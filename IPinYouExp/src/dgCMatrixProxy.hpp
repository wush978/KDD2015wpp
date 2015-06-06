#include <Rcpp.h>
#include "Matrix.hpp"

class dgCMatrixProxyInitializer {

protected:

  Rcpp::IntegerVector dim;

public:
  dgCMatrixProxyInitializer(Rcpp::S4 m)
  : dim(m.slot("Dim")) { 
    if (dim.size() != 2) throw std::invalid_argument("");
  }
  
  virtual ~dgCMatrixProxyInitializer() { }

};

class dgCMatrixProxy : 
public dgCMatrixProxyInitializer, 
public FTPRL::Matrix<int, int> {

  typedef int IndexType;
  
  typedef int ItorType;

  int *i, *p;
  
  double *x;
  
public:

  dgCMatrixProxy(Rcpp::S4 m) 
  : dgCMatrixProxyInitializer(m), FTPRL::Matrix<int, int>(dim[0], dim[1]),
  i(INTEGER(m.slot("i"))), p(INTEGER(m.slot("p"))), x(REAL(m.slot("x"))) { }
  
  virtual ~dgCMatrixProxy() { }
  
  virtual ItorType getFeatureItorBegin(IndexType instance_id) const {
    return p[instance_id];
  }
  
  virtual ItorType getFeatureItorEnd(IndexType instance_id) const {
    return p[instance_id + 1];
  }
  
  virtual IndexType getFeatureId(ItorType feature_iterator) const {
    return i[feature_iterator];
  }
  
  virtual double getValue(ItorType feature_iterator) const {
    return x[feature_iterator];
  }
    

};
  
