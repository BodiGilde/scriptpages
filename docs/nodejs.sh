#!/bin/bash

# Controleer of curl is geïnstalleerd, zo niet, installeer het
if ! command -v curl &> /dev/null; then
    echo "curl is niet geïnstalleerd. Installeren van curl..."
    apt-get update
    apt-get install -y curl
fi

# Vraag om de URL van de package lijst
read -p "Voer de URL van de package lijst in: " pakket_url
if [ -z "$pakket_url" ]; then
    echo "Package URL is vereist."
    exit 1
fi

# Lees pakketten van URL
pakketten=$(curl -s "$pakket_url")
if [ -z "$pakketten" ]; then
    echo "Package lijst kan niet worden gelezen."
    exit 1
fi

# Installeer elke versie
echo "$pakketten" | while IFS= read -r package; do
    echo "Installeren van $package..."
    
    if [ "$package" == "NodeJS23" ]; then
        echo "NodeJS23 is de nieuwste versie!"
        curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJS22" ]; then
        echo "NodeJS22 is een stabiele versie."
        curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJS21" ]; then
        echo "NodeJS21 heeft enkele nieuwe features."
        curl -fsSL https://deb.nodesource.com/setup_21.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJS20" ]; then
        echo "NodeJS20 is een oudere versie."
        curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJS18" ]; then
        echo "NodeJS18 is een LTS (Long Term Support) versie."
        curl -fsSL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJSLTS" ]; then
        echo "NodeJSLTS is de huidige LTS versie."
        curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    elif [ "$package" == "NodeJSCurrent" ]; then
        echo "NodeJSCurrent is de huidige versie."
        curl -fsSL https://deb.nodesource.com/setup_current.x -o nodesource_setup.sh
        bash nodesource_setup.sh
        apt-get install -y nodejs
        node -v
    else
        echo "Onbekende versie: $package"
    fi

done

echo "Alle pakketten zijn geïnstalleerd!"
