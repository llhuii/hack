# Copyright 2021 The KubeEdge Authors.
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

FROM golang:1.16-alpine3.14 AS builder
LABEL stage=builder


# install build tools
#RUN apk update
#RUN apk add build-base bash

# copy source
WORKDIR /code
COPY go.mod .
RUN go mod download
COPY . .
RUN go build -o ./main k8s-in-cluster.go

FROM alpine:3.14

COPY --from=builder /code/main ./main

CMD ["./main"]

