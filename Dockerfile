FROM rocker/r-base
MAINTAINER Wush Wu <wush978@gmail.com>

ENV http_proxy="http://10.1.1.116:3128"
ENV https_proxy="http://10.1.1.116:3128"
ENV ftp_proxy="http://10.1.1.116:3128"

RUN apt-get update
# Packages for data preprocessing
RUN Rscript -e "install.packages('dplyr')" && \
  Rscript -e "install.packages('data.table')"

# Packages for experiments
RUN Rscript -e "install.packages(c('FeatureHashing', 'glmnet'))" && \
  apt-get install -y --no-install-recommends libxml2-dev libcurl4-openssl-dev libssl-dev ca-certificates && \
  Rscript -e "install.packages(c('devtools', 'roxygen2'))"
RUN Rscript -e "devtools::install_github('wush978/FastROC')"

# Packages for reproducible research
RUN Rscript -e "install.packages('knitr')" && \
  Rscript -e "install.packages('rmarkdown')"

COPY IPinYouExp /root/IPinYouExp
RUN cd /root && R CMD INSTALL IPinYouExp
VOLUME /var/local/KDD2015wpp
WORKDIR /var/local/KDD2015wpp
