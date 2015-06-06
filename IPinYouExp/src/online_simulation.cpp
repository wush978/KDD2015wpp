#include <memory>
#include "MurmurHash3.h"
#include "FTPRLProxy.hpp"
#include "dgCMatrixProxy.hpp"
#include <Rcpp.h>
using namespace Rcpp;

double inline sigma(double x) {
  return 1 / (1 + exp(-x));
}

class FTPRLLogisticRegressionLearner : public FTPRLProxy {
  
  NumericVector z, n;
  double *pz, *pn;
  
public:
  FTPRLLogisticRegressionLearner(S4 Rlearner) 
  : FTPRLProxy(Rlearner), z(Rlearner.slot("z")), n(Rlearner.slot("n")), pz(&z[0]), pn(&n[0])
  { }
  
  virtual ~FTPRLLogisticRegressionLearner() { }
  
  template<typename MATRIX>
  double predict(const MATRIX& m, size_t i) {
    double p = 0;
    #pragma omp parallel for reduction( +:p )
    for(auto j = m.getFeatureItorBegin(i);j < m.getFeatureItorEnd(i);j++) {
      auto feature = m.getFeatureId(j);
      auto value = m.getValue(j);
      p += get_w(feature) * value;
    }
    return p;
  }
  
  /**
   * @param g0 = pred - y
   */
  template<typename MATRIX>
  void update(const MATRIX& m, size_t i, double g0) {
    #pragma omp parallel for
    for(auto j = m.getFeatureItorBegin(i);j < m.getFeatureItorEnd(i);j++) {
      auto feature = m.getFeatureId(j);
      auto value = m.getValue(j);
      double g = value * g0;
      update_zn(g, feature);
    }
  }
  
  double get_w(int feature_id) {
    return FTPRL::get_w(z[feature_id], n[feature_id]);
  }
  
  void update_zn(double g, int feature_id) {
    return FTPRL::update_zn(g, pz + feature_id, pn + feature_id);
  }

};

struct LastDataCache {
  dgCMatrixProxy m;
  size_t i_bid, i_ctr, i_wr;
  LogicalVector is_click, is_win;
  NumericVector bid_t, clk_t, ctr, wr;
  LastDataCache(S4 Rm, LogicalVector is_click_src, LogicalVector is_win_src,
    NumericVector bid_t_src, NumericVector clk_t_src,
    NumericVector ctr_src, NumericVector wr_src,
    size_t i_bid_src, size_t i_ctr_src, size_t i_wr_src)
  : m(Rm), is_click(is_click_src), is_win(is_win_src),
    bid_t(bid_t_src), clk_t(clk_t_src), ctr(ctr_src), wr(wr_src),
    i_bid(i_bid_src), i_ctr(i_ctr_src), i_wr(i_wr_src)
  { }
};

