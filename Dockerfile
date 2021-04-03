FROM quay.io/bitnami/kubectl:1.20.5@sha256:31471de1b877a03197986e397cc7a839ec318ec17f0f1188918b25bcb664f5b9 AS kubectl-dist
FROM docker.io/alpine/helm:3.5.3@sha256:0ef27fe15433641d99bbe753867f18bec52f8a4316de352172375c880b494e17 AS helm-dist
FROM quay.io/roboll/helmfile:v0.138.7@sha256:c6130c9dd50b97e6fe62fe07b90312f7402f877bab8873852affc3f0f7146ae7 AS helmfile-dist
FROM alpine:3.13.4@sha256:e103c1b4bf019dc290bcc7aca538dc2bf7a9d0fc836e186f5fa34945c5168310 AS base

FROM base AS builder

COPY --from=kubectl-dist /opt/bitnami/kubectl/bin/kubectl /bin/kubectl
RUN kubectl version --short --client

COPY --from=helm-dist /usr/bin/helm /bin/helm
RUN helm version --short

COPY --from=helmfile-dist /usr/local/bin/helmfile /bin/helmfile
RUN helmfile version

FROM base

ARG VERSION
ARG BUILD_DATE
ARG VCS_REF

LABEL architecture="amd64/x86_64" \
      \
      org.opencontainers.image.title="Deploy" \
      org.opencontainers.image.description="Image with a set of tools for deploy applications to Kubernetes" \
      org.opencontainers.image.vendor="GamesBoost42" \
      org.opencontainers.image.url="https://github.com/GamesBoost42/deploy" \
      org.opencontainers.image.source="https://github.com/GamesBoost42/deploy" \
      org.opencontainers.image.documentation="https://github.com/GamesBoost42/deploy/blob/master/README.md" \
      org.opencontainers.image.authors="https://github.com/GamesBoost42" \
      org.opencontainers.image.licenses="MIT" \
      \
      org.opencontainers.image.version=${VERSION} \
      org.opencontainers.image.revision=${VCS_REF} \
      org.opencontainers.image.created=${BUILD_DATE}

COPY --from=builder /bin/kubectl /bin/helm /bin/helmfile /bin/

RUN set -eux \
  ; apk add --no-cache --quiet \
        bash=5.1.0-r0 \
        curl=7.74.0-r1 \
        git=2.30.2-r0 \
        jq=1.6-r1 \
        unzip=6.0-r8 \
  ; rm -rf /var/lib/apk/* /var/cache/apk/* /usr/share/git-core/templates \
  ; echo 'hosts: files dns' > /etc/nsswitch.conf \
  ; curl --version \
  ; git --version \
  ; jq --version \
  ; kubectl version --short --client \
  ; helm version --short \
  ; helmfile --version \
  ; adduser -h /home/ci -g "CI" -s /bin/bash -D -u 1042 -D ci \
  ; rm -f /root/.ash_history /home/ci/.ash_history /home/ci/.bash_history /home/ci/.bash_logout

USER 1042:1042

ENV PS1="\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "

RUN set -eux \
  ; helm plugin install https://github.com/databus23/helm-diff \
  ; helm plugin list \
  ; helm diff version \
  ; rm -rf \
    ~/.local/share/helm/plugins/helm-diff/.git \
    ~/.local/share/helm/plugins/helm-diff/.circleci \
    ~/.local/share/helm/plugins/helm-diff/.github \
    ~/.local/share/helm/plugins/helm-diff/cmd \
    ~/.local/share/helm/plugins/helm-diff/diff \
    ~/.local/share/helm/plugins/helm-diff/manifest \
    ~/.local/share/helm/plugins/helm-diff/scripts \
    ~/.local/share/helm/plugins/helm-diff/testdata \
    /tmp/helm-diff \
  ; rm -f \
    ~/.local/share/helm/plugins/helm-diff/.gitignore \
    ~/.local/share/helm/plugins/helm-diff/go.mod \
    ~/.local/share/helm/plugins/helm-diff/go.sum \
    ~/.local/share/helm/plugins/helm-diff/install-binary.sh \
    ~/.local/share/helm/plugins/helm-diff/main.go \
    ~/.local/share/helm/plugins/helm-diff/Makefile \
    ~/.local/share/helm/plugins/helm-diff/README.md \
    /tmp/helm-diff.tgz \
  ; helm plugin list \
  ; helm diff version \
  ; rm -f ~/.ash_history ~/.bash_history ~/.bash_logout \
  ; rm -rf ~/.cache

CMD ["bash"]
