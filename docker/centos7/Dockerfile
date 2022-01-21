FROM centos:7 as build

WORKDIR /tmp
RUN rpm --import https://download.mono-project.com/repo/xamarin.gpg && \
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
        # for autofdo
        elfutils-libelf-devel \
        gettext-devel \
        git \
        iptables \
        java-11-openjdk-devel \
        libcurl-devel \
        # For protobuf
        libtool \
        libuuid-devel \
        libxslt \
        lz4 \
        lz4-devel \
        lz4-static \
        mono-devel \
        redhat-lsb-core \
        rh-python38 \
        rh-python38-python-devel \
        rh-ruby27 \
        rpm-build \
        tcl-devel \
        unzip \
        vim-enhanced \
        wget && \
    rm /etc/yum.repos.d/mono-centos7-stable.repo && \
    yum clean all && \
    rm -rf /var/cache/yum

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
        CMAKE_SHA256="69ec045c6993907a4f4a77349d0a0668f1bd3ce8bc5f6fbab6dc7a7e2ffc4f80"; \
    else \
        CMAKE_SHA256="139580473b84f5c6cf27b1d1ac84e9aa6968aa13e4b1900394c50075b366fb15"; \
    fi && \
    curl -Ls https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6-$(uname -s)-$(uname -m).tar.gz -o cmake.tar.gz && \
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
        # Enable RTTI for autofdo        
        -DLLVM_ENABLE_RTTI=ON \
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
        # Enable RTTI for autofdo
        -DLLVM_ENABLE_RTTI=ON \
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
    curl -Ls https://www.openssl.org/source/openssl-1.1.1h.tar.gz -o openssl.tar.gz && \
    echo "5c9ca8774bd7b03e5784f26ae9e9e6d749c9da2438545077e6b3d755a06595d9  openssl.tar.gz" > openssl-sha.txt && \
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

# install golang 1.16
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        GOLANG_ARCH="arm64"; \
        GOLANG_SHA256="63d6b53ecbd2b05c1f0e9903c92042663f2f68afdbb67f4d0d12700156869bac"; \
    else \
        GOLANG_ARCH="amd64"; \
        GOLANG_SHA256="7fe7a73f55ba3e2285da36f8b085e5c0159e9564ef5f63ee0ed6b818ade8ef04"; \
    fi && \
    curl -Ls https://golang.org/dl/go1.16.7.linux-${GOLANG_ARCH}.tar.gz -o golang.tar.gz && \
    echo "${GOLANG_SHA256}  golang.tar.gz" > golang-sha.txt && \
    sha256sum --quiet -c golang-sha.txt && \
    tar --directory /usr/local -xf golang.tar.gz && \
    echo '[ -x /usr/local/go/bin/go ] && export GOROOT=/usr/local/go && export GOPATH=$HOME/go && export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> /etc/profile.d/golang.sh && \
    source /etc/profile.d/golang.sh && \
    go get github.com/onsi/ginkgo/ginkgo@34fc8cd4f44d95736edd25aba7310a6da69620e1 && \
    go get golang.org/x/tools/cmd/goimports && \
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

