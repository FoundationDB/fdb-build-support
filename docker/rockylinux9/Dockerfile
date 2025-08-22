FROM rockylinux:9.3 AS build

WORKDIR /tmp
RUN dnf -y update && \
    dnf install -y \
        epel-release \
        scl-utils \
        yum-utils && \
    dnf install -y --enablerepo devel --allowerasing \
        autoconf \
        automake \
        binutils-devel \
        curl \
        coreutils-single \
        dos2unix \
        dpkg \
        gcc-toolset-13-runtime-13.0 \
        gcc-toolset-13-libstdc++-devel-13.3.1 \
        gcc-toolset-13-binutils-gold-2.40 \
        gcc-toolset-13-binutils-2.40\
        gcc-toolset-13-gcc-13.3.1 \
        gcc-toolset-13-gcc-c++-13.3.1 \
        gettext-devel \
        gperftools \
        gperftools-devel \
        gperftools-libs \
        ghostscript \
        gv \
        iptables \
        java-11-openjdk-devel \
        libbsd-devel \
        libcurl-devel \
        libedit \
        libedit-devel \
        libicu-devel \
        libtool \
        libuuid-devel \
        libxml2-devel \
        libxslt \
        mono-devel \
        pkg-config \
        rpm-build \
        rsync \
        sqlite \
        tcl-devel \
        unzip \
        valgrind \
        vim-enhanced \
        wget \
        zlib-devel \
        gcc-c++ \
        libstdc++-static \
        libunwind \
        libunwind-devel \
        libxcrypt-compat \
        perl-FindBin \
        perl-IPC-Cmd \
        perl-Pod-Html \
        perl-lib \
        python3-devel \
        ruby \
	tidy && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# TODO: Is this really necessary?!? -- from swift's dockerfile
RUN sed -i -e 's/\*__block/\*__libc_block/g' /usr/include/unistd.h

# install docker 20
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_BUILDX_VERSION="v0.23.0"

ENV DOCKER_VERSION="28.1.1"

VOLUME /var/lib/docker

RUN set -ex \
    && if [ "$(uname -m)" == "aarch64" ]; then \
        DOCKER_SHA256="836bbaea204251922ec4dc79dbe81e323ccedaa726efc01f62683f547d721871"; \
        DOCKER_COMPOSE_VERSION="v2.16.0"; \
        DOCKER_BUILDX_URL="https://github.com/docker/buildx/releases/download/${DOCKER_BUILDX_VERSION}/buildx-${DOCKER_BUILDX_VERSION}.linux-$(uname -m)" ;\
    else \
        DOCKER_SHA256="ff34bd799b5e4c3738a3b1a383cf4067c672add48c7203fcd003fcb0aacebc94"; \
        DOCKER_COMPOSE_VERSION="1.26.0"; \
        DOCKER_BUILDX_URL="https://github.com/docker/buildx/releases/download/${DOCKER_BUILDX_VERSION}/buildx-${DOCKER_BUILDX_VERSION}.linux-amd64"; \
    fi \
    && curl -fSLs "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/$(uname -m)/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum --quiet -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm -f docker.tgz \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && curl -Ls "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind \
    && curl -Ls https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -Ls "${DOCKER_BUILDX_URL}" -o /usr/local/lib/docker/cli-plugins/docker-buildx \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-buildx \
    && docker-compose version

# build/install lz4
RUN curl -Ls https://github.com/lz4/lz4/archive/refs/tags/v1.9.3.tar.gz -o lz4.tar.gz && \
    echo "030644df4611007ff7dc962d981f390361e6c97a34e5cbc393ddfbe019ffe2c1  lz4.tar.gz" > lz4-sha.txt && \
    sha256sum --quiet -c lz4-sha.txt && \
    mkdir lz4 && \
    tar --strip-components 1 --no-same-owner --directory lz4 -xf lz4.tar.gz && \
    cd lz4 && \
    make && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# build/install liburing
RUN curl -Ls https://github.com/axboe/liburing/archive/refs/tags/liburing-2.1.tar.gz -o liburing.tar.gz && \
    echo "f1e0500cb3934b0b61c5020c3999a973c9c93b618faff1eba75aadc95bb03e07  liburing.tar.gz" > liburing-sha.txt && \
    sha256sum --quiet -c liburing-sha.txt && \
    mkdir liburing && \
    tar --strip-components 1 --no-same-owner --directory liburing -xf liburing.tar.gz && \
    cd liburing && \
    ./configure && \
    make -j$(nproc) -C src V=1 CPPFLAGS="-Werror" CFLAGS="-g -O2 -Wall -Wextra -Werror" CXXFLAGS="-g -O2 -Wall -Wextra -Werror" && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# build/install git
RUN curl -Ls https://github.com/git/git/archive/refs/tags/v2.45.1.tar.gz -o git.tar.gz && \
    echo "d98c8f70d58f49f7546d59b25e25f2deae6999eb036a33b0fe6f5d07c33f67c6  git.tar.gz" > git-sha.txt && \
    sha256sum --quiet -c git-sha.txt && \
    mkdir git && \
    tar --strip-components 1 --no-same-owner --directory git -xf git.tar.gz && \
    cd git && \
    make configure && \
    ./configure && \
    make && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# build/install ninja
