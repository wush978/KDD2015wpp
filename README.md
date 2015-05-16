# Reproduce the Experiments in "Predicting Winning Price in Real Time Bidding with Censored Data"

## Environment

- Ubuntu
- Docker (Please read the installation guide here: <https://docs.docker.com/installation/ubuntulinux/>)
- GNU Make
- git

## Getting Started

### Checkout the Project

```sh
git clone https://github.com/wush978/KDD2015wpp.git
```

### Download Dataset

Due to the license of the iPinYou dataset, we do not provide an automatic tool for downloading the required dataset.

Please visit the [iPinYou Real-Time Bidding Dataset
for Computational Advertising Research](http://data.computational-advertising.org/) to download the `ipinyou.contest.dataset.zip` and place the file in the root directory of this project.

### Make

After downloading the dataset, please execute `make` to reproduce the experiments.

## Trouble Shooting

If you have any problem, please feel free to post an issue in <https://github.com/wush978/KDD2015wpp/issues>.