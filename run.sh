#!/bin/bash

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export APIGEE_MGMT=${APIGEE_MGMT:-https://api.enterprise.apigee.com/v1}

docker rm -f apigee-d8 || true

docker run --name apigee-d8 -p 8080:80 -d \
	-e APIGEE_EDGE_AUTH_TYPE=basic \
	-e APIGEE_EDGE_ORGANIZATION=$APIGEE_ORG \
	-e APIGEE_EDGE_USERNAME=$APIGEE_USER \
	-e APIGEE_EDGE_PASSWORD=$APIGEE_PASS \
	-e APIGEE_EDGE_ENDPOINT=$APIGEE_MGMT \
	ghcr.io/apigee/docker-apigee-drupal-kickstart:latest