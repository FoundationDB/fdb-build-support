# fdb-build-support

![Build Status](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiMDBtWmhSdnJ5N0FpSXozakdHaXZqRUs5NW41Ykk5eU9PaytkWm9MTzFQYkNNVk1lVjRtdU9BLzU5TEVwazZzVXd3dGI3ZkZ0dmJ3dUVTRkJubEdMRXFBPSIsIml2UGFyYW1ldGVyU3BlYyI6ImI1Tm1Gb2dSbUFocno3VUgiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=main)

This repo contains files useful for building and developing FoundationDB. In 
particular, it contains the docker image definitions used by FoundationDB team 
members for development, and the image definitions used by the FoundationDB 
CI/CD system. 

## How-to

### Build the images

The Dockerfile(s) in this project are built to leverage [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/).
To build the various images are built with commands like:

```shell
cd docker/rockylinux9
docker build --tag foundationdb/build:rockylinux9-latest --target build .
docker build --tag foundationdb/devel:rockylinux9-latest --target devel .
docker build --tag foundationdb/distcc:rockylinux9-latest --target distcc .
docker build --tag foundationdb/codebuild:rockylinux9-latest --target codebuild .
```

The `build` target contains the core dependencies and tools that are required to compile FoundationDB.
The `devel` target is "FROM" the `build` image. It adds developer tools and other convenience packages.
The `distcc` target is "FROM" the `build` image. It adds a distcc daemon to the images. This is used to run a [distcc](https://www.distcc.org) service. 
The `codebuild` target is "FROM" the `devel` images. It us used in FoundationDB CI/CD.

### Build FoundationDB

Here's an example on how to build FoundationDB using the [build image](https://hub.docker.com/r/foundationdb/build).
First you need to run the container:

```shell
docker pull foundationdb/build:rockylinux9-latest
docker run -it foundationdb/build:rockylinux9-latest /bin/bash
```

Then, inside the container, you can run:

```shell
source /opt/rh/gcc-toolset-13/enable

mkdir -p src/foundationdb
git clone https://github.com/apple/foundationdb.git src/foundationdb/ 
mkdir build_output

cmake -S src/foundationdb -B build_output -G Ninja 
ninja -C build_output # If this crashes it probably ran out of memory. Try ninja -j1
```

## Some Notes

* The centos6 images are deprecated, and have fallen behind the centos7 images. The definitions are here, primarily, for posterity to see.
* The centos7 images are deprecated, and have fallen behind the rockylinux9 images. The definitions are here, primarily, for posterity to see.
* The rockylinux9 images are the current active development environment.
* The windows images are maintained by the team at Doxense.
