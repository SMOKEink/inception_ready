set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

cd /var/www/html

until nc -z mariadb 3306; do
    sleep 1
done

if [ ! -f wp-config.php ]; then
    php84 -d memory_limit=256M /usr/local/bin/wp core download --allow-root
    wp config create --allow-root \
        --dbhost=mariadb \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --extra-php << PHP
define( 'WP_HOME', 'https://$DOMAIN_NAME' );
define( 'WP_SITEURL', 'https://$DOMAIN_NAME' );
PHP
    wp core install --allow-root --skip-email \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"
    wp user create --allow-root "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor
    chown -R nobody:nobody /var/www/html
fi

exec php-fpm84 -F