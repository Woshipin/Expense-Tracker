FROM php:8.2-apache

# 1. 安装系统所需依赖与 PHP 扩展 (包含 MySQL 支持)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo pdo_mysql gd

# 2. 开启 Apache 的 Rewrite 模块
RUN a2enmod rewrite

# 3. 复制后端代码到容器工作目录
COPY . /var/www/html

# 4. 将 Apache 根目录重定向到 public 文件夹
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/conf-available/*.conf

# 5. 安装 Composer 并拉取生产环境依赖
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# 6. 赋予 Laravel 存储与缓存目录读写权限
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 7. 暴露 80 端口
EXPOSE 80

# 8. 🌟 启动命令：自动建表 -> 自动插入默认 Type 种子 -> 启动 Apache
CMD ["sh", "-c", "php artisan migrate --force && php artisan db:seed --class=TypeSeeder --force && apache2-foreground"]