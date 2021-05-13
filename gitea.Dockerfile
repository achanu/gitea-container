FROM quay.io/centos/centos:stream AS compile

RUN \
  dnf module -y enable \
    go-toolset:rhel8 \
    nodejs:14 \
  && \
  dnf install -y \
    time \
    git-core \
    golang \
    nodejs \
    npm \
    make \
  && \
  git clone --depth 1 https://github.com/go-gitea/gitea && \
  cd gitea/ && \
  git fetch --depth 1 --tags && \
  LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1)) && \
  git checkout ${LATEST_TAG} && \
  TAGS="bindata" time make frontend && \
  TAGS="bindata" time make backend


FROM quay.io/centos/centos:stream AS build

RUN \
  mkdir -p /rootfs && \
  dnf install -y \
  --installroot /rootfs --releasever 8 \
  --setopt install_weak_deps=false --nodocs \
    coreutils-single \
    glibc-minimal-langpack \
    git-core \
  && \
  dnf clean all && \
  rm -rf /rootfs/var/cache/* && \
  echo "giteauser:x:1000:1000::/home:/sbin/nologin" >> /rootfs/etc/passwd && \
  echo "giteagroup:x:1000:" >> /rootfs/etc/group && \
  echo "giteauser:!!:18757:0:99999:7:::" >> /rootfs/etc/shadow


FROM scratch AS micro
LABEL maintainer="Alexandre Chanu alexandre.chanu@gmail.com"

COPY --from=build /rootfs/ /

COPY --from=compile /gitea/gitea /usr/local/bin/gitea

#USER giteauser

CMD ["/usr/local/bin/gitea"]