std::auto_ptr<LastDataCache> last_m(NULL);
//'@export
// [[Rcpp::export]]
SEXP OnlineSimulation(S4 Rm, S4 Rlearner_ctr, S4 Rlearner_wr, LogicalVector is_click, LogicalVector is_win,
  NumericVector bid_t, NumericVector clk_t, bool is_continue = false) {
  // initializing input
  FTPRLLogisticRegressionLearner learner_ctr(Rlearner_ctr), learner_wr(Rlearner_wr);
  dgCMatrixProxy m(Rm);
  if (m.getNInstance() != is_click.size()) throw std::invalid_argument("Inconsistent between Rm and is_click");
  if (m.getNInstance() != is_win.size()) throw std::invalid_argument("Inconsistent between Rm and is_win");
  double current_t, update_wr_t, update_ctr_t;
  
  // initializing return value
  NumericVector ctr(m.getNInstance(), NA_REAL), wr(m.getNInstance(), NA_REAL);
  size_t i_bid = 0, i_ctr = 0, i_wr = 0;
  uint32_t 
    ctr_index = FeatureHashing_murmurhash3("ctr", 3, MURMURHASH3_H_SEED), 
    ctr_sign = FeatureHashing_murmurhash3("ctr", 3, MURMURHASH3_XI_SEED);
  if (!is_continue) {
    last_m.reset(NULL);
    for(i_bid = 0;i_bid < m.getNInstance();i_bid++) {
      current_t = bid_t[i_bid];
      // predict CTR according to current ctr model
      ctr[i_bid] = sigma(learner_ctr.predict(m, i_bid));
      // predict winning rate according to current wr model and ctr
      wr[i_bid] = sigma(learner_wr.predict(m, i_bid) + learner_wr.get_w(ctr_index % m.getNFeature()) * ctr[i_bid] * (ctr_sign == 1 ? 1 : -1));
      // update wr model according to data before 1 min
      {
        update_wr_t = current_t - 60;
        while(bid_t[i_wr] < update_wr_t) {
  //        Rprintf("update wr on %d...\n", i_wr);
          // update wr model according to data of i_wr
          auto ctr_feature = ctr_index % m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(m, i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - is_win[i_wr];
          learner_wr.update(m, i_wr, g0);
          double g = ctr[i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          i_wr++;
        }
      }
      // update ctr model according to data before 10 min
      {
        update_ctr_t = current_t - 600;
        while(bid_t[i_ctr] < current_t - 600) {
  //        Rprintf("checking bidding log %d...\n", i_ctr);
          // update ctr model according to data of i_ctr
          if (is_click[i_ctr] != NA_INTEGER) {
  //          Rprintf("update ctr on %d...\n", i_ctr);
            double pred = learner_ctr.predict(m, i_ctr);
            double g0 = sigma(pred) - is_click[i_ctr];
            learner_ctr.update(m, i_ctr, g0);
          }
          i_ctr++;
        }
      }
    }
  }
  else { // is_continue = true
    for(i_bid = 0;i_bid < m.getNInstance();i_bid++) {
      current_t = bid_t[i_bid];
      // predict CTR according to current ctr model
      ctr[i_bid] = sigma(learner_ctr.predict(m, i_bid));
      // predict winning rate according to current wr model and ctr
      wr[i_bid] = sigma(learner_wr.predict(m, i_bid) + learner_wr.get_w(ctr_index % m.getNFeature()) * ctr[i_bid] * (ctr_sign == 1 ? 1 : -1));
      // update wr model according to data before 1 min
      {
        update_wr_t = current_t - 60;
        while(last_m->i_wr < last_m->m.getNInstance() & last_m->bid_t[last_m->i_wr] < update_wr_t) {
         auto ctr_feature = ctr_index % last_m->m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = last_m->ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(last_m->m, last_m->i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - last_m->is_win[last_m->i_wr];
          learner_wr.update(last_m->m, last_m->i_wr, g0);
          double g = last_m->ctr[last_m->i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          last_m->i_wr++;
        }
        while(bid_t[i_wr] < update_wr_t) {
          auto ctr_feature = ctr_index % m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(m, i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - is_win[i_wr];
          learner_wr.update(m, i_wr, g0);
          double g = ctr[i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          i_wr++;
        }
      }
      // update ctr model according to data before 10 min
      {
        update_ctr_t = current_t - 600;
        while(last_m->i_ctr < last_m->m.getNInstance() & last_m->bid_t[last_m->i_ctr] < current_t - 600) {
          if (last_m->is_click[last_m->i_ctr] != NA_INTEGER) {
            double pred = learner_ctr.predict(last_m->m, last_m->i_ctr);
            double g0 = sigma(pred) - last_m->is_click[last_m->i_ctr];
            learner_ctr.update(last_m->m, last_m->i_ctr, g0);
          }
          last_m->i_ctr++;
        }
        while(bid_t[i_ctr] < current_t - 600) {
          if (is_click[i_ctr] != NA_INTEGER) {
            double pred = learner_ctr.predict(m, i_ctr);
            double g0 = sigma(pred) - is_click[i_ctr];
            learner_ctr.update(m, i_ctr, g0);
          }
          i_ctr++;
        }
      }
    }
  }
  {
    last_m.reset(new LastDataCache(Rm, is_click, is_win, bid_t, clk_t, ctr, wr, i_bid, i_ctr, i_wr));
  }
  List retval;
  retval["ctr"] = ctr;
  retval["wr"] = wr;
  return retval;
}

//'@export
// [[Rcpp::export]]
SEXP OnlineSimulation2(S4 Rm, S4 Rlearner_wr, NumericVector ECVR, LogicalVector is_win,
  NumericVector bid_t, bool is_continue = false) {
  // initializing input
  FTPRLLogisticRegressionLearner learner_wr(Rlearner_wr);
  dgCMatrixProxy m(Rm);
  if (m.getNInstance() != is_win.size()) throw std::invalid_argument("Inconsistent between Rm and is_win");
  double current_t, update_wr_t;
  
  // initializing return value
  NumericVector ctr = Rcpp::clone(ECVR), wr(m.getNInstance(), NA_REAL);
  size_t i_bid = 0, i_wr = 0;
  uint32_t 
    ctr_index = FeatureHashing_murmurhash3("ctr", 3, MURMURHASH3_H_SEED), 
    ctr_sign = FeatureHashing_murmurhash3("ctr", 3, MURMURHASH3_XI_SEED);
  if (!is_continue) {
    last_m.reset(NULL);
    for(i_bid = 0;i_bid < m.getNInstance();i_bid++) {
      current_t = bid_t[i_bid];
      // update wr model according to data before 1 min
      {
        update_wr_t = current_t - 60;
        while(bid_t[i_wr] < update_wr_t) {
  //        Rprintf("update wr on %d...\n", i_wr);
          // update wr model according to data of i_wr
          auto ctr_feature = ctr_index % m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(m, i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - is_win[i_wr];
          learner_wr.update(m, i_wr, g0);
          double g = ctr[i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          i_wr++;
        }
      }
      // predict winning rate according to current wr model and ctr
      wr[i_bid] = sigma(learner_wr.predict(m, i_bid) + learner_wr.get_w(ctr_index % m.getNFeature()) * ctr[i_bid] * (ctr_sign == 1 ? 1 : -1));
    }
  }
  else { // is_continue = true
    for(i_bid = 0;i_bid < m.getNInstance();i_bid++) {
      current_t = bid_t[i_bid];
      // update wr model according to data before 1 min
      {
        update_wr_t = current_t - 60;
        while(last_m->i_wr < last_m->m.getNInstance() & last_m->bid_t[last_m->i_wr] < update_wr_t) {
          auto ctr_feature = ctr_index % last_m->m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = last_m->ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(last_m->m, last_m->i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - last_m->is_win[last_m->i_wr];
          learner_wr.update(last_m->m, last_m->i_wr, g0);
          double g = last_m->ctr[last_m->i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          last_m->i_wr++;
        }
        while(bid_t[i_wr] < update_wr_t) {
          auto ctr_feature = ctr_index % m.getNFeature();
          double ctr_w = learner_wr.get_w(ctr_feature);
          double ctr_value = ctr[i_wr] * (ctr_sign == 1 ? 1 : -1);
          double pred = learner_wr.predict(m, i_wr) +  ctr_w * ctr_value;
          double g0 = sigma(pred) - is_win[i_wr];
          learner_wr.update(m, i_wr, g0);
          double g = ctr[i_wr] * g0;
          learner_wr.update_zn(g, ctr_feature);
          i_wr++;
        }
      }
      // predict winning rate according to current wr model and ctr
      wr[i_bid] = sigma(learner_wr.predict(m, i_bid) + learner_wr.get_w(ctr_index % m.getNFeature()) * ctr[i_bid] * (ctr_sign == 1 ? 1 : -1));
    }
  }
  {
    last_m.reset(new LastDataCache(Rm, is_win, is_win, bid_t, bid_t, ctr, wr, i_bid, i_wr, i_wr));
  }
  List retval;
  retval["wr"] = wr;
  return retval;
}