# install gradle
RUN curl -Ls https://services.gradle.org/distributions/gradle-7.2-bin.zip -o gradle.zip && \
    echo "f581709a9c35e9cb92e16f585d2c4bc99b2b1a5f85d2badbd3dc6bff59e1e6dd  gradle.zip" > gradle-sha.txt && \
    sha256sum --quiet -c gradle-sha.txt && \
    unzip -qq gradle.zip && \
    mv gradle-7.2 /opt/gradle && \
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
RUN curl -Ls https://github.com/facebook/rocksdb/archive/v6.22.1.tar.gz -o rocksdb.tar.gz && \
    echo "2df8f34a44eda182e22cf84dee7a14f17f55d305ff79c06fb3cd1e5f8831e00d  rocksdb.tar.gz" > rocksdb-sha.txt && \
    sha256sum --quiet -c rocksdb-sha.txt && \
    tar --directory /opt -xf rocksdb.tar.gz && \
    rm -rf /tmp/*

# install Boost::context 1.77 to /opt
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2 -o boost_1_77_0.tar.bz2 && \
    echo "fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854  boost_1_77_0.tar.bz2" > boost-sha.txt && \
    sha256sum --quiet -c boost-sha.txt && \
    tar --no-same-owner --directory /opt -xjf boost_1_77_0.tar.bz2 && \
    cd /opt/boost_1_77_0 &&\
    ./bootstrap.sh --with-libraries=context &&\
    ./b2 link=static cxxflags=-std=c++14 --prefix=/opt/boost_1_77_0 install &&\
    rm -rf /opt/boost_1_77_0/libs && \
    rm -rf /tmp/*

# Install Boost::context 1.77 to /opt, using clang to compile the library
# Boost::context depens on some C++11 features, e.g. std::call_once; however,
# gcc and clang are using different ABIs, thus a gcc-built Boost::context is
# not linkable to clang objects.
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2 -o boost_1_77_0.tar.bz2 && \
    echo "fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854  boost_1_77_0.tar.bz2" > boost-sha-77.txt && \
    sha256sum --quiet -c boost-sha-77.txt && \
    tar --no-same-owner --directory /tmp -xjf boost_1_77_0.tar.bz2 && \
    mv /tmp/boost_1_77_0 /opt/boost_1_77_0_clang && \
    cd /opt/boost_1_77_0_clang && \
    ./bootstrap.sh --with-toolset=clang --with-libraries=context && \
    ./b2 link=static cxxflags="-std=c++14 -stdlib=libc++ -nostdlib++" linkflags="-stdlib=libc++ -nostdlib++ -static-libgcc -lc++ -lc++abi" --prefix=/opt/boost_1_77_0_clang install && \
    rm -rf /opt/boost_1_77_0_clang/libs && \
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
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -Dtoml11_BUILD_TEST=OFF ../toml && \
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

# protobuf, it's used in autofdo
RUN source /opt/rh/devtoolset-8/enable && \
    git clone https://github.com/protocolbuffers/protobuf.git && \
    cd protobuf && \
    git submodule update --init --recursive && \
    ./autogen.sh && \
    ./configure && \
    make check && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# autofdo, the master branch is broken, checkout branch zyang/fix_build instead.
RUN source /opt/rh/devtoolset-8/enable && \
    git clone --recursive https://github.com/sfc-gh-zyang/autofdo.git && \
    cd autofdo && \
    git checkout zyang/fix_build && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_INSTALL_PREFIX=. -DLLVM_PATH=/usr/local ../ && \
    ninja create_llvm_prof && \
    cp create_llvm_prof /usr/bin && \
    cd .. && \
    rm -rf /tmp/*

# download old fdbserver binaries
ARG FDB_VERSION="6.3.23"
RUN mkdir -p /opt/foundationdb/old && \
    for old_fdb_server_version in 6.3.23 6.3.22 6.3.18 6.3.17 6.3.16 6.3.15 6.3.13 6.3.12 6.3.9 6.2.30 6.2.29 6.2.28 6.2.27 6.2.26 6.2.25 6.2.24 6.2.23 6.2.22 6.2.21 6.2.20 6.2.19 6.2.18 6.2.17 6.2.16 6.2.15 6.2.10 6.1.13 6.1.12 6.1.11 6.1.10 6.0.18 6.0.17 6.0.16 6.0.15 6.0.14 5.2.8 5.2.7 5.1.7 5.1.6; do \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${old_fdb_server_version}/fdbserver.x86_64 -o /opt/foundationdb/old/fdbserver-${old_fdb_server_version}; \
    done && \
    chmod +x /opt/foundationdb/old/* && \
    ln -sf /opt/foundationdb/old/fdbserver-${FDB_VERSION} /opt/foundationdb/old/fdbserver

RUN curl -Ls https://github.com/manticoresoftware/manticoresearch/raw/master/misc/junit/ctest2junit.xsl -o /opt/ctest2junit.xsl

# =========================== END OF LAYER: build ==============================
FROM build as devel

# add vscode server
RUN yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo && \
    yum repolist && \
    yum -y install \
        bash-completion \
        byobu \
        cgdb \
        emacs-nox \
        fish \
        jq \
        ripgrep \
        the_silver_searcher \
        tmux \
        tree \
        vim-enhanced \
        zsh && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR /tmp
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python38/enable && \
    pip3 install \
        lxml \
        psutil \
        python-dateutil \
        subprocess32 && \
    mkdir fdb-joshua && \
    cd fdb-joshua && \
    git clone https://github.com/FoundationDB/fdb-joshua . && \
    pip3 install /tmp/fdb-joshua && \
    cd /tmp && \
    curl -Ls https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl -o kubectl && \
    echo "08ff68159bbcb844455167abb1d0de75bbfe5ae1b051f81ab060a1988027868a  kubectl" > kubectl.txt && \
    sha256sum --quiet -c kubectl.txt && \
    mv kubectl /usr/local/bin/kubectl && \
    chmod 755 /usr/local/bin/kubectl && \
    if [ "$(uname -m)" == "aarch64" ]; then \
        AWSCLI_SHA256="40ccb45036e62c0351b307ed0e68f72defa1365e16c2758eb141cd424295ecb3"; \
    else \
        AWSCLI_SHA256="9a8b3c4e7f72bbcc55e341dce3af42479f2730c225d6d265ee6f9162cfdebdfd"; \
    fi && \
    curl -Ls https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m)-2.2.43.zip -o "awscliv2.zip" && \
    echo "${AWSCLI_SHA256}  awscliv2.zip" > awscliv2.txt && \
    sha256sum --quiet -c awscliv2.txt && \
    unzip -qq awscliv2.zip && \
    ./aws/install && \
    rm -rf /tmp/*

ARG FDB_VERSION="6.3.18"
RUN mkdir -p /usr/lib/foundationdb/plugins && \
    curl -Ls https://fdb-joshua.s3.amazonaws.com/old_tls_library.tgz | \
        tar --strip-components=1 --no-same-owner --directory /usr/lib/foundationdb/plugins -xz && \
    ln -sf /usr/lib/foundationdb/plugins/FDBGnuTLS.so /usr/lib/foundationdb/plugins/fdb-libressl-plugin.so && \
    curl -Ls https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/libfdb_c.x86_64.so -o /usr/lib64/libfdb_c_${FDB_VERSION}.so && \
    ln -sf /usr/lib64/libfdb_c_${FDB_VERSION}.so /usr/lib64/libfdb_c.so

WORKDIR /root
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
    > docker_proxy.sh && \
    chmod 755 docker_proxy.sh && \
    printf '%s\n' \
    'source /opt/rh/devtoolset-8/enable' \
    'source /opt/rh/rh-python38/enable' \
    'source /opt/rh/rh-ruby27/enable' \
    '' \
    'function cmk_ci() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.22.1 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 all packages strip_targets' \
    '}' \
    'function cmk() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.22.1 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -C ${HOME}/build_output -j 84' \
    '}' \
    'function ccmk() {' \
    '    CC=clang CXX=clang++ cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.22.1 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
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
    'bash ${HOME}/docker_proxy.sh' \
    '# export OPENSSL_ROOT_DIR=/opt/boringssl'  \
    '# set -o vi'  \
    '# alias ls="ls -lh --color=auto"' \
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
