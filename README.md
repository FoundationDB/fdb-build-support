# fdb-build-support

![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoibkVmakQ0VFc4SU5qdDBTaWhmekNVUTVSaExDSHNrT2hTOHRhVjhYODlKbzVEM2hRZmdIeTMrak8xeU1YLy8yOXQ2eFN5Rk5qWVFZazhQNFh1d1ViOVZVPSIsIml2UGFyYW1ldGVyU3BlYyI6IkNMQVRybGVvZDNacW9qWVAiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=main)

This repo contains files useful for building and developing FoundationDB. In 
particular it contains the docker image definitions used by FoundationDB team 
members for development, and the image definitions used by the FoundationDB 
CI/CD system. 

## How-to

### Build FoundationDB

Here's an example on how to build FoundationDB using the [build image](https://hub.docker.com/r/foundationdb/build).
First you need to run the container:

```shell
docker pull foundationdb/build:centos7-latest
docker run -it foundationdb/build:centos7-latest
```

Then, inside the container, you can run:

```shell
source /opt/rh/devtoolset-8/enable
source /opt/rh/rh-python38/enable
source /opt/rh/rh-ruby27/enable

git clone https://github.com/apple/foundationdb.git
mkdir build && cd build

cmake -G Ninja ../foundationdb
ninja # If this crashes it probably ran out of memory. Try ninja -j1
```
