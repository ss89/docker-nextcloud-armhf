#!/bin/bash
service php7.0-fpm start && service mysql start && service nginx start
echo > /var/log/php7.0-fpm.log
echo > /var/log/nginx/access.log
echo > /var/log/nginx/error.log
echo > /var/log/mysql/error.log
echo > /var/log/php_errors.log
echo > /var/www/html/nextcloud/data/nextcloud.log
tail -f /var/log/php7.0-fpm.log /var/log/nginx/access.log /var/log/nginx/error.log /var/log/mysql/error.log  /var/log/php_errors.log /var/www/html/nextcloud/data/nextcloud.log
