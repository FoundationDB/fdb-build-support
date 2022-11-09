FROM centos:7 as build

WORKDIR /tmp
RUN rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org && \
    yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm && \
    yum -y --enablerepo=elrepo-kernel install kernel-lt{,-devel,-headers} \ && \
    rpm --import https://download.mono-project.com/repo/xamarin.gpg && \
    curl -Ls https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo && \
    yum repolist && \
    yum install -y \
        centos-release-scl-rh \
        epel-release \
        scl-utils \
        yum-utils && \
    yum install -y \
        autoconf \
        automake \
        bin-utils \
        binutils-devel \
        curl \
        debbuild \
        devtoolset-8 \
        devtoolset-8-libasan-devel \
        devtoolset-8-libatomic-devel \
        devtoolset-8-libtsan-devel \
        devtoolset-8-libubsan-devel \
        devtoolset-8-systemtap-sdt-devel \
        dos2unix \
        dpkg \
        gettext-devel \
        gperftools \
        gperftools-devel \
        gperftools-libs \
        ghostscript \
        glibc-static \
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
        python2 \
        redhat-lsb-core \
        rh-python38 \
        rh-python38-python-devel \
        rh-ruby27 \
        rpm-build \
        shadow-utils \
        sqlite \
        tcl-devel \
        unzip \
        vim-enhanced \
        wget \
        zlib-devel \
        && \
    rm -f /etc/yum.repos.d/mono-centos7-stable.repo && \
    yum clean all && \
    rm -rf /var/cache/yum

# TODO: Is this really necessary?!? -- from swift's dockerfile
RUN sed -i -e 's/\*__block/\*__libc_block/g' /usr/include/unistd.h


# install docker 19
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="v2.0.1"

ENV DOCKER_VERSION="19.03.11"

VOLUME /var/lib/docker

RUN set -ex \
    && if [ "$(uname -m)" == "aarch64" ]; then \
        DOCKER_SHA256="9cd49fe82f6b7ec413b04daef35bc0c87b01d6da67611e5beef36291538d3145"; \
    else \
        DOCKER_SHA256="0f4336378f61ed73ed55a356ac19e46699a995f2aff34323ba5874d131548b9e"; \
    fi \
    && curl -fSLs "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/$(uname -m)/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum --quiet -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && curl -Ls "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind \
    && curl -Ls https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
    && docker-compose version

