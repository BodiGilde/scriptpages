#Dit is een test bestand om de NodeJS module van Deploy.sh te testen.

#!/bin/bash

# Controleer of het bestand packages.txt bestaat
if [ ! -f packages.txt ]; then
    echo "Het bestand packages.txt bestaat niet!"
    exit 1
fi

# Lees het bestand en installeer elke versie
while IFS= read -r package; do
    echo "Installeren van $package..."
    
    # Voorbeeld van verschillende outputs voor specifieke NodeJS-versies
    if [ "$package" == "NodeJS23" ]; then
        echo "NodeJS23 is de nieuwste versie!"
    elif [ "$package" == "NodeJS22" ]; then
        echo "NodeJS22 is een stabiele versie."
    elif [ "$package" == "NodeJS21" ]; then
        echo "NodeJS21 heeft enkele nieuwe features."
    elif [ "$package" == "NodeJS20" ]; then
        echo "NodeJS20 is een oudere versie."
    elif [ "$package" == "NodeJS18" ]; then
        echo "NodeJS18 is een LTS (Long Term Support) versie."
    elif [ "$package" == "NodeJSLTS" ]; then
        echo "NodeJSLTS is de huidige LTS versie."
    elif [ "$package" == "NodeJSCurrent" ]; then
        echo "NodeJSCurrent is de huidige versie."
    else
        echo "Onbekende versie: $package"
    fi

    # Hier kun je het commando toevoegen om de NodeJS-versie te installeren
    # Bijvoorbeeld: nvm install $package
done < packages.txt

echo "Alle pakketten zijn geïnstalleerd!"
