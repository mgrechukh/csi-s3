# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
.PHONY: test build container push clean container_std container_micro container_full

PROJECT_DIR=/app
REGISTRY_NAME=ctrox
IMAGE_NAME=csi-s3
VERSION ?= dev
IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):$(VERSION)
MICRO_IMAGE_TAG=$(IMAGE_TAG)-micro
FULL_IMAGE_TAG=$(IMAGE_TAG)-full
TEST_IMAGE_TAG=$(REGISTRY_NAME)/$(IMAGE_NAME):test

_output/s3driver: pkg/s3/*.go cmd/s3driver/*.go
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o $@ ./cmd/s3driver

test:
	docker build -t $(TEST_IMAGE_TAG) -f test/Dockerfile .
	docker run --rm --privileged -v $(PWD):$(PROJECT_DIR) --device /dev/fuse $(TEST_IMAGE_TAG)

container_std: cmd/s3driver/Dockerfile _output/s3driver
	docker build -t $(IMAGE_TAG) -f $< .

push_std: container_std
	docker push $(IMAGE_TAG)

container_full: cmd/s3driver/Dockerfile.full _output/s3driver
	docker build -t $(FULL_IMAGE_TAG) --build-arg VERSION=$(VERSION) -f $< .

push_full: container_full
	docker push $(FULL_IMAGE_TAG)

container_micro: cmd/s3driver/Dockerfile.micro _output/s3driver
	docker build -t $(MICRO_IMAGE_TAG) --build-arg VERSION=$(VERSION) -f $< .

push_micro: container_micro
	docker push $(MICRO_IMAGE_TAG)

build: _output/s3driver
push: build push_micro push_full push_std
container: build container_std container_full container_micro

clean:
	go clean -r -x
	-rm -rf _output
