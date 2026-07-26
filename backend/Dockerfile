FROM php:8.2-apache

# 1. 安装系统所需依赖与 PHP 扩展 (包含 MySQL 与 GD 图形库支持)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql gd

# 2. 开启 Apache 的 Rewrite 模块 (Laravel 路由必需)
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

# 6. 预先创建图片存储目录并赋予完整的读写权限 (防止头像上传报 500 错)
RUN mkdir -p /var/www/html/public/images \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public/images \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public/images

# 7. 暴露 80 端口
EXPOSE 80

# 8. 🌟 自动化启动命令：自动建表 -> 自动导入 Type 数据 -> 自动导入 3 个写死 User 账号 -> 启动 Apache
CMD ["sh", "-c", "php artisan migrate --force && php artisan db:seed --class=TypeSeeder --force && php artisan db:seed --class=UserSeeder --force && apache2-foreground"]