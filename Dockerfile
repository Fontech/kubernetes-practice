FROM php:8.1-apache

ENV APP_ROOT /app
ENV APACHE_DOCUMENT_ROOT $APP_ROOT/public

# 安裝使用 Composer 會用到的套件
# 要寫在同一個 RUN 裡才能讓 Image 有效瘦身
RUN apt-get update && \
    apt-get install -y git zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 修改 Apache Document Root
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 啟用 Rewrite 模組
# 很重要，否則除了首頁以外的頁面都會是 404
RUN ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled

WORKDIR $APP_ROOT

COPY ./app ./app
COPY ./bootstrap ./bootstrap
COPY ./config ./config
COPY ./database ./database
COPY ./lang ./lang
COPY ./public ./public
COPY ./resources ./resources
COPY ./routes ./routes
COPY ./artisan ./artisan
COPY ./composer.json .
COPY ./composer.lock .

# 這些路徑在 .dockerignore 裡被忽略了，所以要補回來
RUN mkdir -p bootstrap/cache
RUN mkdir -p storage/app
RUN mkdir -p storage/app/public
RUN mkdir -p storage/framework
RUN mkdir -p storage/framework/cache
RUN mkdir -p storage/framework/cache/data
RUN mkdir -p storage/framework/sessions
RUN mkdir -p storage/framework/testing
RUN mkdir -p storage/framework/views
RUN mkdir -p storage/logs

# 加上 --no-cache 可以讓 Image 瘦身
RUN composer install \
    --optimize-autoloader \
    --prefer-dist \
    --no-ansi \
    --no-interaction \
    --no-progress \
    --no-scripts \
    --no-cache

# 記得調整 Laravel 會寫入到的資料夾權限
RUN chown -R www-data bootstrap/cache storage

COPY docker-php-entrypoint /usr/local/bin/
