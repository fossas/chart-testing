FROM alpine:3.17

RUN apk --no-cache add \
    bash \
    curl>7.77.0-r0 \
    git \
    libc6-compat \
    openssh-client \
    py3-pip \
    py3-wheel \
    python3 && \
    pip install --upgrade pip==21.0.1

# Install a YAML Linter
ARG yamllint_version=1.29.0
LABEL yamllint_version=$yamllint_version
RUN pip install "yamllint==$yamllint_version"

# Install Yamale YAML schema validator
ARG yamale_version=4.0.4
LABEL yamale_version=$yamale_version
RUN pip install "yamale==$yamale_version"

ARG TARGETPLATFORM
# Install kubectl
ARG kubectl_version=v1.26.2
LABEL kubectl_version=$kubectl_version
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$kubectl_version/bin/$TARGETPLATFORM/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install Helm
ARG helm_version=v3.11.2-fossa.1
LABEL helm_version=$helm_version
RUN targetArch=$(echo $TARGETPLATFORM | cut -f2 -d '/') \
    && if [ ${targetArch} = "amd64" ]; then \
    HELM_ARCH="linux-amd64"; \
    elif [ ${targetArch} = "arm64" ]; then \
    HELM_ARCH="linux-arm64"; \
    fi \
    && curl -LO "https://github.com/fossas/helm-cli/releases/download/$helm_version/helm--$HELM_ARCH.tar.gz" \
    && mkdir -p "/usr/local/helm-$helm_version" \
    && tar -xzf "helm--$HELM_ARCH.tar.gz" -C "/usr/local/helm-$helm_version" \
    && ln -s "/usr/local/helm-$helm_version/$HELM_ARCH/helm" /usr/local/bin/helm \
    && rm -f "helm--$HELM_ARCH.tar.gz"

COPY ./etc/chart_schema.yaml /etc/ct/chart_schema.yaml
COPY ./etc/lintconf.yaml /etc/ct/lintconf.yaml
COPY ct /usr/local/bin/ct
RUN git config --global --add safe.directory /workdir
# Ensure that the binary is available on path and is executable
RUN ct --help
