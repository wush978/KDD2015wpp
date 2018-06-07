# Reproduce the Experiments in "[Predicting Winning Price in Real Time Bidding with Censored Data](https://drive.google.com/file/d/0B5rJuVU7ijjIUVc5Rm10b2dreDhBb2xwcnNuOFl3TF9vNFdv/view?usp=sharing)"

## Corrigendum 

- The Eq.(5) in our paper should be $\sum_{i \in W} {- log\left( \phi(\frac{w_i - \beta_{clm}^T}{\sigma}) \right)} + \sum_{i \in L} {-log\left( \Phi(\frac{\beta_{clm}^Tx_i - b_i}{\sigma}) \right)}$. <img src="https://i.imgur.com/Ac8WNLu.png"/> The original Eq.(5) uses the winning probability, however, the $L$ is the losing bids. Therefore, it should be the losing probability.

## Environment

- Ubuntu
- Docker (Please read the installation guide here: <https://docs.docker.com/installation/ubuntulinux/>)
- GNU Make
- git
- 16GB Memory

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

## Bug Fixes

Thanks for the suggestion from @ysk24ok and @jacky168, the code is updated to correct the mistakes.
The code used in the paper is put to the tag `submission-of-kdd`