RUN curl -Ls https://github.com/ninja-build/ninja/archive/refs/tags/v1.10.2.zip -o ninja.zip && \
    echo "4e7b67da70a84084d5147a97fcfb867660eff55cc60a95006c389c4ca311b77d  ninja.zip" > ninja-sha.txt && \
    sha256sum --quiet -c ninja-sha.txt && \
    unzip ninja.zip && \
    cd ninja-1.10.2 && \
    python3 ./configure.py --bootstrap && \
    cp ninja /usr/bin && \
    cd ../ && \
    rm -rf /tmp/*

# install cmake
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        CMAKE_SHA256="e0f74862734c2d14ef8ac5a71941691531db0bbebee0a9c20a8e96e8a97390f9"; \
    else \
        CMAKE_SHA256="0fcb338b4515044f9ac77543550ac92c314c58f6f95aafcac5cd36aa75db6924"; \
    fi && \
    curl -Ls https://github.com/Kitware/CMake/releases/download/v3.31.0/cmake-3.31.0-$(uname -s)-$(uname -m).tar.gz -o cmake.tar.gz && \
    echo "${CMAKE_SHA256}  cmake.tar.gz" > cmake-sha.txt && \
    sha256sum --quiet -c cmake-sha.txt && \
    mkdir cmake && \
    tar --strip-components 1 --no-same-owner --directory cmake -xf cmake.tar.gz && \
    cp -r cmake/* /usr/local/ && \
    rm -rf /tmp/*

# build/install LLVM 19.1.5
ENV DEVTOOLSET_VERSION=13
ENV LLVM_VERSION=19.1.5
RUN source /opt/rh/gcc-toolset-${DEVTOOLSET_VERSION}/enable && \
    curl -Ls https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz -o llvm.tar.xz && \
    echo "bd8445f554aae33d50d3212a15e993a667c0ad1b694ac1977f3463db3338e542  llvm.tar.xz" > llvm-sha.txt && \
    sha256sum --quiet -c llvm-sha.txt && \
    mkdir llvm-project && \
    tar --strip-components 1 --no-same-owner --directory llvm-project -xf llvm.tar.xz && \
    cd llvm-project && \
    mkdir -p build && \
    cd build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        -Wno-dev \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;compiler-rt" \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
        -DCLANG_DEFAULT_PIE_ON_LINUX=OFF \
        ../llvm && \
    cmake --build . && \
    cmake --build . --target install && \
    cd .. && \
    cp "/usr/local/include/$(uname -m)-unknown-linux-gnu/c++/v1/__config_site" /usr/local/include/c++/v1/__config_site && \
    cd /tmp && \
    rm -rf /tmp/*

# build/install openssl
RUN curl -Ls https://www.openssl.org/source/openssl-1.1.1m.tar.gz -o openssl.tar.gz && \
    echo "f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96  openssl.tar.gz" > openssl-sha.txt && \
    sha256sum --quiet -c openssl-sha.txt && \
    mkdir openssl && \
    tar --strip-components 1 --no-same-owner --directory openssl -xf openssl.tar.gz && \
    cd openssl && \
    ./config CFLAGS="-fPIC -O3" --prefix=/usr/local && \
    make -j`nproc` && \
    make -j1 install && \
    ln -sv /usr/local/lib64/lib*.so.1.1 /usr/lib64/ && \
    cd ../ && \
    rm -rf /tmp/*

ENV GO_VERSION="1.24.4"
# Install golang
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls "https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz" -o golang.tar.gz; \
    else \
        curl -Ls "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o golang.tar.gz; \
    fi \
    && tar -C /usr/local -xzf golang.tar.gz && \
    echo '[ -x /usr/local/go/bin/go ] && export PATH=/usr/local/go/bin:$PATH' >> /etc/profile.d/golang.sh && \
    source /etc/profile.d/golang.sh && \
    go env -w GOPROXY=https://proxy.golang.org,direct && \
    go env -w GOSUMDB=sum.golang.org

# build/install googlebenchmark
# If you change this, then old versions of FDB will stop building in the resulting image.  If you need to support old and
# new builds, then copy the below, and download / compile a second version with the newer SHA.  This needs to be kept in
# lock-step with the CMake logic that automatically downloads external dependencies.  See flowbench/CMakeLists.cmake and
# flowbench/benchmark.cmake in the main FDB repo for more information.

# The perl one-liner tells the googlebenchmark build to download a specific SHA of googletest.  By default, they track
# (tracked?) master, which no longer exists, and risks version skew / incompatibility.
RUN cd /tmp && \
    git clone https://github.com/google/benchmark.git googlebenchmark-f91b6b && \
    cd googlebenchmark-f91b6b/ && \
    git checkout f91b6b42b1b9854772a90ae9501464a161707d1e && \
    perl -p -i -e s/master/2fe3bd994b3189899d93f1d5a881e725e046fdc2/ cmake/GoogleTest.cmake.in

# We disable regexp support for Clang because the system version of that library only works with GCC.
# Link Python to Python3
RUN GOOGLE_BENCHMARK_INSTALL_DIR_CLANG="/opt/googlebenchmark-f91b6b" && \
    mkdir -p ${GOOGLE_BENCHMARK_INSTALL_DIR_CLANG} && \
    cd /tmp/googlebenchmark-f91b6b && \
    mkdir -p /tmp/googlebenchmark-f91b6b/build-clang && \
    ln -s /usr/bin/python3 /usr/bin/python && \
	cmake -DCMAKE_BUILD_TYPE=Release \
        -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on \
        -DBENCHMARK_ENABLE_LTO=true \
        -DRUN_HAVE_STD_REGEX=0 \
        -DRUN_HAVE_POSIX_REGEX=0  \
        -DCMAKE_INSTALL_PREFIX=${GOOGLE_BENCHMARK_INSTALL_DIR_CLANG} \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
        -S /tmp/googlebenchmark-f91b6b \
        -B /tmp/googlebenchmark-f91b6b/build-clang && \
    cd /tmp/googlebenchmark-f91b6b/build-clang && \
    make -j 16 && \
    make install && \
    cd /tmp/googlebenchmark-f91b6b && \
    rm -rf /tmp/googlebenchmark-f91b6b/build-clang

RUN GOOGLE_BENCHMARK_INSTALL_DIR_GCC="/opt/googlebenchmark-f91b6b-g++" && \
    mkdir -p ${GOOGLE_BENCHMARK_INSTALL_DIR_GCC} && \
    cd /tmp/googlebenchmark-f91b6b && \
    source /opt/rh/gcc-toolset-13/enable && \
    mkdir -p /tmp/googlebenchmark-f91b6b/build-gcc && \
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on \
        -DBENCHMARK_ENABLE_LTO=true \
        -DRUN_HAVE_STD_REGEX=0 \
        -DRUN_HAVE_POSIX_REGEX=0 \
        -DCMAKE_INSTALL_PREFIX=${GOOGLE_BENCHMARK_INSTALL_DIR_GCC} \
        -S /tmp/googlebenchmark-f91b6b \
        -B /tmp/googlebenchmark-f91b6b/build-gcc && \
    cd /tmp/googlebenchmark-f91b6b/build-gcc && \
    make -j 16 && \
    make install && \
    cd /tmp/googlebenchmark-f91b6b && \
    rm -rf /tmp/googlebenchmark-f91b6b/build-gcc

RUN rm -rf /tmp/googlebenchmark*

# install doctest_proj to /opt
# We use this in a header-only fashion, so there's no reason to compile it here.
RUN mkdir -p /opt/doctest_proj_2.4.8 && \
    pushd /opt/doctest_proj_2.4.8 && \
    git init && \
    git remote add origin https://github.com/onqtam/doctest.git && \
    git fetch --depth 1 origin 7b9885133108ae301ddd16e2651320f54cafeba7 && \
    git checkout FETCH_HEAD && \
    popd && \
    rm -rf /tmp/*

# download junit dependencies
RUN mkdir /opt/junit_dependencies && \
    cd    /opt/junit_dependencies && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-engine/5.7.1/junit-jupiter-engine-5.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-api/5.7.1/junit-jupiter-api-5.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-params/5.7.1/junit-jupiter-params-5.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-commons/1.7.1/junit-platform-commons-1.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-engine/1.7.1/junit-platform-engine-1.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-launcher/1.7.1/junit-platform-launcher-1.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-console/1.7.1/junit-platform-console-1.7.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/apiguardian/apiguardian-api/1.1.1/apiguardian-api-1.1.1.jar && \
    curl -LsO https://search.maven.org/remotecontent?filepath=org/opentest4j/opentest4j/1.2.0/opentest4j-1.2.0.jar && \
    echo "fc68f0d28633caccf3980fdf1e99628fba9c49424ee56dc685cd8b4d2a9fefde apiguardian-api-1.1.1.jar" > junit_dependencies.sha256 && \
    echo "ce7b985bc469e2625759a4ebc45533c70581a05a348278c1d6408e9b2e35e314 junit-jupiter-api-5.7.1.jar" >> junit_dependencies.sha256 && \
    echo "56616c9350b3624f76cffef6b24ce7bb222915bfd5688f96d3cf4cef34f077cb junit-jupiter-engine-5.7.1.jar" >> junit_dependencies.sha256 && \
    echo "8effdd7f8a4ba5558b568184dee08008b2443c86c673ef81de5861fbc7ef0613 junit-jupiter-params-5.7.1.jar" >> junit_dependencies.sha256 && \
    echo "7c546be86864718fbaceb79fa84ff1d3a516500fc428f1b21d061c2e0fbc5a4b junit-platform-commons-1.7.1.jar" >> junit_dependencies.sha256 && \
    echo "11ed48fcdfcea32f2fa98872db7ecba2d49d178f76493e7a149a2242363ad12e junit-platform-console-1.7.1.jar" >> junit_dependencies.sha256 && \
    echo "37df5a9cd6dbc1f754ba2b46f96b8874a83660e1796bf38c738f022dcf86c23f junit-platform-engine-1.7.1.jar" >> junit_dependencies.sha256 && \
    echo "3122ac6fb284bc50e3afe46419fc977f94d580e9d3d1ea58805d200b510a99ee junit-platform-launcher-1.7.1.jar" >> junit_dependencies.sha256 && \
    echo "58812de60898d976fb81ef3b62da05c6604c18fd4a249f5044282479fc286af2 opentest4j-1.2.0.jar" >> junit_dependencies.sha256 && \
    sha256sum --quiet -c junit_dependencies.sha256

# install gradle
RUN curl -Ls https://services.gradle.org/distributions/gradle-7.5.1-bin.zip -o gradle.zip && \
    echo "f6b8596b10cce501591e92f229816aa4046424f3b24d771751b06779d58c8ec4  gradle.zip" > gradle-sha.txt && \
    sha256sum --quiet -c gradle-sha.txt && \
    unzip -qq gradle.zip && \
    mv gradle-7.5.1 /opt/gradle && \
    echo '[ -x /opt/gradle/bin/gradle ] && export PATH=/opt/gradle/bin/:$PATH' >> /etc/profile.d/gradle.sh && \
    rm -rf /tmp/*

# install maven
ENV MAVEN_VERSION=3.9.9
RUN curl -Ls https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip -o maven.zip && \
    echo "4ec3f26fb1a692473aea0235c300bd20f0f9fe741947c82c1234cefd76ac3a3c  maven.zip" > maven-sha.txt && \
    sha256sum --quiet -c maven-sha.txt && \
    unzip -qq maven.zip && \
    mv apache-maven-${MAVEN_VERSION} /opt/maven && \
    echo '[ -x /opt/maven/bin/mvn ] && export PATH=/opt/maven/bin/:$PATH' >> /etc/profile.d/maven.sh && \
    rm -rf /tmp/*

# install Boost to /opt
# This used to pass --with-libraries=context,filesystem,iostreams,system,serialization
# which doesn't build serialization (or builds it in a form that downstream cmake builds
# cannot find).  Instead of debugging their build logic, we pass "all", which is simpler to
# maintain and does build serialization.
RUN curl -Ls https://archives.boost.io/release/1.78.0/source/boost_1_78_0.tar.bz2 -o boost_1_78_0.tar.bz2 && \
    echo "8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc  boost_1_78_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_78_0 && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_78_0 -xjf boost_1_78_0.tar.bz2 && \
    cd /opt/boost_1_78_0 && \
    source /opt/rh/gcc-toolset-13/enable && \
    ./bootstrap.sh --with-libraries=all && \
    ./b2 link=static cxxflags="-std=c++17 -fPIC" --prefix=/opt/boost_1_78_0 -j32 install &&\
    rm -rf /opt/boost_1_78_0/libs && \
    rm -rf /tmp/*

# install Boost to /opt, using clang to compile the library
# clang 18 generates errors when using all libraries, so we need to specify the libraries explicitly
RUN curl -Ls https://archives.boost.io/release/1.78.0/source/boost_1_78_0.tar.bz2 -o boost_1_78_0.tar.bz2 && \
    echo "8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc  boost_1_78_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_78_0_clang && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_78_0_clang -xjf boost_1_78_0.tar.bz2 && \
    cd /opt/boost_1_78_0_clang && \
    ./bootstrap.sh --with-toolset=clang --with-libraries=context,filesystem,iostreams,system,serialization && \
    ./b2 link=static cxxflags="-std=c++14 -stdlib=libc++ -nostdlib++ -fPIC" linkflags="-stdlib=libc++ -nostdlib++ -static-libgcc -lc++ -lc++abi" --prefix=/opt/boost_1_78_0_clang -j32 install && \
    rm -rf /opt/boost_1_78_0_clang/libs && \
    rm -rf /tmp/*

# install Boost 1.86 to /opt, using clang to compile the library
# Boost::context depends on some C++11 features, e.g. std::call_once; however,
# gcc and clang are using different ABIs, thus a gcc-built Boost::context is
# not linkable to clang objects.
RUN cd /tmp && \
    curl -Ls https://archives.boost.io/release/1.86.0/source/boost_1_86_0.tar.bz2 -o boost_1_86_0.tar.bz2 && \
    echo "1bed88e40401b2cb7a1f76d4bab499e352fa4d0c5f31c0dbae64e24d34d7513b  boost_1_86_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_86_0_clang && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_86_0_clang -xjf boost_1_86_0.tar.bz2 && \
    cd /opt/boost_1_86_0_clang && \
    ./bootstrap.sh --with-toolset=clang --with-libraries=all && \
    ./b2 link=static cxxflags="-std=c++17 -stdlib=libc++ -nostdlib++ -fPIC" linkflags="-stdlib=libc++ -nostdlib++ -static-libgcc -lc++ -lc++abi" --prefix=/opt/boost_1_86_0_clang -j32 install && \
    rm -rf /opt/boost_1_86_0_clang/libs && \
    rm -rf /tmp/*

# install Boost to /opt, using gcc
RUN cd /tmp && \
    curl -Ls https://archives.boost.io/release/1.86.0/source/boost_1_86_0.tar.bz2 -o boost_1_86_0.tar.bz2 && \
    echo "1bed88e40401b2cb7a1f76d4bab499e352fa4d0c5f31c0dbae64e24d34d7513b  boost_1_86_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_86_0 && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_86_0 -xjf boost_1_86_0.tar.bz2 && \
    cd /opt/boost_1_86_0 && \
    source /opt/rh/gcc-toolset-13/enable && \
    ./bootstrap.sh --with-libraries=all && \
    ./b2 link=static cxxflags="-std=c++17 -fPIC" --prefix=/opt/boost_1_86_0 -j32 install &&\
    rm -rf /opt/boost_1_86_0/libs && \
    rm -rf /tmp/*

# jemalloc (needed for FDB after 6.3)
RUN curl -Ls https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 -o jemalloc.tar.bz2 && \
    echo "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa  jemalloc.tar.bz2" > jemalloc-sha.txt && \
    sha256sum --quiet -c jemalloc-sha.txt && \
    mkdir jemalloc && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory jemalloc -xjf jemalloc.tar.bz2 && \
    cd jemalloc && \
    ./configure --enable-static --disable-cxx --enable-prof && \
    make -j32 && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# install jemalloc to /opt/jemalloc_5.3.0 (The FDB build no longer finds the above
# one for some reason; also installing it system-wide makes it difficult to upgrade
# the dependency without accidentally upgrading it for older FDB branches.)
RUN curl -Ls https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 -o jemalloc.tar.bz2 && \
    echo "2db82d1e7119df3e71b7640219b6dfe84789bc0537983c3b7ac4f7189aecfeaa  jemalloc.tar.bz2" > jemalloc-sha.txt && \
    sha256sum --quiet -c jemalloc-sha.txt && \
    mkdir -p /opt/jemalloc_5.3.0 && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory /opt/jemalloc_5.3.0 -xjf jemalloc.tar.bz2 && \
    cd /opt/jemalloc_5.3.0 && \
    ./configure --enable-static --disable-cxx --enable-prof && \
    make -j32 && \
    cd ../  && \
    rm -rf /tmp/*

# install msgpack
RUN curl -LsO https://github.com/msgpack/msgpack-c/releases/download/cpp-3.3.0/msgpack-3.3.0.tar.gz && \
    echo "6e114d12a5ddb8cb11f669f83f32246e484a8addd0ce93f274996f1941c1f07b  msgpack-3.3.0.tar.gz" > msgpack-sha.txt && \
    sha256sum --quiet -c msgpack-sha.txt && \
    mkdir -p /opt/msgpack_3.3.0 && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory /opt/msgpack_3.3.0 -xf msgpack-3.3.0.tar.gz && \
    cd /opt/msgpack_3.3.0 && \
    cmake . && \
    make && \
    cd ../ && \
    rm -rf /tmp/*

# Install CCACHE
RUN curl -Ls https://github.com/ccache/ccache/releases/download/v4.8.3/ccache-4.8.3.tar.gz -o ccache.tar.gz && \
    echo "d59dd569ad2bbc826c0bc335c8ebd73e78ed0f2f40ba6b30069347e63585d9ef  ccache.tar.gz" > ccache-sha256.txt && \
    sha256sum --quiet -c ccache-sha256.txt && \
    mkdir ccache &&\
    tar --strip-components 1 --no-same-owner --directory ccache -xf ccache.tar.gz && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DZSTD_FROM_INTERNET=ON ../ccache && \
    cmake --build . --target install && \
    cd ../ && \
    rm -rf /tmp/*

# build/install toml
RUN curl -Ls https://github.com/ToruNiina/toml11/archive/v3.4.0.tar.gz -o toml.tar.gz && \
    echo "bc6d733efd9216af8c119d8ac64a805578c79cc82b813e4d1d880ca128bd154d  toml.tar.gz" > toml-sha256.txt && \
    sha256sum --quiet -c toml-sha256.txt && \
    mkdir toml && \
    tar --strip-components 1 --no-same-owner --directory toml -xf toml.tar.gz && \
    cd toml && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -Dtoml11_BUILD_TEST=OFF ../ && \
    cmake --build . --target install && \
    cd ../ && \
    rm -rf /tmp/*

# build/install distcc
RUN curl -Ls https://github.com/distcc/distcc/archive/refs/tags/v3.4.tar.gz -o distcc.tar.gz && \
    echo "37a34c9555498a1168fea026b292ab07e7bb394715d87d8403e0c33b16d2d008  distcc.tar.gz" > distcc-sha256.txt && \
    sha256sum --quiet -c distcc-sha256.txt && \
    mkdir distcc && \
    tar --strip-components 1 --no-same-owner --directory distcc -xf distcc.tar.gz && \
    cd distcc && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# download old fdb binaries and client lib if not on aarch64
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        for old_fdb_version in 7.3.43 7.1.57 7.1.41 7.1.33 7.0.0 6.3.25 6.3.18; do \
            mkdir -p /opt/foundationdb/old/${old_fdb_version}/bin; \
            curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbserver.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbserver-${old_fdb_version}; \
            chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbserver-${old_fdb_version}; \
            curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbmonitor.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbmonitor-${old_fdb_version}; \
            chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbmonitor-${old_fdb_version}; \
            curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbcli.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbcli-${old_fdb_version}; \
            chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbcli-${old_fdb_version}; \
            mkdir -p /opt/foundationdb/old/${old_fdb_version}/lib; \
            curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/libfdb_c.x86_64.so -o /opt/foundationdb/old/${old_fdb_version}/lib/libfdb_c-${old_fdb_version}.so; \
        done; \
    fi

RUN curl -Ls https://github.com/manticoresoftware/manticoresearch/raw/master/misc/junit/ctest2junit.xsl -o /opt/ctest2junit.xsl

# Build and install gRPC and Protobuf.
RUN cd /tmp && \
    git clone --recurse-submodules -b v1.70.1 https://github.com/grpc/grpc.git ; \
    mkdir -p /tmp/grpc/build/ && \
    cd /tmp/grpc/build/ && \
    CC=clang CXX=clang++ \
      cmake ../ \
        -DCMAKE_INSTALL_PREFIX=/opt/grpc_clang/  \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_CXX_COMPILER=clang++ \
        -DCMAKE_LINKER=lld \
        -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
        -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -static-libgcc -nostdlib++ -Wl,-Bstatic -lc++ -lc++abi -Wl,-Bdynamic" \
        -DgRPC_INSTALL=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DgRPC_BUILD_TESTS=OFF \
        -DgRPC_ABSL_PROVIDER=module \
        -DgRPC_CARES_PROVIDER=module \
        -DgRPC_PROTOBUF_PROVIDER=module \
        -DgRPC_RE2_PROVIDER=module \
        -DgRPC_SSL_PROVIDER=package \
        -DgRPC_ZLIB_PROVIDER=package && \
    CC=clang CXX=clang++ make -j $(nproc) install && \
    rm -rf /tmp/grpc/build && \
    mkdir -p /tmp/grpc/build/ && \
    cd /tmp/grpc/build/ && \
    source /opt/rh/gcc-toolset-13/enable && \
    cmake ../ \
      -DCMAKE_INSTALL_PREFIX=/opt/grpc/  \
      -DCMAKE_CXX_FLAGS="-static-libstdc++ -static-libgcc" \
      -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc" \
      -DgRPC_INSTALL=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DgRPC_BUILD_TESTS=OFF \
      -DgRPC_ABSL_PROVIDER=module \
      -DgRPC_CARES_PROVIDER=module \
      -DgRPC_PROTOBUF_PROVIDER=module \
      -DgRPC_RE2_PROVIDER=module \
      -DgRPC_SSL_PROVIDER=package \
      -DgRPC_ZLIB_PROVIDER=package && \
    make -j $(nproc) install && \
    rm -rf /tmp/*

# Download swift binaries
RUN export DOWNLOAD_DIR="swift-6.1-RELEASE" && \
    echo $DOWNLOAD_DIR > .swift_tag && \
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME && \
    curl --compressed -fLs https://swift.org/keys/all-keys.asc | gpg --import -  && \
    if [ "$(uname -m)" == "aarch64" ]; then \
        curl -fLs https://download.swift.org/swift-6.1-release/ubi9-aarch64/swift-6.1-RELEASE/swift-6.1-RELEASE-ubi9-aarch64.tar.gz     -o latest_toolchain.tar.gz ; \
        curl -fLs https://download.swift.org/swift-6.1-release/ubi9-aarch64/swift-6.1-RELEASE/swift-6.1-RELEASE-ubi9-aarch64.tar.gz.sig -o latest_toolchain.tar.gz.sig ; \
    else \
        curl -fLs https://download.swift.org/swift-6.1-release/ubi9/swift-6.1-RELEASE/swift-6.1-RELEASE-ubi9.tar.gz     -o latest_toolchain.tar.gz ; \
        curl -fLs https://download.swift.org/swift-6.1-release/ubi9/swift-6.1-RELEASE/swift-6.1-RELEASE-ubi9.tar.gz.sig -o latest_toolchain.tar.gz.sig ; \
    fi && \
    gpg --batch --verify latest_toolchain.tar.gz.sig latest_toolchain.tar.gz && \
    tar -xzf latest_toolchain.tar.gz --directory / --strip-components=1 && \
    chmod -R o+r /usr/lib/swift && \
    rm -rf "$GNUPGHOME" latest_toolchain.tar.gz.sig latest_toolchain.tar.gz; \
    # Print Installed Swift Version
    swift --version

# install sphinx
RUN python3 -m pip install setuptools==65.3.0 sphinx-bootstrap-theme==0.8.1 docutils==0.19 sphinx==5.1.1 sphinx-autobuild Jinja2==3.1.2 urllib3==2.0.2

# Install seaweedfs, an ersatz 's3' service, for s3 tests.
ENV SEAWEEDFS_VERSION=3.80
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_arm64.tar.gz -o linux.tar.gz && \
        curl -Ls https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_arm64.tar.gz.md5 -o linux.tar.gz.md5 ; \
    else \
        curl -Ls https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_amd64.tar.gz -o linux.tar.gz && \
        curl -Ls https://github.com/seaweedfs/seaweedfs/releases/download/${SEAWEEDFS_VERSION}/linux_amd64.tar.gz.md5 -o linux.tar.gz.md5 ; \
    fi && \
    echo "$(cat linux.tar.gz.md5) linux.tar.gz" | md5sum --quiet -c && \
    tar --no-same-owner --no-same-permissions --directory /usr/local/bin -xzf linux.tar.gz weed && \
    cd /tmp && \
    rm -rf /tmp/*

# =========================== END OF LAYER: build ==============================
FROM build AS devel

WORKDIR /tmp

RUN dnf repolist && \
    dnf --enablerepo devel install -y \
        texinfo && \
    dnf -y install \
        bash-completion \
        bind-utils \
        emacs-nox \
        fish \
        gdb \
        htop \
        jq \
        libevent-devel \
        ncurses-devel \
        nload \
        nano \
        ripgrep \
        sysstat \
        the_silver_searcher \
        tree \
        valgrind-devel \
        vim-enhanced \
        zsh \
        tmux \
        flex \
        readline-devel \
        tig && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# install byobu \
RUN curl -Ls https://launchpad.net/byobu/trunk/5.133/+download/byobu_5.133.orig.tar.gz -o byobu.tar.gz && \
    echo "4d8ea48f8c059e56f7174df89b04a08c32286bae5a21562c5c6f61be6dab7563  byobu.tar.gz" > byobu-sha256.txt && \
    sha256sum --quiet -c byobu-sha256.txt && \
    mkdir byobu && \
    tar --strip-components 1 --no-same-owner --directory byobu -xf byobu.tar.gz && \
    cd byobu && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# install cgdb
RUN curl -Ls https://github.com/cgdb/cgdb/archive/refs/tags/v0.8.0.tar.gz -o cgdb.tar.gz && \
    echo "6d2408c1265185f3d39d3b6e4e079f7b1aa77a4ab117b19b3f490fff79d59b9e  cgdb.tar.gz" > cgdb-sha256.txt && \
    sha256sum --quiet -c cgdb-sha256.txt && \
    mkdir cgdb && \
    tar --strip-components 1 --no-same-owner --directory cgdb -xf cgdb.tar.gz && \
    cd cgdb && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local && \
    make -srj4 && \
    make install && \
    cd ../ && \
    rm -rf /tmp/*

# instal fdb-joshua
ENV ARTIFACT="client"
RUN pip3 install \
        boto3 \
        lxml \
        psutil \
        python-dateutil \
        subprocess32 \
        toml && \
    mkdir fdb-joshua && \
    cd fdb-joshua && \
    git clone https://github.com/FoundationDB/fdb-joshua . && \
    pip3 install /tmp/fdb-joshua && \
    cd /tmp && \
    rm -rf /tmp/*

# - Download kubectl from AWS https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.5/2023-09-14/bin/linux/arm64/kubectl -o kubectl && \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.5/2023-09-14/bin/linux/arm64/kubectl.sha256 -o kubectl.txt; \
    else \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.5/2023-09-14/bin/linux/amd64/kubectl -o kubectl && \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.5/2023-09-14/bin/linux/amd64/kubectl.sha256 -o kubectl.txt; \
    fi && \
    sha256sum --quiet -c kubectl.txt && \
    chmod 755 kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    cd /tmp && \
    rm -rf /tmp/*

# install k9s kubernetes client
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_arm64.tar.gz -o k9s.tar.gz && \
        echo "05f7b054b2f41a69f13893ec819a8aca43662a4bad61951e9887a6f92ecbf2d8  k9s.tar.gz" > k9s-sha.txt; \
    else \
        curl -Ls https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz -o k9s.tar.gz && \
        echo "e507831ebd5f9b8c0380f212669f352c6e34cb760c916b498babae8be83c4392  k9s.tar.gz" > k9s-sha.txt; \
    fi && \
    sha256sum --quiet -c k9s-sha.txt && \
    tar --no-same-owner --no-same-permissions --directory /usr/local/bin -xzf k9s.tar.gz k9s && \
    cd /tmp && \
    rm -rf /tmp/*

# install aws cli
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        AWSCLI_SHA256="1005c0342e66e8b3205f44908ced3e577079185dd1850ac9ee43be126f0a3693"; \
    else \
        AWSCLI_SHA256="b73bc4821fc674120ccf299848fc586e12297456273c509c66f3b168a28338f8"; \
    fi && \
    curl -Ls https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-2.13.25.zip -o "awscliv2.zip" && \
    echo "${AWSCLI_SHA256}  awscliv2.zip" > awscliv2.txt && \
    sha256sum --quiet -c awscliv2.txt && \
    unzip -qq awscliv2.zip && \
    ./aws/install && \
    cd /tmp && \
    rm -rf /tmp/*

# install fdb client lib for joshua
ARG FDB_VERSION="7.1.57"
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/libfdb_c.x86_64.so -o /usr/lib64/libfdb_c_${FDB_VERSION}.so && \
        ln -sf /usr/lib64/libfdb_c_${FDB_VERSION}.so /usr/lib64/libfdb_c.so; \
    fi

# install fdb header files for compiling the operator
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        rpm -ivh https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients-${FDB_VERSION}-1.el7.x86_64.rpm --excludepath=/etc/foundationdb --excludepath=/usr/bin --excludepath=/usr/lib --excludepath=/usr/lib64; \
    fi

# Installing helm https://helm.sh/docs/intro/install for e2e testing with the operator.
RUN pushd /tmp && \
    # Binaries and checksum are fetched from here: https://github.com/helm/helm/releases/tag/v3.12.0
    if [ "$(uname -m)" == "aarch64" ]; then \
        curl -sLo helm.tar.gz "https://get.helm.sh/helm-v3.12.0-linux-arm64.tar.gz" && echo "658839fed8f9be2169f5df68e55cb2f0aa731a50df454caf183186766800bbd0 helm.tar.gz" | sha256sum --quiet -c -; \
    else \
        curl -sLo helm.tar.gz "https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz" && echo "da36e117d6dbc57c8ec5bab2283222fbd108db86c83389eebe045ad1ef3e2c3b helm.tar.gz" | sha256sum --quiet -c -; \
    fi && \
    tar -zxvf /tmp/helm.tar.gz && \
    mv linux-*/helm /usr/local/bin/helm && \
    helm version --short && \
    popd && \
    rm -rf /tmp/*

WORKDIR /root

# add vscode server
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        VSCODE_ARCH="arm64"; \
    else \
        VSCODE_ARCH="x64"; \
    fi && \
    curl -Ls https://update.code.visualstudio.com/latest/server-linux-${VSCODE_ARCH}/stable -o /tmp/vscode-server-linux-${VSCODE_ARCH}.tar.gz && \
    mkdir -p .vscode-server/bin/latest && \
    tar --strip-components 1 --no-same-owner --directory .vscode-server/bin/latest -xf /tmp/vscode-server-linux-${VSCODE_ARCH}.tar.gz && \
    touch .vscode-server/bin/latest/0 && \
    rm -rf /tmp/*

RUN rm -f /root/anaconda-ks.cfg && \
    printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -Eeuo pipefail' \
    '' \
    'mkdir -p ~/.docker' \
    'cat > ~/.docker/config.json << EOF' \
    '{' \
    ' "aliases": {' \
    '   "builder": "buildx"' \
    ' },' \
    ' "proxies":' \
    ' {' \
    '   "default":' \
    '   {' \
    '     "httpProxy": "${HTTP_PROXY}",' \
    '     "httpsProxy": "${HTTPS_PROXY}",' \
    '     "noProxy": "${NO_PROXY}"' \
    '   }' \
    ' }' \
    '}' \
    'EOF' \
    > /usr/local/bin/docker_proxy.sh && \
    chmod 755 /usr/local/bin/docker_proxy.sh && \
    printf '%s\n' \
    '' \
    '# WARNING: THIS .bashrc WILL GET CLOBBERED PERIODICALLY BY OKTETO.  DO NOT EDIT.' \
    '# INSTEAD, EDIT ~/src/.bashrc.local .  SEE BELOW FOR HOW THAT IS USED.' \
    '# IF YOU NEED TO UPDATE THIS FILE, FORK https://github.com/FoundationDB/fdb-build-support.' \
    '' \
    'function cmk_ci() {' \
    '    source /opt/rh/gcc-toolset-13/enable' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D  BUILD_AWS_BACKUP=ON -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja 2>&1 | tee ${HOME}/cmake.log && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 all packages strip_targets 2>&1 | tee ${HOME}/ninja.log' \
    '}' \
    'function cmk() {' \
    '    source /opt/rh/gcc-toolset-13/enable' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D  BUILD_AWS_BACKUP=ON -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja 2>&1 | tee ${HOME}/cmake.log && \' \
    '    ninja -C ${HOME}/build_output -j 84 2>&1 | tee ${HOME}/ninja.log' \
    '}' \
    '' \
    'function ccmk_ci() {' \
    '    CC=clang CXX=clang++ USE_LD=LLD USE_LIBCXX=1 cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D  BUILD_AWS_BACKUP=ON -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja 2>&1 | tee ${HOME}/cmake.log && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 all packages strip_targets 2>&1 | tee ${HOME}/ninja.log' \
    '}' \
    'function ccmk() {' \
    '    CC=clang CXX=clang++ USE_LD=LLD USE_LIBCXX=1 cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D  BUILD_AWS_BACKUP=ON -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja 2>&1 | tee ${HOME}/cmake.log && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 2>&1 | tee ${HOME}/ninja.log' \
    '}' \
    'function ccmk_dbg() {' \
    '    CC=clang CXX=clang++ USE_LD=LLD USE_LIBCXX=1 cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D  BUILD_AWS_BACKUP=ON -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -D CMAKE_BUILD_TYPE=DEBUG -D FULL_DEBUG_SYMBOLS=ON -G Ninja 2>&1 | tee ${HOME}/cmake.log && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 2>&1 | tee ${HOME}/ninja.log' \
    '}' \
    'function ct() {' \
    '    cd ${HOME}/build_output && ctest -j 32 --no-compress-output -T test --output-on-failure 2>&1 | tee ${HOME}/ctest.log' \
    '}' \
    'function j() {' \
    '   python3 -m joshua.joshua "${@}"' \
    '}' \
    'function jsd() {' \
    '   j start --tarball $(find ${HOME}/build_output/packages -name correctness\*.tar.gz) "${@}"' \
    '}' \
    '' \
    'function fmt() {' \
    '   find ${HOME}/src/foundationdb -type f \( -name \*.c -o -name \*.cpp -o -name \*.h -o -name \*.hpp \) -a \( ! -name sqlite3.amalgamation.c \) -a \( ! -path \*.git\* \) -exec clang-format -style=file -i "{}" \;' \
    '}' \
    '' \
    'USER_BASHRC="$HOME/src/.bashrc.local"' \
    'if test -f "$USER_BASHRC"; then' \
    '   source $USER_BASHRC' \
    'fi' \
    '' \
    'function addr2line() {' \
    '    EXECUTABLE=""' \
    '    while getopts ":e:" OPTION' \
    '    do' \
    '            case "$OPTION" in' \
    '                    e)' \
    '                            EXECUTABLE="$OPTARG"' \
    '                            ;;' \
    '                    ?)' \
    '                            ;;' \
    '            esac' \
    '    done' \
    '    if [ -z $EXECUTABLE ]' \
    '    then' \
    '            echo "Missing executable"' \
    '            return' \
    '    fi' \
    '    readelf -p .comment $EXECUTABLE | grep -q "clang"' \
    '    if [ $? -eq 0 ]' \
    '    then' \
    '            # This is a clang generated ELF' \
    '            llvm-addr2line "$@"' \
    '    else' \
    '            # This is gcc/other compiler generated ELF' \
    '            command addr2line "$@"' \
    '    fi' \
    '}' \
    '' \
    >> .bashrc

# =========================== END OF LAYER: devel ==============================
FROM build AS distcc

RUN useradd distcc && \
    update-distcc-symlinks

EXPOSE 3632
EXPOSE 3633
USER distcc
ENV ALLOW 0.0.0.0/0

ENTRYPOINT distccd \
           --daemon \
           --enable-tcp-insecure \
           --no-detach \
           --port 3632 \
           --log-stderr \
           --log-level info \
           --listen 0.0.0.0 \
           --allow ${ALLOW} \
           --jobs `nproc`

# =========================== END OF LAYER: distcc =============================
FROM devel AS codebuild

COPY dockerd-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["dockerd-entrypoint.sh"]

# =========================== END OF LAYER: codebuild ==========================
