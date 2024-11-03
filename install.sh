#!/bin/bash

echo "Kontroluji oprávnění..."
# Kontrola, zda je skript spuštěn jako root
if [ "$EUID" -ne 0 ]; then 
    echo "Spusťte skript jako root (sudo)"
    exit 1
fi

echo "Nastavuji proměnné..."
# Nastavení proměnných
DOMAIN="skolavola.sinfin.io"
USER="skolavola"
APP_DIR="/home/$USER/skolavola"

echo "Instaluji potřebné balíčky..."
# Instalace potřebných balíčků
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

echo "Vytvářím nginx konfiguraci..."
# Vytvoření nginx konfigurace
cat > /etc/nginx/sites-available/skolavola << 'EOL'
server {
    listen 80;
    server_name skolavola.sinfin.io;
    
    location /.well-known/acme-challenge/ {
        root /home/skolavola/skolavola/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name skolavola.sinfin.io;

    ssl_certificate /etc/letsencrypt/live/skolavola.sinfin.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/skolavola.sinfin.io/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}


EOL

echo "Vytvářím symbolický odkaz..."
# Vytvoření symbolického odkazu
if [ ! -e /etc/nginx/sites-enabled/skolavola ]; then
    ln -sf /etc/nginx/sites-available/skolavola /etc/nginx/sites-enabled/
fi

echo "Vytvářím systemd service..."
# Vytvoření systemd service
cat > /etc/systemd/system/skolavola.service << 'EOL'
[Unit]
Description=Skolavola Rack Application
After=network.target

[Service]
User=skolavola
WorkingDirectory=/home/skolavola/skolavola
ExecStart=/home/skolavola/.local/share/gem/ruby/3.1.0/bin/bundle exec rackup
Restart=always
Environment=RACK_ENV=production

[Install]
WantedBy=multi-user.target
EOL

echo "Vytvářím adresář pro certbot..."
# Vytvoření adresáře pro certbot a nastavení oprávnění
if [ ! -d "/home/$USER/skolavola/certbot" ]; then
    mkdir -p /home/$USER/skolavola/certbot
    chown -R www-data:www-data /home/$USER/skolavola/certbot
    chmod -R 755 /home/$USER/skolavola/certbot
fi

echo "Nastavuji oprávnění pro www-data..."
# Pro jistotu přidáme uživatele www-data do skupiny skolavola
if ! groups www-data | grep -q "$USER"; then
    usermod -a -G $USER www-data
fi

echo "Nastavuji oprávnění pro adresáře..."
# Nastavíme skupinová oprávnění pro nadřazené adresáře
if [ "$(stat -c %a /home/$USER)" != "755" ]; then
    chmod 755 /home/$USER
fi

if [ "$(stat -c %a /home/$USER/skolavola)" != "755" ]; then
    chmod 755 /home/$USER/skolavola
fi

echo "Získávám SSL certifikát..."
# Získání SSL certifikátu
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ $(find "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -mtime +90) ]; then
    certbot certonly --webroot -w /home/$USER/skolavola/certbot -d $DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN
fi

echo "Restartuji služby..."
# Restart služeb
systemctl daemon-reload
systemctl enable skolavola
systemctl restart skolavola
systemctl restart nginx

echo "Instalace dokončena!" 