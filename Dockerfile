FROM centos:7
MAINTAINER Ron Williams <hello@ronwilliams.io>
ENV PATH /usr/local/src/vendor/bin/:/usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Set TERM env to avoid mysql client error message "TERM environment variable not set" when running from inside the container
ENV TERM xterm

# Fix command line compile issue with bundler.
ENV LC_ALL en_US.utf8

# Install and enable repositories
RUN yum -y update && \
    yum -y install epel-release && \
    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \ 
    rpm -Uvh https://centos7.iuscommunity.org/ius-release.rpm && \
    yum -y update


RUN yum -y groupinstall "Development Tools" && \
    yum -y install \
    curl \
    git \
    mariadb \
    msmtp \
    net-tools \
    python34 \
    tmux \
    vim \
    wget

# Install PHP and PHP modules
RUN yum -y install \
    php56u \
    php56u-curl \
    php56u-gd \
    php56u-imap \
    php56u-mbstring \
    php56u-mcrypt \
    php56u-mysql \
    php56u-odbc \
    php56u-pear \
    php56u-pecl-imagick \
    php56u-pecl-zendopcache

# Avoid duplicate loading of these .so (shared objects) when php is run
# This is a workaround, the ideal fix would be to prevent the creation in the first place
RUN rm /etc/php.d/20-curl.ini \
    /etc/php.d/20-dom.ini \
    /etc/php.d/20-fileinfo.ini \
    /etc/php.d/20-gd.ini \
    /etc/php.d/40-imagick.ini \
    /etc/php.d/40-json.ini \
    /etc/php.d/20-mbstring.ini \
    /etc/php.d/20-mcrypt.ini \
    /etc/php.d/30-mysql.ini \
    /etc/php.d/30-mysqli.ini \
    /etc/php.d/20-odbc.ini \
    /etc/php.d/20-pdo.ini \
    /etc/php.d/30-pdo_mysql.ini \
    /etc/php.d/30-pdo_odbc.ini \
    /etc/php.d/30-pdo_sqlite.ini \
    /etc/php.d/20-phar.ini \
    /etc/php.d/20-posix.ini \
    /etc/php.d/20-sqlite3.ini \
    /etc/php.d/20-sysvmsg.ini \
    /etc/php.d/20-sysvsem.ini \
    /etc/php.d/20-sysvshm.ini \
    /etc/php.d/20-wddx.ini \
    /etc/php.d/20-xmlwriter.ini \
    /etc/php.d/20-zip.ini

# Install misc tools
RUN yum -y install \
    python-setuptools

# Perform yum cleanup
RUN yum -y upgrade && \
    yum clean all

# Install Composer and Drush
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer \
    --version=1.0.0-alpha10 && \
    composer \
    --working-dir=/usr/local/src/ \
    global \
    require \
    drush/drush:7.* && \
    ln -s /usr/local/src/vendor/bin/drush /usr/bin/drush

# Disable services management by systemd.
RUN systemctl disable httpd.service && \
    systemctl disable rsyslog.service

# Apache config, and PHP config, test apache config
# See https://github.com/docker/docker/issues/7511 /tmp usage
COPY public/index.php /var/www/public/index.php
COPY centos-7 /tmp/centos-7/
RUN rsync -a /tmp/centos-7/etc/httpd /etc/ && \
    apachectl configtest
RUN rsync -a /tmp/centos-7/etc/php* /etc/

EXPOSE 80 443

# Simple startup script to avoid some issues observed with container restart 
ADD conf/run-httpd.sh /run-httpd.sh
RUN chmod -v +x /run-httpd.sh

ADD conf/mail.ini /etc/php.d/mail.ini
RUN chmod 644 /etc/php.d/mail.ini

CMD ["/run-httpd.sh"]
