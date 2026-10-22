# ==============================================================================
# PHP 7.2.34 (CVE-2026-109618 & CVE-2026-109619 Fixed) Base Image
# ==============================================================================
FROM alpine:3.12

LABEL maintainer="zhqagp <zhqagp@qq.com>" \
      description="PHP 7.2.34 FPM image patched against CVE-2026-109618 and CVE-2026-109619 (PHP2Shell)"

ENV TIMEZONE=Asia/Shanghai \
    PHP_INI_DIR=/etc/php7

COPY . /tmp/php-src

RUN set -eux \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache \
        ca-certificates \
        curl \
        tar \
        xz \
        tzdata \
        libressl \
        libxml2 \
        libzip \
        bzip2 \
        gmp \
        oniguruma \
        sqlite-libs \
    # Build dependencies
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        bison \
        re2c \
        pkgconf \
        build-base \
        libxml2-dev \
        openssl-dev \
        libzip-dev \
        bzip2-dev \
        gmp-dev \
        oniguruma-dev \
        sqlite-dev \
        curl-dev \
        zlib-dev \
    # Compile PHP
    && cd /tmp/php-src \
    && ./buildconf --force \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=${PHP_INI_DIR} \
        --with-config-file-path=${PHP_INI_DIR} \
        --with-config-file-scan-dir=${PHP_INI_DIR}/conf.d \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
        --enable-mbstring \
        --enable-opcache \
        --enable-sockets \
        --enable-pcntl \
        --enable-soap \
        --enable-bcmath \
        --enable-calendar \
        --enable-exif \
        --enable-shmop \
        --enable-sysvmsg \
        --enable-sysvsem \
        --enable-sysvshm \
        --enable-mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --enable-ftp \
        --enable-phar \
        --enable-posix \
        --enable-tokenizer \
        --enable-xml \
        --enable-xmlreader \
        --enable-xmlwriter \
        --enable-simplexml \
        --enable-dom \
        --enable-fileinfo \
        --enable-ctype \
        --enable-session \
        --with-openssl \
        --with-curl \
        --with-zlib \
        --with-bz2 \
        --with-gmp \
        --with-zip \
    && make -j$(nproc) \
    && make install \
    && mkdir -p ${PHP_INI_DIR}/conf.d \
    && mkdir -p ${PHP_INI_DIR}/php-fpm.d \
    && cp php.ini-production ${PHP_INI_DIR}/php.ini \
    && cp ${PHP_INI_DIR}/php-fpm.conf.default ${PHP_INI_DIR}/php-fpm.conf \
    && cp ${PHP_INI_DIR}/php-fpm.d/www.conf.default ${PHP_INI_DIR}/php-fpm.d/www.conf \
    # Create www-data user
    && addgroup -g 82 -S www-data || true \
    && adduser -u 82 -D -S -G www-data www-data || true \
    # Security hardening configuration
    && { \
        echo "date.timezone=${TIMEZONE}"; \
        echo "session.upload_progress.enabled=0"; \
        echo "expose_php=Off"; \
        echo "display_errors=Off"; \
    } | tee ${PHP_INI_DIR}/conf.d/99-security.ini \
    # Clean up
    && rm -rf /tmp/php-src \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man

WORKDIR /var/www/html
EXPOSE 9000

CMD ["php-fpm", "-F"]
