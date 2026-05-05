FROM ruby:3.2-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NOWARNINGS="yes" \
    LANG=en_US.UTF-8 \
    BUNDLE_PATH=/bundle_cache \
    GEM_HOME=/bundle_cache \
    GEM_PATH=/bundle_cache
ARG INSTALL_DEVELOPMENT_DEPENDENCIES=false
ARG TARGETARCH
ARG NODE_24_VERSION=24.14.1

RUN sed -e '/bullseye-updates/ s/^#*/#/' -i /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -qq -y --no-install-recommends ca-certificates curl gnupg2 && \
    mkdir -p /usr/share/keyrings && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -qq -y --no-install-recommends \
      build-essential git-core imagemagick \
      default-libmysqlclient-dev default-mysql-client netcat shared-mime-info \
      libqt5webkit5 libqt5webkit5-dev xvfb \
      libvips42 \
      cmake pkg-config file \
      postgresql-client-15 libpq-dev && \
    case "${TARGETARCH}" in \
      amd64) NODE_TARBALL="node-v${NODE_24_VERSION}-linux-x64.tar.gz" ;; \
      arm64) NODE_TARBALL="node-v${NODE_24_VERSION}-linux-arm64.tar.gz" ;; \
      *) echo "Unsupported Docker target platform for Node.js: ${TARGETARCH}" >&2; exit 1 ;; \
    esac && \
    NODE_BASE_URL="https://nodejs.org/download/release/v${NODE_24_VERSION}" && \
    curl -fsSL "${NODE_BASE_URL}/SHASUMS256.txt" -o SHASUMS256.txt && \
    grep " ${NODE_TARBALL}\$" SHASUMS256.txt >/dev/null && \
    curl -fsSLO "${NODE_BASE_URL}/${NODE_TARBALL}" && \
    grep " ${NODE_TARBALL}\$" SHASUMS256.txt | sha256sum -c - && \
    tar -xzf "${NODE_TARBALL}" -C /usr/local --strip-components=1 --no-same-owner && \
    rm -f SHASUMS256.txt "${NODE_TARBALL}" && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /usr/share/man/* /usr/share/doc/*

RUN corepack enable && \
    corepack prepare yarn@stable --activate && \
    gem update --system 3.5.23 > /dev/null && \
    gem install bundler -v 2.5.23 --silent && \
    echo "alias m='make'\n\
alias ms='make start'\n\
alias mss='make start_no_async'\n\
alias mc='make console'\n\
alias mcs='make console_no_async'\n\
alias r='bundle exec rspec'\n\
alias ra='bundle exec rubocop -a'\n\
alias raa='bundle exec rubocop -A'\n\
alias cred='bin/rails credentials:edit --environment development'\n\
alias crsd='bin/rails credentials:show --environment development'\n\
alias cres='bin/rails credentials:edit --environment staging'\n\
alias crss='bin/rails credentials:show --environment staging'\n\
alias crep='bin/rails credentials:edit --environment production'\n\
alias crsp='bin/rails credentials:show --environment production'\n\
alias cret='bin/rails credentials:edit --environment test'\n\
alias crst='bin/rails credentials:show --environment test'\n\
alias sw='bundle exec rake rswag:specs:swaggerize'\n\
export EDITOR=vi\n\
export PATH=\"/app/bin:/bundle_cache/bin:\$PATH\"" >> ~/.bashrc
