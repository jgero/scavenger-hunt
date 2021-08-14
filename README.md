# Scavenger Hunt

The App is deployed on GCP to [this](https://scavenger-hunt-page-c5emzvjboa-ew.a.run.app) domain.

## develop, build and run

The Makefile contains separate rules to build and run development and production versions of the
page. By setting the `CONTAINER_RUNTIME` environment variable it is possible to specify a container
runtime. The rules were tested for podman and docker, so one of these is recommended. Defaults to
docker.

