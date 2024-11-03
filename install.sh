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
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name skolavola.sinfin.io;

    ssl_certificate /etc/letsencrypt/live/skolavola.cz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/skolavola.cz/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

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

# Získání SSL certifikátu
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN

# Restart služeb
systemctl daemon-reload
systemctl enable skolavola
systemctl restart skolavola
systemctl restart nginx

echo "Instalace dokončena!" 