# Reproduce the Experiments in "Predicting Winning Price in Real Time Bidding with Censored Data"

## Environment

- Ubuntu
- Docker (Please read the installation guide here: <https://docs.docker.com/installation/ubuntulinux/>)
- GNU Make

## Getting Started

### Download Dataset

Due to the license of the iPinYou dataset, we do not provide an automatic tool for downloading the required dataset.

Please visit the [iPinYou Real-Time Bidding Dataset
for Computational Advertising Research](http://data.computational-advertising.org/) to download the `ipinyou.contest.dataset.zip` and place the file in the root directory of this project.

### Make

After downloading the dataset, we provide a Makefile to automate the steps to reproduce the experiments.

```sh
make
```
