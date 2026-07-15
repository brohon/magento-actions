FROM debian:bullseye

LABEL org.opencontainers.image.source="https://github.com/MAD-I-T/magento-actions"

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=20.14.0
ARG COMPOSER_VERSION=2.8.9

ENV NODE_VERSION="${NODE_VERSION}"
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="/usr/local/bin:${PATH}"

# Create the action user.
RUN adduser \
    --uid 1000 \
    --disabled-password \
    --gecos "" \
    dave

# Install base packages, configure the Sury PHP repository with a dedicated
# keyring, and install PHP 8.4 plus the required extensions.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        wget \
        gnupg \
        git \
        gcc \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        default-mysql-client \
        unzip \
        zip \
        xz-utils; \
    \
    curl -fsSL https://packages.sury.org/php/apt.gpg \
        -o /usr/share/keyrings/deb.sury.org-php.gpg; \
    \
    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ bullseye main" \
        > /etc/apt/sources.list.d/php.list; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        php8.4 \
        php8.4-bcmath \
        php8.4-cli \
        php8.4-common \
        php8.4-curl \
        php8.4-dev \
        php8.4-gd \
        php8.4-intl \
        php8.4-mbstring \
        php8.4-mysql \
        php8.4-soap \
        php8.4-xdebug \
        php8.4-xml \
        php8.4-xsl \
        php8.4-zip; \
    \
    update-alternatives --set php /usr/bin/php8.4; \
    \
    apt-get clean; \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/doc/* \
        /usr/share/doc-base/*

# Verify PHP installation.
RUN php --version \
    && php -m

# Download, verify, and install Composer 2.8.9.
RUN set -eux; \
    EXPECTED_SIGNATURE="$(curl -fsSL https://composer.github.io/installer.sig)"; \
    php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');"; \
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', '/tmp/composer-setup.php');")"; \
    \
    if [ "${EXPECTED_SIGNATURE}" != "${ACTUAL_SIGNATURE}" ]; then \
        echo "ERROR: Invalid Composer installer signature"; \
        rm -f /tmp/composer-setup.php; \
        exit 1; \
    fi; \
    \
    php /tmp/composer-setup.php \
        --install-dir=/usr/local/bin \
        --filename=composer \
        --version="${COMPOSER_VERSION}"; \
    \
    rm -f /tmp/composer-setup.php; \
    composer --version

# Copy Magento Action files.
COPY LICENSE README.md /
COPY scripts /opt/scripts
COPY config /opt/config
COPY entrypoint.sh /entrypoint.sh

# Ensure the entrypoint and shell scripts are executable.
RUN set -eux; \
    chmod +x /entrypoint.sh; \
    if [ -d /opt/scripts ]; then \
        find /opt/scripts \
            -type f \
            -name "*.sh" \
            -exec chmod +x {} \;; \
    fi

# Install PHP Deployer dependencies using PHP 8.4 and Composer 2.8.9.
RUN set -eux; \
    cd /opt/config/php-deployer; \
    /usr/bin/php8.4 /usr/local/bin/composer install \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        --optimize-autoloader

# Install and verify n98-magerun2.
RUN set -eux; \
    mkdir -p /opt/magerun; \
    cd /opt/magerun; \
    \
    curl -fsSLO https://files.magerun.net/n98-magerun2-latest.phar; \
    curl -fsSL \
        "https://files.magerun.net/sha256.php?file=n98-magerun2-latest.phar" \
        -o n98-magerun2-latest.phar.sha256; \
    \
    sha256sum -c n98-magerun2-latest.phar.sha256; \
    chmod +x n98-magerun2-latest.phar; \
    ln -s /opt/magerun/n98-magerun2-latest.phar \
        /usr/local/bin/n98-magerun2; \
    n98-magerun2 --version

# Download, verify, and install Node.js.
RUN set -eux; \
    cd /tmp; \
    curl -fsSLO --compressed \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"; \
    curl -fsSLO \
        "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    \
    grep " node-v${NODE_VERSION}-linux-x64.tar.xz\$" SHASUMS256.txt \
        | sha256sum -c -; \
    \
    tar -xJf "node-v${NODE_VERSION}-linux-x64.tar.xz" \
        -C /usr/local \
        --strip-components=1; \
    \
    rm -f \
        "node-v${NODE_VERSION}-linux-x64.tar.xz" \
        SHASUMS256.txt; \
    \
    node --version; \
    npm --version

# Install Yarn and Gulp CLI globally.
RUN set -eux; \
    npm install --global yarn gulp-cli; \
    yarn --version; \
    gulp --version; \
    npm cache clean --force

ENTRYPOINT ["/entrypoint.sh"]
