#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V1.0.0-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

# Functie om foutmeldingen weer te geven
toon_fout() {
    whiptail --title "Fout" --msgbox "$1" 8 50
}

# Functie om gebruikersinvoer te krijgen
krijg_invoer() {
    whiptail --title "$1" --inputbox "$2" 8 60 3>&1 1>&2 2>&3
}

# Functie om wachtwoord invoer te krijgen
krijg_wachtwoord() {
    whiptail --title "$1" --passwordbox "$2" 8 60 3>&1 1>&2 2>&3
}

# Functie om voortgang weer te geven
toon_voortgang() {
    echo "$1" | whiptail --title "Voortgang" --gauge "Even geduld aub..." 8 50 0
}

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)
    for pakket in "${pakketten[@]}"; do
        if [[ "$pakket" == NodeJS* ]]; then
            installeer_nodejs "$pakket"
        elif ! dpkg -s "$pakket" >/dev/null 2>&1; then
            whiptail --title "Pakket Installatie" --infobox "Bezig met installeren van ${pakket}..." 10 50
            if sudo apt-get install -y "$pakket" 2>&1 | whiptail --title "Pakket Installatie" --progressbox 20 70; then
                whiptail --title "Pakket Installatie" --msgbox "${pakket} succesvol geïnstalleerd." 8 50
            else
                whiptail --title "Pakket Installatie" --msgbox "Installatie van ${pakket} mislukt." 8 50
            fi
        else
            whiptail --title "Pakket Installatie" --msgbox "${pakket} is al geïnstalleerd." 8 50
        fi
    done
}

# Functie om NodeJS te installeren
installeer_nodejs() {
    local versie=$1
    local setup_url=""

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
        whiptail --title "NodeJS Installatie" --infobox "Bezig met installeren van ${versie}..." 10 50
        
        if curl -fsSL "$setup_url" -o nodesource_setup.sh &&
           sudo bash nodesource_setup.sh 2>&1 | whiptail --title "NodeJS Setup" --progressbox 20 70; then
            
            if sudo apt-get install -y nodejs 2>&1 | whiptail --title "NodeJS Installatie" --progressbox 20 70; then
                installed_version=$(node -v)
                whiptail --title "NodeJS Installatie" --msgbox "${versie} is succesvol geïnstalleerd. Geïnstalleerde versie: $installed_version" 8 60
            else
                whiptail --title "NodeJS Installatie" --msgbox "Installatie van ${versie} is mislukt." 8 50
                return 1
            fi
        else
            whiptail --title "NodeJS Setup" --msgbox "Setup van ${versie} is mislukt." 8 50
            return 1
        fi
        
        sudo rm nodesource_setup.sh
    fi
}

# Functie om project te downloaden met git clone
download_project() {
    local invoer=$1
    local gebruikersnaam=$2
    local wachtwoord=$3
    if [[ "$invoer" =~ ^https?:// ]]; then
        # Verwijder eventuele bestaande gebruikersnaam en wachtwoord uit de URL
        invoer=$(echo "$invoer" | sed -E 's/^(https?:\/\/).*@/\1/')
        # Voeg de nieuwe gebruikersnaam en wachtwoord toe
        repo_url="https://$gebruikersnaam:$(printf '%s' "$wachtwoord" | jq -sRr @uri)@${invoer#https://}"
        if GIT_ASKPASS="echo $wachtwoord" git clone "$repo_url" 2>&1 | whiptail --title "Project Download" --progressbox 20 70; then
            whiptail --title "Project Download" --msgbox "Project succesvol gedownload." 8 50
        else
            toon_fout "Downloaden van het project mislukt."
            return 1
        fi
    elif [ -d "$invoer" ]; then
        cp -r "$invoer"/* .
    else
        toon_fout "Ongeldig bestand of directory locatie: $invoer"
        return 1
    fi
}

# Hoofdscript begint hier en roept de bovenstaande functies op waar nodig
toon_splashscreen

# Installeer whiptail, curl, git en jq altijd automatisch
echo "Vereiste packages whiptail, curl, git en jq worden geïnstalleerd..."
if sudo apt-get update && sudo apt-get install -y whiptail curl git jq; then
    echo "Whiptail, curl, git en jq zijn succesvol geïnstalleerd."
else
    echo "Installatie van whiptail, curl, git of jq mislukt. Script wordt beëindigd."
    exit 1
fi

# Stap 1: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Project Invoer" "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; then
    toon_fout "Project invoer is vereist."
    clear
    exit 1
fi

# Stap 2: Invoer voor gebruikersnaam en wachtwoord voor private repositories
gebruikersnaam=$(krijg_invoer "Gebruikersnaam" "Voer uw gebruikersnaam in voor de private repository:")
if [ -z "$gebruikersnaam" ]; then
    toon_fout "Gebruikersnaam is vereist."
    clear
    exit 1
fi

wachtwoord=$(krijg_wachtwoord "Wachtwoord" "Voer uw wachtwoord in voor de private repository:")
if [ -z "$wachtwoord" ]; then
    toon_fout "Wachtwoord is vereist."
    clear
    exit 1
fi

# Stap 3: Download project
toon_voortgang "50"
if download_project "$project_invoer" "$gebruikersnaam" "$wachtwoord"; then
    whiptail --title "Project Download" --msgbox "Project succesvol gedownload." 8 50
else
    toon_fout "Er is een fout opgetreden tijdens de project download."
    clear
    exit 1
fi

# Stap 4: Lees pakketten van pak.txt
if [ -f "pak.txt" ]; then
    pakketten=$(cat pak.txt)
else
    toon_fout "pak.txt niet gevonden in de gedownloade projectmap."
    clear
    exit 1
fi

# Stap 5: Installeer pakketten
echo "$pakketten" | while IFS= read -r package; do
    toon_voortgang "Bezig met installeren van $package..."
    installeer_pakketten "$package"
done

whiptail --title "Voltooid" --msgbox "De deployment van het project is voltooid." 8 50
clear