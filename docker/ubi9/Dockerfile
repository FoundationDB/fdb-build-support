FROM registry.access.redhat.com/ubi9 AS build

WORKDIR /tmp

# install docker 20
ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_CHANNEL="stable" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_BUILDX_VERSION="v0.10.5"

ENV DOCKER_VERSION="20.10.21"

VOLUME /var/lib/docker

RUN set -ex \
    && if [ "$(uname -m)" == "aarch64" ]; then \
        DOCKER_SHA256="b4ceb6151d4dd1bfc7557f5fe0317e29cfcac91f798c34fae7dee891a811f8ee"; \
        DOCKER_COMPOSE_VERSION="v2.16.0"; \
        DOCKER_BUILDX_URL="https://github.com/docker/buildx/releases/download/${DOCKER_BUILDX_VERSION}/buildx-${DOCKER_BUILDX_VERSION}.linux-$(uname -m)" ;\
    else \
        DOCKER_SHA256="2582bed8772b283bda9d4565c0af76ee653c93d93dc6b8d0aad795d731a1bb81"; \
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
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose /usr/local/lib/docker/cli-plugins/docker-buildx

# This is required from installing kustomize and can be removed once we install the appropriate compiler versions.
RUN dnf -y install \
        gcc-c++ \
        gcc \
        unzip && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# install golang 1.20
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        GOLANG_ARCH="arm64"; \
        GOLANG_SHA256="4e15ab37556e979181a1a1cc60f6d796932223a0f5351d7c83768b356f84429b"; \
    else \
        GOLANG_ARCH="amd64"; \
        GOLANG_SHA256="b945ae2bb5db01a0fb4786afde64e6fbab50b67f6fa0eb6cfa4924f16a7ff1eb"; \
    fi && \
    curl -Ls https://golang.org/dl/go1.20.6.linux-${GOLANG_ARCH}.tar.gz -o golang.tar.gz && \
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
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.53.3 && \
    go install github.com/goreleaser/goreleaser@v1.9.2 && \
    go install sigs.k8s.io/kind@v0.17.0 && \
    rm -rf /tmp/*

# download old fdb binaries and client lib if not on aarch64
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        for old_fdb_version in 7.1.23 7.1.19 7.0.0 6.3.23 6.3.22 6.3.18 6.3.17 6.3.16 6.3.15 6.3.13 6.3.12 6.3.9 6.2.30 6.2.29 6.2.28 6.2.27 6.2.26 6.2.25 6.2.24 6.2.23 6.2.22 6.2.21 6.2.20 6.2.19 6.2.18 6.2.17 6.2.16 6.2.15 6.2.10 6.1.13 6.1.12 6.1.11 6.1.10 6.0.18 6.0.17 6.0.16 6.0.15 6.0.14 5.2.8 5.2.7 5.1.7 5.1.6; do \
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

# =========================== END OF LAYER: build ==============================
FROM build AS devel

WORKDIR /tmp

# - Download kubectl from AWS
#   https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
RUN if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/arm64/kubectl -o kubectl && \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/arm64/kubectl.sha256 -o kubectl.txt; \
    else \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl -o kubectl && \
        curl -Ls https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl.sha256 -o kubectl.txt; \
    fi && \
    sha256sum --quiet -c kubectl.txt && \
    chmod 755 kubectl && \
    mv kubectl /usr/local/bin/kubectl && \
    if [ "$(uname -m)" == "aarch64" ]; then \
        curl -Ls https://github.com/derailed/k9s/releases/download/v0.26.5/k9s_Linux_arm64.tar.gz -o k9s.tar.gz && \
        echo "62bc8fe98ad035a64bbeede91bdd57de357af3059bd80975a9d22b6b072d97f8  k9s.tar.gz" > k9s-sha.txt; \
    else \
        curl -Ls https://github.com/derailed/k9s/releases/download/v0.26.5/k9s_Linux_x86_64.tar.gz -o k9s.tar.gz && \
        echo "8ae556d05b4744f7b79cc71549e4096daa9c6b913be88ee43be42ef800137bc3  k9s.tar.gz" > k9s-sha.txt; \
    fi && \
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

ARG FDB_VERSION="6.3.18"
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        mkdir -p /usr/lib/foundationdb/plugins && \
        curl -Ls https://fdb-joshua.s3.amazonaws.com/old_tls_library.tgz | \
            tar --strip-components=1 --no-same-owner --directory /usr/lib/foundationdb/plugins -xz && \
        ln -sf /usr/lib/foundationdb/plugins/FDBGnuTLS.so /usr/lib/foundationdb/plugins/fdb-libressl-plugin.so && \
        curl -Ls https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/libfdb_c.x86_64.so -o /usr/lib64/libfdb_c_${FDB_VERSION}.so && \
        ln -sf /usr/lib64/libfdb_c_${FDB_VERSION}.so /usr/lib64/libfdb_c.so; \
    fi

# Install header files for compling the operator
RUN if [ ! "$(uname -m)" == "aarch64" ]; then \
        rpm -ivh https://github.com/apple/foundationdb/releases/download/${FDB_VERSION}/foundationdb-clients-${FDB_VERSION}-1.el7.x86_64.rpm --excludepath=/etc/foundationdb --excludepath=/usr/bin --excludepath=/usr/lib --excludepath=/usr/lib64; \
    fi

# Installing helm https://helm.sh/docs/intro/install for e2e testing with the operator.
ARG HELM_VERSION="v3.12.0"
RUN pushd /tmp && \
    # Binaries and checksum are fetched from here: https://github.com/helm/helm/releases/tag/v3.12.0
    if [ "$(uname -m)" == "aarch64" ]; then \
        curl -sLo helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-arm64.tar.gz" && echo "658839fed8f9be2169f5df68e55cb2f0aa731a50df454caf183186766800bbd0 helm.tar.gz" | sha256sum --quiet -c -; \
    else \
        curl -sLo helm.tar.gz "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" && echo "da36e117d6dbc57c8ec5bab2283222fbd108db86c83389eebe045ad1ef3e2c3b helm.tar.gz" | sha256sum --quiet -c -; \
    fi && \
    tar -zxvf /tmp/helm.tar.gz && \
    mv linux-*/helm /usr/local/bin/helm && \
    helm version --short && \
    popd && \
    rm -rf /tmp/*

WORKDIR /root

# =========================== END OF LAYER: devel ==============================
FROM build AS distcc

ARG DEVTOOLSET_VERSION=11

RUN useradd distcc && \
    source /opt/rh/devtoolset-${DEVTOOLSET_VERSION}/enable && \
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
FROM devel AS codebuild

COPY dockerd-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["dockerd-entrypoint.sh"]

# =========================== END OF LAYER: codebuild ==========================
