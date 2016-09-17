FROM armv7/armhf-ubuntu:16.04
RUN apt update && \
    apt install -y sudo bzip2 nginx mariadb-server php-apcu php-fpm php-mysql php-dompdf php-zip php-xml php-xml-parser php-xml-serializer php-mbstring php-gd php-curl && \
	apt-get clean && \
	apt-get autoclean
ADD nextcloud-10.0.0.tar.bz2 /var/www/html
RUN chown -R www-data.www-data /var/www/html/
RUN mkdir /data && chown -R www-data.www-data /data
ENV databaseHost="127.0.0.1" \
databaseName="nextcloud" \
databaseUser="nextcloud" \
databasePass="nextcloud" \
nextcloudAdminUser="admin" \
nextcloudAdminPass="admin" \
nextcloudDataDir="/data" \
nextcloudTrustedDomain="localhost"

RUN cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.bak && \
	sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini && \
	sed -i -e "s/;env/env/" /etc/php/7.0/fpm/pool.d/www.conf && \
	sed -i -e 's/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/' /etc/php/7.0/fpm/php.ini && \
	sed -i -e 's/^allow_url_fopen/;allow_url_fopen/' /etc/php/7.0/fpm/php.ini && \
        sed -i -e 's/;open_basedir =/open_basedir = \/var\/www\/html:\/data:\/tmp/' /etc/php/7.0/fpm/php.ini
COPY default /etc/nginx/sites-available/default
COPY start.sh /start.sh

RUN service mysql start && \
    echo "Creating Database" && \
    mysql -e "CREATE DATABASE IF NOT EXISTS $databaseName" && \
    echo "Setting MySQL Password" && \
    mysql -e "CREATE USER '$databaseUser'@'%' IDENTIFIED BY '$databasePass';" && \
    mysql -e "GRANT ALL ON $databaseName.* TO '$databaseUser'@'%';" && \
    mysql -e "CREATE USER '$databaseUser'@'localhost' IDENTIFIED BY '$databasePass';" && \
    mysql -e "GRANT ALL ON $databaseName.* TO '$databaseUser'@'localhost';" && \
    echo "Installing Nextcloud" && \
    sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install --database "mysql" --database-host "$databaseHost" --database-name "$databaseName" --database-user "$databaseUser" --database-pass "$databasePass" --admin-user "$nextcloudAdminUser" --admin-pass "$nextcloudAdminPass" --data-dir "$nextcloudDataDir" && \
	echo "Changing trusted domain in config" && \
	cp /var/www/html/nextcloud/config/config.php /var/www/html/nextcloud/config/config.php.org && \
	sed -e "s/0 => 'localhost',/0 => '$nextcloudTrustedDomain',/" /var/www/html/nextcloud/config/config.php > /var/www/html/nextcloud/config/config.php.new && \
	sed -e "s/'installed' => true,/'installed' => true,\n  'memcache.local' => '\\\\OC\\\\Memcache\\\\APCu',/" /var/www/html/nextcloud/config/config.php.new > /var/www/html/nextcloud/config/config.php && \
	chown www-data.www-data /var/www/html/nextcloud/config/config.php && \
	chown www-data.www-data /var/www/html/nextcloud/config/config.php.org

VOLUME /data /var/www/html/nextcloud/config /var/www/html/nextcloud/data
EXPOSE 80
ENTRYPOINT /start.sh
