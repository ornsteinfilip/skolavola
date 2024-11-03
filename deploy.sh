#!/bin/bash

# Nastavení pracovního adresáře
cd /home/skolavola/skolavola

# Pull nejnovější změny z gitu
echo "Stahuji nejnovější změny z gitu..."
git pull

# Restart služby
echo "Restartuji aplikaci..."
sudo systemctl restart skolavola

echo "Hotovo! Aplikace byla aktualizována a restartována." 