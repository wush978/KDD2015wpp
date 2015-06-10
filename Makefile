WORKING_DIR=$(shell pwd)
DOCKER_IMAGE=wush978/kdd2015wpp
DOCKER_RUN=docker run --rm -v $(WORKING_DIR):/var/local/KDD2015wpp $(DOCKER_IMAGE)

all : .predict_wp .fig9 .winningpricectr

ipinyou.contest.dataset.zip :
	echo "please download the \"ipinyou.contest.dataset.zip\" from \"http://data.computational-advertising.org/\""

.ipinyou.contest.dataset : ipinyou.contest.dataset.zip
	unzip ipinyou.contest.dataset.zip && touch .ipinyou.contest.dataset

.dockerbuild : Dockerfile
	docker pull $(DOCKER_IMAGE) && touch .dockerbuild
	# In case you want to build by your own:
	# docker build -t $(DOCKER_IMAGE) . && touch .dockerbuild

.decompress : .ipinyou.contest.dataset
	$(DOCKER_RUN) find ipinyou.contest.dataset/training2nd -name "*.bz2" -exec bunzip2 -f {} \;
	$(DOCKER_RUN) find ipinyou.contest.dataset/training3rd -name "*.bz2" -exec bunzip2 -f {} \;
	touch .decompress

.preparedata : .dockerbuild .decompress
	-mkdir -p cache/
	$(DOCKER_RUN) Rscript PrepareData.R

.predict_ctr_wr : .preparedata PredictCTR_WR.R
	$(DOCKER_RUN) Rscript PredictCTR_WR.R | tee log/PredictCTR_WR.log && touch .predict_ctr_wr

.predict_wp : .predict_ctr_wr WinningPrice.R
	$(DOCKER_RUN) Rscript WinningPrice.R | tee log/WinningPrice.log && touch .predict_wp

.fig9 : .predict_ctr_wr PredictCTR_WR_Fig9.R WinningPrice_Fig9.R
	$(DOCKER_RUN) Rscript PredictCTR_WR_Fig9.R && $(DOCKER_RUN) Rscript WinningPrice_Fig9.R | tee log/WinningPrice_Fig9.log && touch .fig9

.winningprice_ctr : .preparedata WinningPriceCTR.R
	$(DOCKER_RUN) Rscript WinningPriceCTR.R | tee log/WinningPriceCTR.log && touch $@
