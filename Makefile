# wblew/kulian-unbound:Makefile
.phony: buildx build inspect inspectx

# The image tag. Can be multiple tags. Defaults to latest.
#	For example: make buildx TAG="1.2 1.2.3 latest"
TAG?=latest

# Additonal buildx options. Defaults to --push.
OPTS?=--push

# The image repository. Without the trailing slash!
REPO?=git.kulian.org/wblew

override TAGS:=$(addprefix $(REPO)/unbound:,$(TAG))

# build local image for just native platform
build:
	docker build $(addprefix --tag=,$(TAGS)) .

# mybuilder is-preq of buildx unless it exists
ifeq ($(shell docker buildx inspect mybuilder),)
buildx: mybuilder
else
buildx:
endif
	docker buildx bake --builder=mybuilder -f docker-bake.hcl $(addprefix --set=*.tags=,$(TAGS)) $(OPTS)

inspect:
	docker image inspect $(firstword $(TAGS))

inspectx:
	docker buildx imagetools inspect --builder=mybuilder $(firstword $(TAGS))

# create the mybuilder buildx builder instance. It has
# nodes: ads01, ads02, crystal, and athena if this has
# been executed on athena.
_appends:=$(addprefix append-,$(filter-out $(shell hostname -s),ads01 ads02 crystal))
.phony:  mybuilder create-builder $(_appends)
mybuilder : create-builder $(_appends)
create-builder:
	docker buildx create --use --bootstrap --driver docker-container --name mybuilder \
		--driver-opt network=host --buildkitd-flags '--allow-insecure-entitlement network.host' \
		unix:///var/run/docker.sock
append-% :
	docker buildx create --append --bootstrap --name mybuilder \
		--driver-opt network=host --buildkitd-flags '--allow-insecure-entitlement network.host' \
		ssh://wblew@$*.kulian.org
