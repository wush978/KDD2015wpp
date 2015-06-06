#include <Rcpp.h>
#include "FTPRL.hpp"

class FTPRLProxy : public FTPRL::FTPRL {
  
public :

  FTPRLProxy(Rcpp::S4 Rlearner) 
  : FTPRL::FTPRL(
      Rcpp::as<double>(Rlearner.slot("alpha")),
      Rcpp::as<double>(Rlearner.slot("beta")),
      Rcpp::as<double>(Rlearner.slot("lambda1")),
      Rcpp::as<double>(Rlearner.slot("lambda2")))
  { }
  
  ~FTPRLProxy() { }
  
};