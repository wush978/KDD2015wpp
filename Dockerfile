FROM rocker/r-base
MAINTAINER Wush Wu <wush978@gmail.com>

RUN apt-get update
RUN echo "options(repos=c(cran='http://cran.rstudio.com/'))" > /root/.Rprofile
# Packages for data preprocessing
RUN Rscript -e "install.packages('dplyr')" && \
  Rscript -e "install.packages('data.table')"

# Packages for experiments
RUN apt-get update
RUN apt-get install -y --no-install-recommends libxml2-dev libcurl4-nss-dev libssl-dev ca-certificates git && \
  Rscript -e "install.packages('devtools')" && \
  Rscript -e "devtools::install_version(package = 'roxygen2', version = '5.0.1')" && \
  Rscript -e "install.packages(c('glmnet', 'FeatureHashing'))" && \
  cd /root && git clone https://github.com/wush978/FastROC && \
  R CMD INSTALL FastROC
# Packages for reproducible research
RUN Rscript -e "install.packages('knitr')" && \
  Rscript -e "install.packages('rmarkdown')"

COPY IPinYouExp /root/IPinYouExp
RUN cd /root && R CMD INSTALL IPinYouExp
VOLUME /var/local/KDD2015wpp
WORKDIR /var/local/KDD2015wpp
