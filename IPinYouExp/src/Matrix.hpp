#pragma once

namespace FTPRL {
  
/**
 * Abstract Type of Matrix Data
 */
template<typename IndexType, typename ItorType>
class Matrix {

protected:
  IndexType nfeature, ninstance;

public:

  Matrix(IndexType _nfeature, IndexType _ninstance) :
  nfeature(_nfeature), ninstance(_ninstance) { }
  
  virtual ~Matrix() { }
  
  inline IndexType getNFeature() const {
    return nfeature;
  }
  
  inline IndexType getNInstance() const {
    return ninstance;
  }
  
  virtual ItorType getFeatureItorBegin(IndexType instance_id) const = 0;
  
  virtual ItorType getFeatureItorEnd(IndexType instance_id) const = 0;
  
  virtual IndexType getFeatureId(ItorType feature_iterator) const = 0;
  
  virtual double getValue(ItorType feature_iterator) const = 0;
  
};

}