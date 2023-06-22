# Base image
FROM php:7.4-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype6-dev \
    unzip \
    git \
    vim \
    wget

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
    intl \
    gd \
    bcmath \
    opcache \
    pdo_mysql \
    soap \
    zip

# Enable Apache modules
RUN a2enmod rewrite headers

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the document root
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Update Apache configuration
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Clone Magento repository
WORKDIR ${APACHE_DOCUMENT_ROOT}
RUN git clone --branch 2.4 https://github.com/magento/magento2.git .

# Install Magento dependencies via Composer
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data ${APACHE_DOCUMENT_ROOT}
RUN chmod -R 755 ${APACHE_DOCUMENT_ROOT}

# Expose ports
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
