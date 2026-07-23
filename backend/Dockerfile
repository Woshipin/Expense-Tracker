FROM php:8.2-apache

# 安装 MySQL 扩展
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev zip unzip git \
    && docker-php-ext-install pdo pdo_mysql

# 开启 Apache rewrite
RUN a2enmod rewrite

# 复制项目代码
COPY . /var/www/html

# 设置入口为 public 目录
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# 赋予存储目录权限
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

# 🌟 核心新增：容器启动时自动先执行 php artisan migrate --force 建表，再启动 Apache
CMD php artisan migrate --force && apache2-foreground