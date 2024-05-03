FROM debian:buster

LABEL org.opencontainers.image.source="https://github.com/MAD-I-T/magento-actions"

RUN adduser -u 1000 dave 

RUN echo 'deb  http://deb.debian.org/debian  buster contrib non-free' >> /etc/apt/sources.list
RUN echo 'deb-src  http://deb.debian.org/debian  buster contrib non-free' >> /etc/apt/sources.list

RUN apt-get -y update \
    && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    wget

RUN apt-get -yq install \
    python-pip\
    gcc\
    python-dev

RUN wget -O "/etc/apt/trusted.gpg.d/php.gpg" "https://packages.sury.org/php/apt.gpg" \
    && sh -c 'echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/php.list'

RUN apt-get install -f libgd3 -y

RUN apt-get -y update \
    && apt-get -y install \
    git \
    curl \
    php7.4 \
    php7.4-common \
    php7.4-cli \
    php7.4-curl \
    php7.4-dev \
    php7.4-gd \
    php7.4-intl \
    php7.4-mysql \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-xsl \
    php7.4-zip \
    php7.4-json \
    php7.4-xdebug \
    php7.4-soap \
    php7.4-bcmath \
    php8.1 \
    php8.1-common \
    php8.1-cli \
    php8.1-curl \
    php8.1-dev \
    php8.1-gd \
    php8.1-intl \
    php8.1-mysql \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-xsl \
    php8.1-zip \
    php8.1-xdebug \
    php8.1-soap \
    php8.1-bcmath \
    php8.2 \
    php8.2-common \
    php8.2-cli \
    php8.2-curl \
    php8.2-dev \
    php8.2-gd \
    php8.2-intl \
    php8.2-mysql \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-xsl \
    php8.2-zip \
    php8.2-xdebug \
    php8.2-soap \
    php8.2-bcmath \
    zip \
    default-mysql-client \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/* \
    /usr/share/doc \
    /usr/share/doc-base

# Download and install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=2.2.2
RUN php -r "unlink('composer-setup.php');"

RUN composer --version

COPY LICENSE README.md /
COPY scripts /opt/scripts
COPY config /opt/config
COPY entrypoint.sh /entrypoint.sh

RUN cd /opt/config/php-deployer/ &&  /usr/bin/php8.2 /usr/local/bin/composer install

RUN  mkdir /opt/magerun/ \
    && cd /opt/magerun/ \
    && curl -sS -O https://files.magerun.net/n98-magerun2-latest.phar \
    && curl -sS -o n98-magerun2-latest.phar.sha256 https://files.magerun.net/sha256.php?file=n98-magerun2-latest.phar \
    && shasum -a 256 -c n98-magerun2-latest.phar.sha256

# Install dependencies for Node.js
RUN apt-get update && apt-get install -y xz-utils

# Download and install Node.js
ENV NODE_VERSION=16.12.0
RUN cd /tmp && \
    curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" && \
    tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.xz"

# Verify installation
RUN node -v && npm -v

# Install Yarn globally using npm
RUN npm install --global yarn

# Verify Yarn installation
RUN yarn --version

# Install Gulp CLI globally using npm or Yarn
RUN npm install --global gulp-cli
# Alternatively, you can use Yarn to install Gulp CLI
# RUN yarn global add gulp-cli

# Verify Gulp CLI installation
RUN gulp --version


ENTRYPOINT "/entrypoint.sh"
