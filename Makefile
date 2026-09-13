DOCKERHUB_USER ?= amitsingh790634
TAG ?= 1.0.0
NAMESPACE ?= streamingapp
RELEASE ?= streamingapp

.PHONY: images push helm-lint deploy scale smoke

images:
	DOCKERHUB_USER=$(DOCKERHUB_USER) TAG=$(TAG) ./scripts/build-and-push.sh

push: images

helm-lint:
	helm lint helm/streamingapp
	helm template $(RELEASE) helm/streamingapp --debug >/tmp/streamingapp-rendered.yaml
	@echo "Rendered manifests written to /tmp/streamingapp-rendered.yaml"

deploy:
	./scripts/deploy.sh $(NAMESPACE) $(RELEASE)

scale:
	./scripts/scale-and-update.sh $(NAMESPACE) $(RELEASE)

smoke:
	HOST=streamingapp.local ./scripts/smoke-test.sh
