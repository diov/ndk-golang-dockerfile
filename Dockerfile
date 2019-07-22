FROM circleci/android:api-29

# Setup Ndk
RUN sdkmanager "platforms;android-29"

ARG ndk_version=android-ndk-r20
ARG android_ndk_home=/opt/android/${ndk_version}

# install NDK
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/${ndk_version}.zip https://dl.google.com/android/repository/${ndk_version}-linux-x86_64.zip && \
    sudo unzip -q /tmp/${ndk_version}.zip -d /opt/android && \
    rm /tmp/${ndk_version}.zip && \
    sudo chown -R circleci:circleci ${android_ndk_home}

ENV ANDROID_NDK_HOME ${android_ndk_home}

USER root
# gcc for cgo
RUN sudo apt-get update && apt-get install -y --no-install-recommends \
    g++ \
    gcc \
    libc6-dev \
    make \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.12.7

# Reset user to circleci
USER circleci

RUN set -eux; \
  \
# this "case" statement is generated via "update.sh"
  dpkgArch="$(dpkg --print-architecture)"; \
  case "${dpkgArch##*-}" in \
    amd64) goRelArch='linux-amd64'; goRelSha256='66d83bfb5a9ede000e33c6579a91a29e6b101829ad41fffb5c5bb6c900e109d9' ;; \
    armhf) goRelArch='linux-armv6l'; goRelSha256='48edbe936e9eb74f259bfc4b621fafca4d4ec43156b4ee7bd0d979f257dcd60a' ;; \
    arm64) goRelArch='linux-arm64'; goRelSha256='4da1f7198a8fa0c4067852656b6c10153a4eca5a26aca28ef02ae9f4a7939ba5' ;; \
    i386) goRelArch='linux-386'; goRelSha256='ae2424b7ff557a708be12d3141f25b645966489ca49af1ad10b4fbe4c97d4c41' ;; \
    ppc64el) goRelArch='linux-ppc64le'; goRelSha256='8eda20600d90247efbfa70d116d80056e11192d62592240975b2a8c53caa5bf3' ;; \
    s390x) goRelArch='linux-s390x'; goRelSha256='3374ac3d646555e50be790091b51849319cfcb176904048458c7f4252337fce8' ;; \
    *) goRelArch='src'; goRelSha256='95e8447d6f04b8d6a62de1726defbb20ab203208ee167ed15f83d7978ce43b13'; \
      echo >&2; echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; echo >&2 ;; \
  esac; \
  \
  url="https://golang.org/dl/go${GOLANG_VERSION}.${goRelArch}.tar.gz"; \
  wget -O go.tgz "$url"; \
  echo "${goRelSha256} *go.tgz" | sha256sum -c -; \
  tar -C /usr/local -xzf go.tgz; \
  rm go.tgz; \
  \
  if [ "$goRelArch" = 'src' ]; then \
    echo >&2; \
    echo >&2 'error: UNIMPLEMENTED'; \
    echo >&2 'TODO install golang-any from jessie-backports for GOROOT_BOOTSTRAP (and uninstall after build)'; \
    echo >&2; \
    exit 1; \
  fi; \
  \
  export PATH="/usr/local/go/bin:$PATH"; \
  go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"