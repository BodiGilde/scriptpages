# Script om eerst packages van een online lijst te installeren en dan een project zip te downloaden en unzippen op uitvoerende locatie
# Kan nu alleen standaard Debian repro packages installeren en NodeJS
# Voor bruikbare nodejs versies zie NodeJS Variants bestand

#!/bin/bash
# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V0.9.7-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

#Hieronder staan de initialiseer functies die dialog en gebruikersinvoer starten

# Functie om foutmeldingen weer te geven
toon_fout() {
    dialog --title "Fout" --msgbox "$1" 8 50
}

# Functie om gebruikersinvoer te krijgen
krijg_invoer() {
    dialog --title "$1" --inputbox "$2" 8 60 3>&1 1>&2 2>&3
}

# Functie om voortgang weer te geven
toon_voortgang() {
    echo "$1" | dialog --title "Voortgang" --gauge "Even geduld aub..." 8 50 0
}

# Hieronder zijn de package installeer functies

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)
    for pakket in "${pakketten[@]}"; do
        if [[ "$pakket" == NodeJS* ]]; then
            installeer_nodejs "$pakket"
        elif ! dpkg -s "$pakket" >/dev/null 2>&1; then
            dialog --title "Pakket Installatie" --infobox "Bezig met installeren van ${pakket}..." 10 50
            if sudo apt-get install -y "$pakket" 2>&1 | dialog --title "Pakket Installatie" --progressbox 20 70; then
                dialog --title "Pakket Installatie" --msgbox "${pakket} succesvol geïnstalleerd." 8 50
            else
                dialog --title "Pakket Installatie" --msgbox "Installatie van ${pakket} mislukt." 8 50
            fi
        else
            dialog --title "Pakket Installatie" --msgbox "${pakket} is al geïnstalleerd." 8 50
        fi
    done
}

# Functie om NodeJS te installeren
installeer_nodejs() {
    local versie=$1
    local setup_url=""

    # Stel de setup_url in op basis van de opgegeven versie
    case $versie in
        NodeJS23) setup_url="https://deb.nodesource.com/setup_23.x" ;;
        NodeJS22) setup_url="https://deb.nodesource.com/setup_22.x" ;;
        NodeJS21) setup_url="https://deb.nodesource.com/setup_21.x" ;;
        NodeJS20) setup_url="https://deb.nodesource.com/setup_20.x" ;;
        NodeJS18) setup_url="https://deb.nodesource.com/setup_18.x" ;;
        NodeJSLTS) setup_url="https://deb.nodesource.com/setup_lts.x" ;;
        NodeJSCurrent) setup_url="https://deb.nodesource.com/setup_current.x" ;;
        *) toon_fout "Onbekende versie: $versie" && return 1 ;;
    esac

    if [ -n "$setup_url" ]; then
        dialog --title "NodeJS Installatie" --infobox "Bezig met installeren van ${versie}..." 10 50
        
        # Download en voer het setup script uit
        if curl -fsSL "$setup_url" -o nodesource_setup.sh &&
           sudo bash nodesource_setup.sh 2>&1 | dialog --title "NodeJS Setup" --progressbox 20 70; then
            
            # Installeer NodeJS
            if sudo apt-get install -y nodejs 2>&1 | dialog --title "NodeJS Installatie" --progressbox 20 70; then
                installed_version=$(node -v)
                dialog --title "NodeJS Installatie" --msgbox "${versie} is succesvol geïnstalleerd. Geïnstalleerde versie: $installed_version" 8 60
            else
                dialog --title "NodeJS Installatie" --msgbox "Installatie van ${versie} is mislukt." 8 50
                return 1
            fi
        else
            dialog --title "NodeJS Setup" --msgbox "Setup van ${versie} is mislukt." 8 50
            return 1
        fi
        
        sudo rm nodesource_setup.sh  # Verwijder het setup script
    fi
}

# Functie om vereiste pakketten te controleren en te installeren
controleer_en_installeer_pakketten() {
    local vereiste_pakketten=""
    case ${1,,} in
        *.gz|*.tgz) vereiste_pakketten="tar" ;;
        *.rar) vereiste_pakketten="unrar" ;;
        *.7z) vereiste_pakketten="p7zip-full" ;;
    esac
    if [ -n "$vereiste_pakketten" ]; then
        if dialog --title "Pakket Installatie" --yesno "De volgende packages zijn vereist voor het unzippen: $vereiste_pakketten. Wilt u deze installeren?" 8 60; then
            installeer_pakketten "$vereiste_pakketten"
        else
            toon_fout "Vereiste packages zijn niet geïnstalleerd. Kan niet doorgaan met unzippen."
            exit 1
        fi
    fi
}

# Hieronder zijn de project folder download en unzip functies

# Functie om project te downloaden en functie extraheer_archief op te roepen
download_en_extraheer_project() {
    local invoer=$1
    if [[ "$invoer" =~ ^https?:// ]]; then
        local project_bestandsnaam=$(basename "$invoer")
        if curl "$invoer" -O "$project_bestandsnaam"; then
            extraheer_archief "$project_bestandsnaam"
            sudo rm "$project_bestandsnaam"
        else
            toon_fout "Downloaden van het project mislukt."
            return 1
        fi
    elif [ -f "$invoer" ]; then
        extraheer_archief "$invoer"
    elif [ -d "$invoer" ]; then
        cp -r "$invoer"/* .
    else
        toon_fout "Ongeldig bestand of directory locatie: $invoer"
        return 1
    fi
}

# Functie om archieven te extraheren met sudo
extraheer_archief() {
    local bestand=$1
    controleer_en_installeer_pakketten "$bestand"
    case ${bestand,,} in
        *.tar.gz|*.tgz) sudo tar -xzvf "$bestand" ;;
        *.tar) sudo tar -xvf "$bestand" ;;
        *.gz) sudo gunzip -k "$bestand" ;;
        *.rar) sudo unrar x "$bestand" ;;
        *.7z) sudo 7z x "$bestand" ;;
        *) toon_fout "Niet ondersteund bestandsformaat: ${bestand}" && return 1 ;;
    esac
    return $?
}

# Hoofdscript begint hier en roept de bovenstaande functies op waar nodig
toon_splashscreen

# Installeer dialog en curl altijd automatisch
echo "Vereiste packages dialog en curl worden geïnstalleerd..."
if sudo apt-get update && sudo apt-get install -y dialog curl; then
    echo "Dialog en curl zijn succesvol geïnstalleerd."
else
    echo "Installatie van dialog of curl mislukt. Script wordt beëindigd."
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
    installeer_pakketten "$package"
done

# Stap 4: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Project Invoer" "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; then
    toon_fout "Project invoer is vereist."
    clear
    exit 1
fi

# Stap 5: Download en extraheer project
toon_voortgang "50"
if download_en_extraheer_project "$project_invoer"; then
    dialog --title "Voltooid" --msgbox "De deployment van het project is voltooid." 8 50
else
    toon_fout "Er is een fout opgetreden tijdens de project deployment."
fi

clear
