FROM rocker/r-base
MAINTAINER Wush Wu <wush978@gmail.com>

RUN apt-get update
# Packages for data preprocessing
RUN Rscript -e "install.packages('dplyr')" && \
  Rscript -e "install.packages('data.table')"
# Packages for reproducible research
RUN Rscript -e "install.packages('knitr')" && \
  Rscript -e "install.packages('rmarkdown')"
  
VOLUME /var/local/KDD2015wpp
WORKDIR /var/local/KDD2015wpp
