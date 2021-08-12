#-------------------------------------------------------------------------------#
#-------------------------------- SETUP ----------------------------------------#
#-------------------------------------------------------------------------------#
# set docker as container runtime if nothing else is set
CONTAINER_RUNTIME?=docker
#-------------------------------------------------------------------------------#
#---------------- FUNCTIONS TO BUILD AND RUN DEV IMAGES ------------------------#
#-------------------------------------------------------------------------------#
# build a dev image
build_dev = $(CONTAINER_RUNTIME) build \
	-t my-webpage/$(1):dev \
	-f ./docker/dev.Dockerfile \
	--build-arg TARGET=$(1) \
	.
# run a dev image
run_dev = $(CONTAINER_RUNTIME) run \
	--rm \
	--tty \
	-v $(PWD)/$(1)/src/:/app/$(1)/src/:z \
	-v $(PWD)/$(1)/static/:/app/$(1)/static/:z \
	-v $(PWD)/$(1)/rollup.config.js:/app/$(1)/rollup.config.js:z \
	--mount type=image,source=my-webpage/$(1):dev,destination=/app/$(1)/src/node_modules/,rw=true \
	-p 3000:3000 \
	-p 10000:10000 \
	my-webpage/$(1):dev
#-------------------------------------------------------------------------------#
#--------------- FUNCTIONS TO BUILD AND DEPLOY PROD IMAGES ---------------------#
#-------------------------------------------------------------------------------#
# build a prod image
build_prod = $(CONTAINER_RUNTIME) build \
	-t eu.gcr.io/webpage-jgero/$(1)-page:latest \
	-f ./docker/prod.Dockerfile \
	--build-arg TARGET=$(1) \
	.
# push a prod image to gcloud
push = $(CONTAINER_RUNTIME) push eu.gcr.io/webpage-jgero/$(1)-page:latest
# deploy the gcp cloud run services
deploy = gcloud run deploy $(1)-page \
	--image eu.gcr.io/webpage-jgero/$(1)-page:latest \
	--region europe-west1 \
	--platform managed
#-------------------------------------------------------------------------------#
#----------------- TARGETS TO BUILD AND RUN DEV CONTAINERS ---------------------#
#--------- this is the recommended way of developing the pages -----------------#
#-------------------------------------------------------------------------------#
scavenger: scavenger_build scavenger_run
.PHONY: scavenger_build
scavenger_build:
	$(call build_dev,scavenger-hunt)
.PHONY: scavenger_run
scavenger_run:
	$(call run_dev,scavenger-hunt)
#-------------------------------------------------------------------------------#
#---------------- TARGETS TO BUILD AND DEPLOY PROD IMAGES ----------------------#
#------------ this is supposed to be run in the cloud build --------------------#
#-------------------------------------------------------------------------------#
# build
build: scavenger_build_prod
# build scavenger-hunt
.PHONY: scavenger_build_prod
scavenger_build_prod:
	$(call build_prod,scavenger-hunt)
#-------------------------------------------------------------------------------#
# push
push: build scavenger_push
# push scavenger-hunt
.PHONY: scavenger_push
scavenger_push:
	$(call push,scavenger-hunt)
#-------------------------------------------------------------------------------#
# deploy
deploy: scavenger_deploy
# deploy scavenger-hunt
.PHONY: scavenger_deploy
scavenger_deploy:
	$(call deploy,scavenger-hunt)
