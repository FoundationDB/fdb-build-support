FROM centos:7 as build

WORKDIR /tmp
RUN rpm --import https://download.mono-project.com/repo/xamarin.gpg && \
    curl https://download.mono-project.com/repo/centos7-stable.repo | tee /etc/yum.repos.d/mono-centos7-stable.repo && \
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
        devtoolset-8-libtsan-devel \
        devtoolset-8-libubsan-devel \
        devtoolset-8-systemtap-sdt-devel \
        dos2unix \
        dpkg \
        gettext-devel \
        git \
        golang \
        java-11-openjdk-devel \
        libcurl-devel \
        libuuid-devel \
        libxslt \
        lz4 \
        lz4-devel \
        lz4-static \
        mono-devel \
        redhat-lsb-core \
        rpm-build \
        tcl-devel \
        unzip \
        wget && \
    if [ "$(uname -p)" == "aarch64" ]; then \
        yum install -y \
            rh-python38 \
            rh-python38-python-devel \
            rh-ruby27; \
    else \
        yum install -y \
            rh-python36 \
            rh-python36-python-devel \
            rh-ruby26; \
    fi && \
    rm /etc/yum.repos.d/mono-centos7-stable.repo && \
    yum clean all && \
    rm -rf /var/cache/yum

# install docker 19
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.26.0"

ENV DOCKER_SHA256="0f4336378f61ed73ed55a356ac19e46699a995f2aff34323ba5874d131548b9e"
ENV DOCKER_VERSION="19.03.11"

VOLUME /var/lib/docker

RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    # set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && groupadd dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget -nv "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
    && docker-compose version

