# PHP 5.3.3 on Apache w/ Xdebug
FROM centos:6.8

# Install apache and packages required to compile PHP
RUN yum -y update && \
    yum -y upgrade && \
    yum -y install vim man wget httpd && \
    yum -y groupinstall "Development Tools" && \
    yum -y install epel-release && \
    yum -y install \
        libxml2-devel \
        httpd-devel \
        libXpm-devel \
        gmp-devel \
        libicu-devel \
        t1lib-devel \
        aspell-devel \
        openssl-devel \
        bzip2-devel \
        libcurl-devel \
        libjpeg-devel \
        libvpx-devel \
        libpng-devel \
        freetype-devel \
        readline-devel \
        libtidy-devel \
        libxslt-devel \
        libmcrypt-devel

# Download, extract and build PHP 5.3.3
RUN mkdir build && \
    cd build && \
    wget http://museum.php.net/php5/php-5.3.3.tar.gz && \
    tar -xvf php-5.3.3.tar.gz && \
    rm php-5.3.3.tar.gz && \
    cd php-5.3.3 && \
    ./configure \
        --with-libdir=lib64 \
        --prefix=/usr/local \
        --with-layout=PHP \
        --with-pear \
        --with-apxs2 \
        --enable-calendar \
        --enable-bcmath \
        --with-gmp \
        --enable-exif \
        --with-mcrypt \
        --with-mhash \
        --with-zlib \
        --with-bz2 \
        --enable-zip \
        --enable-ftp \
        --enable-mbstring \
        --with-iconv \
        --enable-intl \
        --with-icu-dir=/usr \
        --with-gettext \
        --with-pspell \
        --enable-sockets \
        --with-openssl \
        --with-curl \
        --with-curlwrappers \
        --with-gd \
        --enable-gd-native-ttf \
        --with-jpeg-dir=/usr \
        --with-png-dir=/usr \
        --with-zlib-dir=/usr \
        --with-xpm-dir=/usr \
        --with-freetype-dir=/usr \
        --with-t1lib=/usr \
        --with-libxml-dir=/usr \
        --with-mysql=mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --enable-soap \
        --with-xmlrpc \
        --with-xsl \
        --with-tidy=/usr \
        --with-readline \
        --enable-pcntl \
        --enable-sysvshm \
        --enable-sysvmsg \
        --enable-shmop && \
    make && \
    make install && \
    cp php.ini-production /usr/local/lib/php.ini && \
    ln -s /usr/local/lib/php.ini /etc/php.ini

# Install last version of Xdebug that supports PHP 5.3
RUN yum -y install php-pear && \
    pecl install xdebug-2.2.7

# Enable Xdebug in php.ini
RUN echo "zend_extension=\"$(find / -name 'xdebug.so' 2> /dev/null)\"" >> /etc/php.ini && \
    echo -e "xdebug.remote_enable=1\nxdebug.remote_autostart=1" >> /etc/php.ini

# Apache configuration
RUN sed -i "$(cat /etc/httpd/conf/httpd.conf | grep -n 'DirectoryIndex index.html' | cut -d: -f1) s/$/ index.php/" /etc/httpd/conf/httpd.conf && \
    cd /etc/httpd && \
    mkdir sites-available sites-enabled && \
    echo -e "<VirtualHost *:80>\nDocumentRoot \"/var/www/html/public\"\n<Directory /var/www/html/public>\nOptions FollowSymLinks Indexes\nAllowOverride All\n</Directory>\n</VirtualHost>" > /etc/httpd/sites-available/000-default.conf && \
    ln -s /etc/httpd/sites-available/000-default.conf /etc/httpd/sites-enabled/000-default.conf && \
    echo "Include sites-enabled/*.conf" >> /etc/httpd/conf/httpd.conf && \
    echo "AddType application/x-httpd-php .php" >> /etc/httpd/conf/httpd.conf

# Add a test page to verify everything went okay
RUN mkdir /var/www/html/public && \
    echo "<?php phpinfo();" > /var/www/html/public/index.php

# Get host IP address and add it as Xdebug remote target
CMD sed -i "/xdebug.remote_host=\"[.0-9]*\"/d" /etc/php.ini && \
    echo "xdebug.remote_host=\"$(/sbin/ip route|awk '/default/ { print $3 }')\"" >> /etc/php.ini && \
    httpd -DFOREGROUND