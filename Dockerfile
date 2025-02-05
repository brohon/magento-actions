FROM debian:bullseye

LABEL org.opencontainers.image.source="https://github.com/MAD-I-T/magento-actions"

RUN adduser -u 1000 dave 

RUN echo 'deb  http://deb.debian.org/debian  bullseye contrib non-free' >> /etc/apt/sources.list
RUN echo 'deb-src  http://deb.debian.org/debian  bullseye contrib non-free' >> /etc/apt/sources.list

RUN apt-get -y update \
    && apt-get -y install \
    apt-transport-https \
    ca-certificates \
    wget

RUN apt-get -yq install \
    python3-pip\
    python3-setuptools\
    gcc\
    python-dev

RUN wget -O "/etc/apt/trusted.gpg.d/php.gpg" "https://packages.sury.org/php/apt.gpg" \
    && sh -c 'echo "deb https://packages.sury.org/php/ bullseye main" > /etc/apt/sources.list.d/php.list'

RUN apt-get install -f libgd3 -y

RUN apt-get -y update \
    && apt-get -y install \
    git \
    curl \
    php8.3 \
    php8.3-common \
    php8.3-cli \
    php8.3-curl \
    php8.3-dev \
    php8.3-gd \
    php8.3-intl \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-xsl \
    php8.3-zip \
    php8.3-xdebug \
    php8.3-soap \
    php8.3-bcmath \
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
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=2.7.6
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
ENV NODE_VERSION=20.14.0
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
