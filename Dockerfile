FROM php:7.0-apache
MAINTAINER Alan Kent <alan.james.kent@gmail.com>


########### BASE Settings ########### 

ENV MAGENTO_USER magento
ENV MAGENTO_PASSWORD magento
ENV MAGENTO_GROUP magento


########### SSHD ########### 

# Enable sftp
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/run/sshd
EXPOSE 22


########### Apache and PHP Setup ########### 

# (See also work by Mark Shust <mark.shust@mageinferno.com>
# https://github.com/mageinferno/)

RUN apt-get update \
 && apt-get install -y libfreetype6-dev libicu-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libxslt1-dev vim git curl net-tools telnet sudo cron openssl unzip \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
 && docker-php-ext-install gd intl mbstring mcrypt pdo_mysql xsl zip \
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && a2enmod rewrite \
 && echo "memory_limit 2048M" > /usr/local/etc/php/php.ini 

RUN useradd -m -s /bin/bash -p $(openssl passwd -1 ${MAGENTO_PASSWORD}) -G sudo ${MAGENTO_USER}
RUN mkdir /magento2 \
 && chown magento:magento /magento2 \
 && cd /magento2 \
 && sed -i -e 's/www-data/magento/g' /etc/apache2/envvars \
 && sed -i -e 's/www-data/magento/g' /etc/apache2/apache2.conf \
 && sudo -u ${MAGENTO_USER} sh -c "echo 'export PATH=\${PATH}:/magento2/bin' >> /home/magento/.bashrc" \
 && sudo -u ${MAGENTO_USER} sh -c "echo 'PS1=m2$\ ' >> /home/magento/.bashrc" \
 && echo 'if [ $PPID == 0 ]; then exec sudo -u magento bash ; fi' >> /root/.bashrc

# Environment variables from /etc/apache2/apache2.conf
ENV APACHE_RUN_USER magento
ENV APACHE_RUN_GROUP magento
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid


############ MySQL Setup ########### 

# Install MariaDB 10.0 instead of MySQL 5.6 as MySQL does not appear available
# via apt-get according to error message.

ENV MYSQL_ROOT_PASSWORD ""
ENV MYSQL_ALLOW_EMPTY_PASSWORD true
ENV MYSQL_DATABASE magento
ENV MYSQL_USER magento
ENV MYSQL_PASSWORD magento


#RUN curl -L -o /tmp/mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.3.7-1debian8_all.deb \
# && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/mysql-apt-config.deb \
# && DEBIAN_FRONTEND=noninteractive apt-get update \
# && DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server-10.0


########### MariaDB Setup ########### 

# Install MariaDB 10.0 instead of MySQL 5.6 as MySQL does not appear available
# any more via apt-get according to error message.
# The following was adapted from:
# https://github.com/docker-library/mariadb/blob/2a8c48a54d8210241861740ea76b5aedf4da681f/10.0/Dockerfile

ENV MARIADB_MAJOR 10.0
ENV MARIADB_VERSION 10.0.24+maria-1~jessie

# add our user and group first to make sure their IDs get assigned
# consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql \
 && useradd -r -g mysql mysql \
 && mkdir /docker-entrypoint-initdb.d \
 && apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 199369E5404BD5FC7D2FE43BCBCB082A1BB943DB \
 && echo "deb http://ftp.osuosl.org/pub/mariadb/repo/$MARIADB_MAJOR/debian jessie main" > /etc/apt/sources.list.d/mariadb.list \
 && { \
      echo 'Package: *'; \
      echo 'Pin: release o=MariaDB'; \
      echo 'Pin-Priority: 999'; \
    } > /etc/apt/preferences.d/mariadb \
 && { \
      echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password password 'unused'; \
      echo mariadb-server-$MARIADB_MAJOR mysql-server/root_password_again password 'unused'; \
    } | debconf-set-selections \
 && apt-get update \
 && apt-get install -y mariadb-server=$MARIADB_VERSION \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/lib/mysql \
 && mkdir /var/lib/mysql \
 && sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf \
 && echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf \
 && mv /tmp/my.cnf /etc/mysql/my.cnf


############ NodeJS ########### 

# Install NodeJS (after curl is installed above).
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - \
 && apt-get update \
 && apt-get install -y nodejs


############ Install Gulp ########### 

RUN mkdir -p /gulp \
 && cd /gulp \
 && curl -L -o /tmp/gulp.zip https://github.com/SnowdogApps/magento2-frontools/archive/master.zip \
 && unzip /tmp/gulp.zip \
 && mv magento2-frontools-master/* . \
 && rm -rf magento2-frontools-master \
 && rm /tmp/gulp.zip \
 && npm install -g gulp \
 && npm install --save-dev gulp \
 && npm install jshint gulp-less gulp-concat gulp-uglify gulp-rename gulp-livereload gulp-sourcemaps gulp-util notify-send --save-dev \
 && npm install \
 && chown -R magento:magento .
EXPOSE 3000
EXPOSE 3001


############ Install Samba ########### 

# Install Samba, but don't start it up by default.
# Mount on Windows using
#    NET USE M: \\192.168.99.100\magento2 magento /USER:magento
RUN apt-get update \
 && apt-get install -yq samba gettext \
 && mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
ADD smb.conf /etc/samba/smb.conf
ENV SAMBA_START 0
EXPOSE 445
EXPOSE 139
EXPOSE 135


############ Misc ########### 

# Don't ask for passwords when running sudo.
RUN echo "magento ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add local shell scripts.
ADD bin/* /usr/local/bin/
ADD entrypoint.sh /entrypoint.sh
RUN chown magento:magento /usr/local/bin/m2* \
 && chmod +rx /usr/local/bin/m2* \
 && chmod +x /entrypoint.sh

WORKDIR /magento2
ENV SHELL /bin/bash
ENV PATH PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/magento2/bin

ENTRYPOINT ["/entrypoint.sh"]
