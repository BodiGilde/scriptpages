#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo
    echo "X+++++++++++++++++++++++X"
    echo "| NodeJS Install Script |"
    echo "| V1.0                  |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

# Functie om foutmeldingen weer te geven
toon_fout() {
    dialog --title "Fout" --msgbox "$1" 8 50  # Toon een foutmelding in een dialoogvenster
}

# Functie om gebruikersinvoer te krijgen
krijg_invoer() {
    dialog --title "$1" --inputbox "$2" 8 60 3>&1 1>&2 2>&3  # Vraag de gebruiker om invoer via een dialoogvenster
}

# Functie om voortgang weer te geven
toon_voortgang() {
    echo "$1" | dialog --title "Voortgang" --gauge "Even geduld aub..." 8 50 0  # Toon een voortgangsbalk
}

# Functie om NodeJS te installeren
installeer_nodejs() {
    local versie=$1
    case $versie in
        NodeJS23)
            curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJS22)
            curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJS21)
            curl -fsSL https://deb.nodesource.com/setup_21.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJS20)
            curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJS18)
            curl -fsSL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJSLTS)
            curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        NodeJSCurrent)
            curl -fsSL https://deb.nodesource.com/setup_current.x -o nodesource_setup.sh
            bash nodesource_setup.sh
            apt-get install -y nodejs
            node -v
            ;;
        *)
            toon_fout "Onbekende versie: $versie"
            ;;
    esac
    sudo rm nodesource_setup.sh  # Verwijder het setup script
}

# Hoofdscript begint hier

# Toon splashscreen
toon_splashscreen

# Installeer dialog altijd automatisch
echo "Vereist package dialog wordt geïnstalleerd..."
sudo apt-get update  # Werk de pakketlijst bij
sudo apt-get install -y dialog  # Installeer het dialog pakket stilletjes
if [ $? -ne 0 ]; then
    echo "Installatie van dialog mislukt. Script wordt beëindigd."
    exit 1
fi

# Stap 1: Invoer voor pakket/afhankelijkheden URL
pakket_url=$(krijg_invoer "Package lijst" "Vul het package/dependencies URL van het dashboard in:")
if [ -z "$pakket_url" ]; then
    toon_fout "Package URL is vereist."
    clear
    exit 1
fi

# Stap 2: Lees pakketten van URL
pakketten=$(curl -s "$pakket_url")
if [ -z "$pakketten" ]; then
    toon_fout "Package lijst kan niet worden gelezen."
    clear
    exit 1
fi

# Stap 3: Installeer pakketten
echo "$pakketten" | while IFS= read -r package; do
    toon_voortgang "Bezig met installeren van $package..."
    installeer_nodejs "$package"
done

# Stap 4: Voltooiing
dialog --title "Voltooid" --msgbox "De installatie van NodeJS versies is voltooid." 8 50  # Toon voltooiingsbericht

clear  # Wis het scherm na voltooiing
