build:
	@DEPLOY=0 .github/scripts/build-image.sh

deploy:
	@DEPLOY=1 .github/scripts/build-image.sh
