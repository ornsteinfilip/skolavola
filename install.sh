#!/bin/bash

# Kontrola, zda je skript spuštěn jako root
if [ "$EUID" -ne 0 ]; then 
    echo "Spusťte skript jako root (sudo)"
    exit 1
fi

# Nastavení proměnných
DOMAIN="skolavola.sinfin.io"
USER="skolavola"
APP_DIR="/home/$USER/skolavola"

# Instalace potřebných balíčků
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Vytvoření nginx konfigurace
cat > /etc/nginx/sites-available/skolavola << 'EOL'
server {
    listen 80;
    server_name skolavola.sinfin.io;

    # Přidání location pro ACME challenge
    location /.well-known/acme-challenge/ {
        root /home/skolavola/skolavola/certbot;
    }
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}


EOL

# Vytvoření symbolického odkazu
if [ ! -e /etc/nginx/sites-enabled/skolavola ]; then
    ln -sf /etc/nginx/sites-available/skolavola /etc/nginx/sites-enabled/
fi

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

# Vytvoření adresáře pro certbot a nastavení oprávnění
mkdir -p /home/$USER/skolavola/certbot
chown -R www-data:www-data /home/$USER/skolavola/certbot
chmod -R 755 /home/$USER/skolavola/certbot

# Pro jistotu přidáme uživatele www-data do skupiny skolavola
usermod -a -G $USER www-data

# Nastavíme skupinová oprávnění pro nadřazené adresáře
chmod 755 /home/$USER
chmod 755 /home/$USER/skolavola

# Získání SSL certifikátu
certbot certonly --webroot -w /home/$USER/skolavola/certbot -d $DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN --dry-run

# Restart služeb
systemctl daemon-reload
systemctl enable skolavola
systemctl restart skolavola
systemctl restart nginx

echo "Instalace dokončena!" 