# build/install lz4
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    source /opt/rh/rh-ruby27/enable && \
    curl -Ls https://github.com/lz4/lz4/archive/refs/tags/v1.9.3.tar.gz -o lz4.tar.gz && \
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
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    source /opt/rh/rh-ruby27/enable && \
    curl -Ls https://github.com/axboe/liburing/archive/refs/tags/liburing-2.1.tar.gz -o liburing.tar.gz && \
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
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/git/git/archive/v2.30.0.tar.gz -o git.tar.gz && \
    echo "8db4edd1a0a74ebf4b78aed3f9e25c8f2a7db3c00b1aaee94d1e9834fae24e61  git.tar.gz" > git-sha.txt && \
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
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/ninja-build/ninja/archive/refs/tags/v1.10.2.zip -o ninja.zip && \
    echo "4e7b67da70a84084d5147a97fcfb867660eff55cc60a95006c389c4ca311b77d  ninja.zip" > ninja-sha.txt && \
    sha256sum --quiet -c ninja-sha.txt && \
    unzip ninja.zip && \
    cd ninja-1.10.2 && \
    ./configure.py --bootstrap && \
    cp ninja /usr/bin && \
    cd .. && \
    rm -rf /tmp/*

# install cmake
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        CMAKE_SHA256="5f1c0d49bac89915b5c68811c2430e5de6c8e606785b9f2919eabee86c2f12b4"; \
    else \
        CMAKE_SHA256="71a776b6a08135092b5beb00a603b60ca39f8231c01a0356e205e0b4631747d9"; \
    fi && \
    curl -Ls https://github.com/Kitware/CMake/releases/download/v3.24.2/cmake-3.24.2-$(uname -s)-$(uname -m).tar.gz -o cmake.tar.gz && \
    echo "${CMAKE_SHA256}  cmake.tar.gz" > cmake-sha.txt && \
    sha256sum --quiet -c cmake-sha.txt && \
    mkdir cmake && \
    tar --strip-components 1 --no-same-owner --directory cmake -xf cmake.tar.gz && \
    cp -r cmake/* /usr/local/ && \
    rm -rf /tmp/*

# build/install LLVM
# compiler-rt, libcxx and libcxxabi can't be built with gcc<11
#     ref: https://libcxx.llvm.org/#platform-and-compiler-support)
# so build and install clang first, then build other components and with clang
# build clang a second time to pass component check
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    curl -Ls https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.0/llvm-project-13.0.0.src.tar.xz -o llvm.tar.xz && \
    echo "6075ad30f1ac0e15f07c1bf062c1e1268c241d674f11bd32cdf0e040c71f2bf3  llvm.tar.xz" > llvm-sha.txt && \
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
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb" \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        ../llvm && \
    cmake --build . && \
    cmake --build . --target install && \
    cd .. && \
    rm -rf build && \
    mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        -Wno-dev \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;libcxx;libcxxabi;libunwind" \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DCMAKE_C_COMPILER=/usr/local/bin/clang \
        -DCMAKE_CXX_COMPILER=/usr/local/bin/clang++ \
        ../llvm && \
    cmake --build . && \
    cmake --build . --target install && \
    cd ../.. && \
    rm -rf /tmp/*

# build/install openssl
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://www.openssl.org/source/openssl-1.1.1m.tar.gz -o openssl.tar.gz && \
    echo "f89199be8b23ca45fc7cb9f1d8d3ee67312318286ad030f5316aca6462db6c96  openssl.tar.gz" > openssl-sha.txt && \
    sha256sum --quiet -c openssl-sha.txt && \
    mkdir openssl && \
    tar --strip-components 1 --no-same-owner --directory openssl -xf openssl.tar.gz && \
    cd openssl && \
    ./config CFLAGS="-fPIC -O3" --prefix=/usr/local && \
    make -j`nproc` && \
    make -j1 install && \
    ln -sv /usr/local/lib64/lib*.so.1.1 /usr/lib64/ && \
    cd .. && \
    rm -rf /tmp/*

# install golang 1.19
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        GOLANG_ARCH="arm64"; \
        GOLANG_SHA256="99de2fe112a52ab748fb175edea64b313a0c8d51d6157dba683a6be163fd5eab"; \
    else \
        GOLANG_ARCH="amd64"; \
        GOLANG_SHA256="74b9640724fd4e6bb0ed2a1bc44ae813a03f1e72a4c76253e2d5c015494430ba"; \
    fi && \
    curl -Ls https://golang.org/dl/go1.19.3.linux-${GOLANG_ARCH}.tar.gz -o golang.tar.gz && \
    echo "${GOLANG_SHA256}  golang.tar.gz" > golang-sha.txt && \
    sha256sum --quiet -c golang-sha.txt && \
    tar --directory /usr/local -xf golang.tar.gz && \
    echo '[ -x /usr/local/go/bin/go ] && export GOROOT=/usr/local/go && export GOPATH=$HOME/go && export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /etc/profile.d/golang.sh && \
    source /etc/profile.d/golang.sh && \
    go install github.com/onsi/ginkgo/v2/ginkgo@v2.1.3 && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/segmentio/golines@latest && \
    go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.9.2 && \
    go install sigs.k8s.io/kustomize/kustomize/v4@v4.5.2 && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1 && \
    go install github.com/goreleaser/goreleaser@v1.6.3 && \
    rm -rf /tmp/*

# build/install boringssl
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    source /opt/rh/rh-ruby27/enable && \
    source /etc/profile.d/golang.sh && \
    mkdir -p /opt/boringssl && \
    cd /opt/boringssl && \
    git clone https://boringssl.googlesource.com/boringssl . && \
    git checkout e796cc65025982ed1fb9ef41b3f74e8115092816 && \
    for file in crypto/fipsmodule/rand/fork_detect_test.cc include/openssl/bn.h ssl/test/bssl_shim.cc; do \
        perl -p -i -e 's/#include <inttypes.h>/#define __STDC_FORMAT_MACROS 1\n#include <inttypes.h>/g;' $file; \
    done && \
    perl -p -i -e 's/-Werror/-Werror -fPIC/' CMakeLists.txt && \
    git diff && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. && \
    ninja && \
    ./ssl/ssl_test && \
    mkdir -p /opt/boringssl/lib && \
    cp crypto/libcrypto.a ssl/libssl.a /opt/boringssl/lib/

# build/install wolfssl
RUN source /opt/rh/devtoolset-8/enable && \
    mkdir wolfssl && \
    pushd  wolfssl && \
    git init && \
    git remote add origin https://github.com/wolfSSL/wolfssl.git && \
    # e1829e6: Add wolfSSL_EVP_PKEY_paramgen to the compatibility layer. \
    git fetch --depth 1 origin e1829e614d35ad2dd1d6cc06d493158f16cca505 && \
    git checkout FETCH_HEAD && \
    # add new macro \
    sed -i "$(grep -nE '^#define ASN1_IA5STRING.*' wolfssl/openssl/ssl.h | awk -F':' '{ print $1 }' | head -n1) i #define ASN1_IA5STRING_new              wolfSSL_ASN1_STRING_new" wolfssl/openssl/ssl.h && \
    # fix naming collision \
    sed -i 's/internal_error/wolfssl_internal_error/g' src/internal.c src/ssl.c wolfssl/ssl.h && \
    # fix to allow our version of autoconf \
    sed -i 's/1\.14\.1/1.13.4/g' configure.ac && \
    ./autogen.sh && \
    ./configure CFLAGS="-O3 -fPIC" --prefix=/opt/wolfSSL --enable-aesni \
     --enable-aesgcm  --enable-aesctr  --enable-intelasm \
     --enable-sp --enable-sp-asm --enable-sp-math-all \
     --enable-opensslextra --enable-opensslall --enable-asio \
     --enable-static  --enable-pwdbased --enable-sessioncerts && \
    make -j "$(nproc)" && \
    make install && \
    popd && \
    rm -rf /tmp/*

# install gradle
RUN curl -Ls https://services.gradle.org/distributions/gradle-7.5.1-bin.zip -o gradle.zip && \
    echo "f6b8596b10cce501591e92f229816aa4046424f3b24d771751b06779d58c8ec4  gradle.zip" > gradle-sha.txt && \
    sha256sum --quiet -c gradle-sha.txt && \
    unzip -qq gradle.zip && \
    mv gradle-7.5.1 /opt/gradle && \
    echo '[ -x /opt/gradle/bin/gradle ] && export PATH=/opt/gradle/bin/:$PATH' >> /etc/profile.d/gradle.sh && \
    rm -rf /tmp/*

# install maven
RUN curl -Ls https://archive.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.zip -o maven.zip && \
    echo "f28cd38f620d76423c4543d5b443cdbdd5cfac2c511626cb92be3d5d273a6959  maven.zip" > maven-sha.txt && \
    sha256sum --quiet -c maven-sha.txt && \
    unzip -qq maven.zip && \
    mv apache-maven-3.8.3 /opt/maven && \
    echo '[ -x /opt/maven/bin/mvn ] && export PATH=/opt/maven/bin/:$PATH' >> /etc/profile.d/maven.sh && \
    rm -rf /tmp/*

# install rocksdb to /opt
RUN curl -Ls https://github.com/facebook/rocksdb/archive/refs/tags/v6.27.3.tar.gz -o rocksdb.tar.gz && \
    echo "ee29901749b9132692b26f0a6c1d693f47d1a9ed8e3771e60556afe80282bf58  rocksdb.tar.gz" > rocksdb-sha.txt && \
    sha256sum --quiet -c rocksdb-sha.txt && \
    tar --directory /opt -xf rocksdb.tar.gz && \
    rm -rf /tmp/*

# install Boost::context, Boost::filesystem & Boost::iostreams 1.78 to /opt
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.bz2 -o boost_1_78_0.tar.bz2 && \
    echo "8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc  boost_1_78_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_78_0 && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_78_0 -xjf boost_1_78_0.tar.bz2 && \
    cd /opt/boost_1_78_0 && \
    ./bootstrap.sh --with-libraries=context,filesystem,iostreams &&\
    ./b2 link=static cxxflags="-std=c++14 -fPIC" --prefix=/opt/boost_1_78_0 install &&\
    rm -rf /opt/boost_1_78_0/libs && \
    rm -rf /tmp/*

# Install Boost::context, Boost::filesystem & Boost::iostreams 1.78 to /opt, using clang to compile the library
# Boost::context depens on some C++11 features, e.g. std::call_once; however,
# gcc and clang are using different ABIs, thus a gcc-built Boost::context is
# not linkable to clang objects.
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/boost_1_78_0.tar.bz2 -o boost_1_78_0.tar.bz2 && \
    echo "8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc  boost_1_78_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    mkdir -p /opt/boost_1_78_0_clang && \
    tar --strip-components 1 --no-same-owner --directory /opt/boost_1_78_0_clang -xjf boost_1_78_0.tar.bz2 && \
    cd /opt/boost_1_78_0_clang && \
    ./bootstrap.sh --with-toolset=clang --with-libraries=context,filesystem,iostreams && \
    ./b2 link=static cxxflags="-std=c++14 -stdlib=libc++ -nostdlib++ -fPIC" linkflags="-stdlib=libc++ -nostdlib++ -static-libgcc -lc++ -lc++abi" --prefix=/opt/boost_1_78_0_clang install && \
    rm -rf /opt/boost_1_78_0_clang/libs && \
    rm -rf /tmp/*

# jemalloc (needed for FDB after 6.3)
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 -o jemalloc-5.2.1.tar.bz2 && \
    echo "34330e5ce276099e2e8950d9335db5a875689a4c6a56751ef3b1d8c537f887f6  jemalloc-5.2.1.tar.bz2" > jemalloc-sha.txt && \
    sha256sum --quiet -c jemalloc-sha.txt && \
    mkdir jemalloc && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory jemalloc -xjf jemalloc-5.2.1.tar.bz2 && \
    cd jemalloc && \
    ./configure --enable-static --disable-cxx --enable-prof && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# Install CCACHE
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/ccache/ccache/releases/download/v4.0/ccache-4.0.tar.gz -o ccache.tar.gz && \
    echo "ac97af86679028ebc8555c99318352588ff50f515fc3a7f8ed21a8ad367e3d45  ccache.tar.gz" > ccache-sha256.txt && \
    sha256sum --quiet -c ccache-sha256.txt && \
    mkdir ccache &&\
    tar --strip-components 1 --no-same-owner --directory ccache -xf ccache.tar.gz && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DZSTD_FROM_INTERNET=ON ../ccache && \
    cmake --build . --target install && \
    cd .. && \
    rm -rf /tmp/*

# build/install toml
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/ToruNiina/toml11/archive/v3.4.0.tar.gz -o toml.tar.gz && \
    echo "bc6d733efd9216af8c119d8ac64a805578c79cc82b813e4d1d880ca128bd154d  toml.tar.gz" > toml-sha256.txt && \
    sha256sum --quiet -c toml-sha256.txt && \
    mkdir toml && \
    tar --strip-components 1 --no-same-owner --directory toml -xf toml.tar.gz && \
    cd toml && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -Dtoml11_BUILD_TEST=OFF ../ && \
    cmake --build . --target install && \
    cd .. && \
    rm -rf /tmp/*

# build/install distcc
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    curl -Ls https://github.com/distcc/distcc/archive/v3.3.5.tar.gz -o distcc.tar.gz && \
    echo "13a4b3ce49dfc853a3de550f6ccac583413946b3a2fa778ddf503a9edc8059b0  distcc.tar.gz" > distcc-sha256.txt && \
    sha256sum --quiet -c distcc-sha256.txt && \
    mkdir distcc && \
    tar --strip-components 1 --no-same-owner --directory distcc -xf distcc.tar.gz && \
    cd distcc && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# valgrind
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://sourceware.org/pub/valgrind/valgrind-3.17.0.tar.bz2 -o valgrind-3.17.0.tar.bz2 && \
    echo "ad3aec668e813e40f238995f60796d9590eee64a16dff88421430630e69285a2  valgrind-3.17.0.tar.bz2" > valgrind-sha.txt && \
    sha256sum --quiet -c valgrind-sha.txt && \
    mkdir valgrind && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory valgrind -xjf valgrind-3.17.0.tar.bz2 && \
    cd valgrind && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# download old fdb binaries and client lib
RUN for old_fdb_version in 7.1.23 7.1.19 7.0.0 6.3.23 6.3.22 6.3.18 6.3.17 6.3.16 6.3.15 6.3.13 6.3.12 6.3.9 6.2.30 6.2.29 6.2.28 6.2.27 6.2.26 6.2.25 6.2.24 6.2.23 6.2.22 6.2.21 6.2.20 6.2.19 6.2.18 6.2.17 6.2.16 6.2.15 6.2.10 6.1.13 6.1.12 6.1.11 6.1.10 6.0.18 6.0.17 6.0.16 6.0.15 6.0.14 5.2.8 5.2.7 5.1.7 5.1.6; do \
        mkdir -p /opt/foundationdb/old/${old_fdb_version}/bin; \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbserver.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbserver-${old_fdb_version}; \
        chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbserver-${old_fdb_version}; \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbmonitor.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbmonitor-${old_fdb_version}; \
        chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbmonitor-${old_fdb_version}; \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/fdbcli.x86_64 -o /opt/foundationdb/old/${old_fdb_version}/bin/fdbcli-${old_fdb_version}; \
        chmod +x /opt/foundationdb/old/${old_fdb_version}/bin/fdbcli-${old_fdb_version}; \
        mkdir -p /opt/foundationdb/old/${old_fdb_version}/lib; \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_version}/libfdb_c.x86_64.so -o /opt/foundationdb/old/${old_fdb_version}/lib/libfdb_c-${old_fdb_version}.so; \
    done

RUN curl -Ls https://github.com/manticoresoftware/manticoresearch/raw/master/misc/junit/ctest2junit.xsl -o /opt/ctest2junit.xsl

# Download Rust binaries
ENV RUSTUP_VERSION=1.24.3 \
    RUST_VERSION=1.59.0
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        RUST_ARCH="aarch64-unknown-linux-gnu"; \
        RUST_SHA256="32a1532f7cef072a667bac53f1a5542c99666c4071af0c9549795bbdb2069ec1"; \
    else \
        RUST_ARCH="x86_64-unknown-linux-gnu"; \
        RUST_SHA256="3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338"; \
    fi && \
    curl -LsO "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${RUST_ARCH}/rustup-init" && \
    echo "${RUST_SHA256}  rustup-init" > rustup-sha.txt && \
    sha256sum --quiet -c rustup-sha.txt && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain ${RUST_VERSION} --default-host ${RUST_ARCH} && \
    rm -rf /tmp/*

# Download swift binaries
ARG SWIFT_SIGNING_KEY=8A7495662C3CD4AE18D95637FAF6989E1BC16FEA
ARG SWIFT_PLATFORM=centos
ARG OS_MAJOR_VER=7
ARG SWIFT_WEBROOT=https://download.swift.org/development

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
    SWIFT_PLATFORM=$SWIFT_PLATFORM \
    OS_MAJOR_VER=$OS_MAJOR_VER \
    OS_VER=$SWIFT_PLATFORM$OS_MAJOR_VER \
    SWIFT_WEBROOT="$SWIFT_WEBROOT/$SWIFT_PLATFORM$OS_MAJOR_VER"

RUN echo "${SWIFT_WEBROOT}/latest-build.yml"

RUN set -e; \
    # - Latest Toolchain info
    export $(curl -s ${SWIFT_WEBROOT}/latest-build.yml | grep 'download:' | sed 's/:[^:\/\/]/=/g')  \
    && export $(curl -s ${SWIFT_WEBROOT}/latest-build.yml | grep 'download_signature:' | sed 's/:[^:\/\/]/=/g')  \
    && export DOWNLOAD_DIR=$(echo $download | sed "s/-${OS_VER}.tar.gz//g") \
    && echo $DOWNLOAD_DIR > .swift_tag \
    # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
    && export GNUPGHOME="$(mktemp -d)" \
    && curl -fL ${SWIFT_WEBROOT}/${DOWNLOAD_DIR}/${download} -o latest_toolchain.tar.gz \
    ${SWIFT_WEBROOT}/${DOWNLOAD_DIR}/${download_signature} -o latest_toolchain.tar.gz.sig \
    && curl -fL https://swift.org/keys/all-keys.asc | gpg --import -  \
    && gpg --batch --verify latest_toolchain.tar.gz.sig latest_toolchain.tar.gz \
    # - Unpack the toolchain, set libs permissions, and clean up.
    && tar -xzf latest_toolchain.tar.gz --directory / --strip-components=1 \
    && chmod -R o+r /usr/lib/swift \
    && rm -rf "$GNUPGHOME" latest_toolchain.tar.gz.sig latest_toolchain.tar.gz

# Print Installed Swift Version
RUN swift --version

# =========================== END OF LAYER: build ==============================
FROM build as devel

# protobuf-compiler and protobuf-devel are used to generate reference data for some tests.

RUN yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo && \
    yum repolist && \
    yum -y install \
        bash-completion \
        byobu \
        cgdb \
        emacs-nox \
        fish \
        htop \
        jq \
        libevent-devel \
        ncurses-devel \
        nload \
        protobuf-compiler \
        protobuf-devel \
        nano \
        ripgrep \
        sysstat \
        the_silver_searcher \
        tree \
        vim-enhanced \
        zsh && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR /tmp
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    pip3 install \
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
    curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl -o kubectl && \
    echo "860c3d37a5979491895767e7332404d28dc0d7797c7673c33df30ca80e215a07  kubectl" > kubectl.txt && \
    sha256sum --quiet -c kubectl.txt && \
    chmod 755 kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    curl -Ls https://github.com/derailed/k9s/releases/download/v0.26.5/k9s_Linux_x86_64.tar.gz -o k9s.tar.gz && \
    echo "8ae556d05b4744f7b79cc71549e4096daa9c6b913be88ee43be42ef800137bc3  k9s.tar.gz" > k9s-sha.txt && \
    sha256sum --quiet -c k9s-sha.txt && \
    tar --no-same-owner --no-same-permissions --directory /usr/local/bin -xzf k9s.tar.gz k9s && \
    if [ "$(uname -m)" == "aarch64" ]; then \
        AWSCLI_SHA256="bcb195622f0956c8569736b95bff9cff7f5684e400e694a33661f2d498fbc799"; \
    else \
        AWSCLI_SHA256="daf9253f0071b5cfee9532bc5220bedd7a5d29d4e0f92b42b9e3e4c496341e88"; \
    fi && \
    curl -Ls https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-2.7.34.zip -o "awscliv2.zip" && \
    echo "${AWSCLI_SHA256}  awscliv2.zip" > awscliv2.txt && \
    sha256sum --quiet -c awscliv2.txt && \
    unzip -qq awscliv2.zip && \
    ./aws/install && \
    rm -rf /tmp/*

# install tig (git client)
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/jonas/tig/releases/download/tig-2.5.4/tig-2.5.4.tar.gz -o tig.tar.gz && \
    echo "c48284d30287a6365f8a4750eb0b122e78689a1aef8ce1d2961b6843ac246aa7  tig.tar.gz" > tig-sha.txt && \
    sha256sum --quiet -c tig-sha.txt && \
    mkdir tig && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory tig -xzf tig.tar.gz && \
    cd tig && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# install newer tmux
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/tmux/tmux/releases/download/3.1c/tmux-3.1c.tar.gz -o tmux.tar.gz && \
    echo "918f7220447bef33a1902d4faff05317afd9db4ae1c9971bef5c787ac6c88386  tmux.tar.gz" > tmux-sha.txt && \
    sha256sum --quiet -c tmux-sha.txt && \
    mkdir tmux && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory tmux -xzf tmux.tar.gz && \
    cd tmux && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

ARG FDB_VERSION="6.3.18"
RUN mkdir -p /usr/lib/foundationdb/plugins && \
    curl -Ls https://fdb-joshua.s3.amazonaws.com/old_tls_library.tgz | \
        tar --strip-components=1 --no-same-owner --directory /usr/lib/foundationdb/plugins -xz && \
    ln -sf /usr/lib/foundationdb/plugins/FDBGnuTLS.so /usr/lib/foundationdb/plugins/fdb-libressl-plugin.so && \
    curl -Ls https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/libfdb_c.x86_64.so -o /usr/lib64/libfdb_c_${FDB_VERSION}.so && \
    ln -sf /usr/lib64/libfdb_c_${FDB_VERSION}.so /usr/lib64/libfdb_c.so

# Install header files for compling the operator
RUN rpm -ivh https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients-${FDB_VERSION}-1.el7.x86_64.rpm --excludepath=/etc/foundationdb --excludepath=/usr/bin --excludepath=/usr/lib --excludepath=/usr/lib64

WORKDIR /root
# Pull in rust developer tools -- we use "nightly" for development
# for extra warning messages and support for cargo fuzz
RUN source $HOME/.cargo/env \
    rustup default nightly \
    rustup component add rust-analysis \
    rustup component add rust-src \
    rustup component add rls \
    cargo install cargo-fuzz

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
    'source /opt/rh/devtoolset-8/enable' \
    'source /opt/rh/rh-python38/enable' \
    'source /opt/rh/rh-ruby27/enable' \
    '' \
    'function cmk_ci() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.27.3 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 all packages strip_targets' \
    '}' \
    'function cmk() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.27.3 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -C ${HOME}/build_output -j 84' \
    '}' \
    'function ccmk() {' \
    '    CC=clang CXX=clang++ cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.27.3 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -C ${HOME}/build_output -j 84' \
    '}' \
    'function ct() {' \
    '    cd ${HOME}/build_output && ctest -j 32 --no-compress-output -T test --output-on-failure' \
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
    'source $HOME/.cargo/env' \
    '' \
    '# export OPENSSL_ROOT_DIR=/opt/boringssl'  \
    >> .bashrc

# =========================== END OF LAYER: devel ==============================
FROM build as distcc

RUN useradd distcc && \
    source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
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
FROM devel as codebuild

COPY dockerd-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["dockerd-entrypoint.sh"]

# =========================== END OF LAYER: codebuild ==========================