# build/install git
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/git/git/archive/v2.30.0.tar.gz -o git.tar.gz && \
    echo "8db4edd1a0a74ebf4b78aed3f9e25c8f2a7db3c00b1aaee94d1e9834fae24e61  git.tar.gz" > git-sha.txt && \
    sha256sum -c git-sha.txt && \
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
    curl -Ls https://github.com/ninja-build/ninja/archive/v1.9.0.zip -o ninja.zip && \
    echo "8e2e654a418373f10c22e4cc9bdbe9baeca8527ace8d572e0b421e9d9b85b7ef  ninja.zip" > ninja-sha.txt && \
    sha256sum -c ninja-sha.txt && \
    unzip ninja.zip && \
    cd ninja-1.9.0 && \
    ./configure.py --bootstrap && \
    cp ninja /usr/bin && \
    cd .. && \
    rm -rf /tmp/*

# install cmake
RUN if [ "$(uname -p)" == "aarch64" ]; then \
        curl -Ls https://github.com/Kitware/CMake/releases/download/v3.19.6/cmake-3.19.6-Linux-aarch64.tar.gz -o cmake.tar.gz; \
        echo "69ec045c6993907a4f4a77349d0a0668f1bd3ce8bc5f6fbab6dc7a7e2ffc4f80  cmake.tar.gz" > cmake-sha.txt; \
    else \
        curl -Ls https://github.com/Kitware/CMake/releases/download/v3.13.4/cmake-3.13.4-Linux-x86_64.tar.gz -o cmake.tar.gz; \
        echo "563a39e0a7c7368f81bfa1c3aff8b590a0617cdfe51177ddc808f66cc0866c76  cmake.tar.gz" > cmake-sha.txt; \
    fi && \
    sha256sum -c cmake-sha.txt && \
    mkdir cmake && \
    tar --strip-components 1 --no-same-owner --directory cmake -xf cmake.tar.gz && \
    cp -r cmake/* /usr/local/ && \
    rm -rf /tmp/*

# build/install LLVM
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/llvm-project-11.0.0.tar.xz -o llvm.tar.xz && \
    echo "b7b639fc675fa1c86dd6d0bc32267be9eb34451748d2efd03f674b773000e92b  llvm.tar.xz" > llvm-sha.txt && \
    sha256sum -c llvm-sha.txt && \
    mkdir llvm-project && \
    tar --strip-components 1 --no-same-owner --directory llvm-project -xf llvm.tar.xz && \
    mkdir -p llvm-project/build && \
    cd llvm-project/build && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;libcxx;libcxxabi;libunwind;lld;lldb" \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        ../llvm && \
    cmake --build . && \
    cmake --build . --target install && \
    cd ../.. && \
    rm -rf /tmp/*

# build/install openssl
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://www.openssl.org/source/openssl-1.1.1h.tar.gz -o openssl.tar.gz && \
    echo "5c9ca8774bd7b03e5784f26ae9e9e6d749c9da2438545077e6b3d755a06595d9  openssl.tar.gz" > openssl-sha.txt && \
    sha256sum -c openssl-sha.txt && \
    mkdir openssl && \
    tar --strip-components 1 --no-same-owner --directory openssl -xf openssl.tar.gz && \
    cd openssl && \
    ./config CFLAGS="-fPIC -O3" --prefix=/usr/local && \
    make -j`nproc` && \
    make -j1 install && \
    ln -sv /usr/local/lib64/lib*.so.1.1 /usr/lib64/ && \
    cd .. && \
    rm -rf /tmp/*

# install rocksdb to /opt
RUN curl -Ls https://github.com/facebook/rocksdb/archive/v6.10.1.tar.gz -o rocksdb.tar.gz && \
    echo "d573d2f15cdda883714f7e0bc87b814a8d4a53a82edde558f08f940e905541ee  rocksdb.tar.gz" > rocksdb-sha.txt && \
    sha256sum -c rocksdb-sha.txt && \
    tar --directory /opt -xf rocksdb.tar.gz && \
    rm -rf /tmp/*

# install boost 1.67 to /opt
RUN curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.67.0/source/boost_1_67_0.tar.bz2 -o boost_1_67_0.tar.bz2 && \
    echo "2684c972994ee57fc5632e03bf044746f6eb45d4920c343937a465fd67a5adba  boost_1_67_0.tar.bz2" > boost-sha-67.txt && \
    sha256sum -c boost-sha-67.txt && \
    tar --no-same-owner --directory /opt -xjf boost_1_67_0.tar.bz2 && \
    rm -rf /opt/boost_1_67_0/libs && \
    rm -rf /tmp/*

# install boost 1.72 to /opt
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://boostorg.jfrog.io/artifactory/main/release/1.72.0/source/boost_1_72_0.tar.bz2 -o boost_1_72_0.tar.bz2 && \
    echo "59c9b274bc451cf91a9ba1dd2c7fdcaf5d60b1b3aa83f2c9fa143417cc660722  boost_1_72_0.tar.bz2" > boost-sha-72.txt && \
    sha256sum -c boost-sha-72.txt && \
    tar --no-same-owner --directory /opt -xjf boost_1_72_0.tar.bz2 && \
    cd /opt/boost_1_72_0 &&\
    ./bootstrap.sh --with-libraries=context &&\
    ./b2 link=static cxxflags=-std=c++14 --prefix=/opt/boost_1_72_0 install &&\
    rm -rf /opt/boost_1_72_0/libs && \
    rm -rf /tmp/*

# jemalloc (needed for FDB after 6.3)
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 -o jemalloc-5.2.1.tar.bz2 && \
    echo "34330e5ce276099e2e8950d9335db5a875689a4c6a56751ef3b1d8c537f887f6  jemalloc-5.2.1.tar.bz2" > jemalloc-sha.txt && \
    sha256sum -c jemalloc-sha.txt && \
    mkdir jemalloc && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory jemalloc -xjf jemalloc-5.2.1.tar.bz2 && \
    cd jemalloc && \
    ./configure --enable-static --disable-cxx && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

# Install CCACHE
RUN source /opt/rh/devtoolset-8/enable && \
    curl -Ls https://github.com/ccache/ccache/releases/download/v4.0/ccache-4.0.tar.gz -o ccache.tar.gz && \
    echo "ac97af86679028ebc8555c99318352588ff50f515fc3a7f8ed21a8ad367e3d45  ccache.tar.gz" > ccache-sha256.txt && \
    sha256sum -c ccache-sha256.txt && \
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
    sha256sum -c toml-sha256.txt && \
    mkdir toml && \
    tar --strip-components 1 --no-same-owner --directory toml -xf toml.tar.gz && \
    mkdir build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -Dtoml11_BUILD_TEST=OFF ../toml && \
    cmake --build . --target install && \
    cd .. && \
    rm -rf /tmp/*

# download old fdbserver binaries
ARG FDB_VERSION="6.2.29"
RUN mkdir -p /opt/foundationdb/old && \
    curl -Ls https://www.foundationdb.org/downloads/misc/fdbservers-${FDB_VERSION}.tar.gz | \
        tar --no-same-owner --directory /opt/foundationdb/old -xz && \
    chmod +x /opt/foundationdb/old/* && \
    ln -sf /opt/foundationdb/old/fdbserver-${FDB_VERSION} /opt/foundationdb/old/fdbserver

# build/install distcc
RUN source /opt/rh/devtoolset-8/enable && \
    if [ "$(uname -p)" == "aarch64" ]; then \
        source /opt/rh/rh-python38/enable; \
    else \
        source /opt/rh/rh-python36/enable; \
    fi && \
    curl -Ls https://github.com/distcc/distcc/archive/v3.3.5.tar.gz -o distcc.tar.gz && \
    echo "13a4b3ce49dfc853a3de550f6ccac583413946b3a2fa778ddf503a9edc8059b0  distcc.tar.gz" > distcc-sha256.txt && \
    sha256sum -c distcc-sha256.txt && \
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
    sha256sum -c valgrind-sha.txt && \
    mkdir valgrind && \
    tar --strip-components 1 --no-same-owner --no-same-permissions --directory valgrind -xjf valgrind-3.17.0.tar.bz2 && \
    cd valgrind && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf /tmp/*

RUN curl -Ls https://github.com/manticoresoftware/manticoresearch/raw/master/misc/junit/ctest2junit.xsl -o /opt/ctest2junit.xsl

# =========================== END OF LAYER: build   ============================
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
        vim \
        zsh && \
    yum clean all && \
    rm -rf /var/cache/yum

WORKDIR /tmp
RUN source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python36/enable && \
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
    curl -Ls https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/kubectl -o kubectl && \
    echo "3dbe69e6deb35fbd6fec95b13d20ac1527544867ae56e3dae17e8c4d638b25b9  kubectl" > kubectl.txt && \
    sha256sum -c kubectl.txt && \
    mv kubectl /usr/local/bin/kubectl && \
    chmod 755 /usr/local/bin/kubectl && \
    curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip -o "awscliv2.zip" && \
    echo "7ee475f22c1b35cc9e53affbf96a9ffce91706e154a9441d0d39cbf8366b718e  awscliv2.zip" > awscliv2.txt && \
    sha256sum -c awscliv2.txt && \
    unzip -qq awscliv2.zip && \
    ./aws/install && \
    rm -rf /tmp/*

ARG FDB_VERSION="6.2.29"
RUN mkdir -p /usr/lib/foundationdb/plugins && \
    curl -Ls https://www.foundationdb.org/downloads/misc/joshua_tls_library.tar.gz | \
        tar --strip-components=1 --no-same-owner --directory /usr/lib/foundationdb/plugins -xz && \
    ln -sf /usr/lib/foundationdb/plugins/FDBGnuTLS.so /usr/lib/foundationdb/plugins/fdb-libressl-plugin.so && \
    curl -Ls https://www.foundationdb.org/downloads/${FDB_VERSION}/linux/libfdb_c_${FDB_VERSION}.so -o /usr/lib64/libfdb_c_${FDB_VERSION}.so && \
    ln -sf /usr/lib64/libfdb_c_${FDB_VERSION}.so /usr/lib64/libfdb_c.so

WORKDIR /root
RUN curl -Ls https://update.code.visualstudio.com/latest/server-linux-x64/stable -o /tmp/vscode-server-linux-x64.tar.gz && \
    mkdir -p .vscode-server/bin/latest && \
    tar --strip-components 1 --no-same-owner --directory .vscode-server/bin/latest -xf /tmp/vscode-server-linux-x64.tar.gz && \
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
    'source /opt/rh/rh-python36/enable' \
    'source /opt/rh/rh-ruby26/enable' \
    '' \
    'function cmk_ci() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.10.1 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
    '    ninja -v -C ${HOME}/build_output -j 84 all packages strip_targets' \
    '}' \
    'function cmk() {' \
    '    cmake -S ${HOME}/src/foundationdb -B ${HOME}/build_output -D USE_CCACHE=ON -D USE_WERROR=ON -D RocksDB_ROOT=/opt/rocksdb-6.10.1 -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja && \' \
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
    'USER_BASHRC="$HOME/src/.bashrc.local"' \
    'if test -f "$USER_BASHRC"; then' \
    '   source $USER_BASHRC' \
    'fi' \
    '' \
    'bash ${HOME}/docker_proxy.sh' \
    >> .bashrc

# =========================== END OF LAYER: devel   ============================
FROM build as distcc

RUN useradd distcc && \
    source /opt/rh/devtoolset-8/enable && \
    source /opt/rh/rh-python36/enable && \
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

# =========================== END OF LAYER: distcc  ============================
FROM build as ycsb

ENV YCSB_VERSION=ycsb-foundationdb-binding-0.17.0 \
    PATH=${PATH}:/usr/bin

RUN cd /opt \
    && eval curl "-Ls https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-foundationdb-binding-0.17.0.tar.gz" \
    | tar -xzvf -

RUN rm -Rf /opt/${YCSB_VERSION}/lib/fdb-java-5.2.5.jar

# COPY The Appropriate fdb-java-.jar Aaron from packages
# COPY binary RPM for foundationd-db
# Install Binary

WORKDIR "/opt/${YCSB_VERSION}"

ENTRYPOINT ["bin/ycsb.sh"]