#pragma once

#include <cmath>

namespace FTPRL {
  
class FTPRL {
  
  double alpha, beta, lambda1, lambda2;
  
public:

  FTPRL(double _alpha, double _beta, double _lambda1, double _lambda2)
  : alpha(_alpha), beta(_beta), lambda1(_lambda1), lambda2(_lambda2)
  { }
  
  virtual ~FTPRL() { }

  const double get_w(const double z, const double n) const {
    if (n < 0) return 0;
    if (std::abs(z) <= lambda1) return 0;
    return - (z - (z > 0 ? 1 : -1) * lambda1) / ((beta + std::sqrt(n)) / alpha + lambda2);
  }
  
  void update_zn(const double g, double* z, double* n) {
    if (g == 0) return;
    double sigma = (std::sqrt(*n + g * g) - std::sqrt(*n)) / alpha;
    *z = *z + g - sigma * get_w(*z, *n);
    *n = *n + g * g;
  }
  
};
  
}