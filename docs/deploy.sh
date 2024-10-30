#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V1.0.7-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)
    for pakket in "${pakketten[@]}"; do
        if [[ "$pakket" == NodeJS* ]]; then
            installeer_nodejs "$pakket"
        elif ! dpkg -s "$pakket" >/dev/null 2>&1; then
            echo "Bezig met installeren van ${pakket}..."
            if sudo apt-get install -y "$pakket"; then
                echo "${pakket} succesvol geïnstalleerd."
            else
                echo "Installatie van ${pakket} mislukt."
            fi
        else
            echo "${pakket} is al geïnstalleerd."
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
        *) 
            echo "Onbekende versie: $versie"
            return 1 
        ;;
    esac

    if [ -n "$setup_url" ]; then
        echo "Bezig met installeren van ${versie}..."
        
        if curl -fsSL "$setup_url" -o nodesource_setup.sh &&
           sudo bash nodesource_setup.sh &&
           sudo apt-get install -y nodejs; then
            installed_version=$(node -v)
            echo "${versie} is succesvol geïnstalleerd. Geïnstalleerde versie: $installed_version"
        else
            echo "Installatie van ${versie} is mislukt."
            return 1
        fi
        
        sudo rm nodesource_setup.sh
    fi
}

# Functie om een privé GitHub-repository te klonen
kloon_repository() {
    local repo_url
    local repo_naam
    local gebruikersnaam
    local wachtwoord

    echo "Voer de URL van de GitHub-repository in (of plak deze):"
    read -r repo_url

    repo_naam=$(basename -s .git "$repo_url")

    echo "Voer je GitHub-gebruikersnaam in:"
    read -r gebruikersnaam

    echo "Voer je GitHub-wachtwoord of personal access token in:"
    read -rs wachtwoord
    echo

    if git clone "https://${gebruikersnaam}:${wachtwoord}@${repo_url#https://}" "$repo_naam"; then
        echo "Repository succesvol gekloond naar $repo_naam"
        cd "$repo_naam" || exit
    else
        echo "Klonen van de repository is mislukt."
        exit 1
    fi
}

# Functie om pakketten uit pak.txt te installeren
installeer_pakketten_uit_bestand() {
    if [ -f "pak.txt" ]; then
        echo "Installeren van pakketten uit pak.txt..."
        mapfile -t pakketten < pak.txt
        installeer_pakketten "${pakketten[*]}"
    else
        echo "pak.txt niet gevonden in de repository."
    fi
}

# Hoofdscript
main() {
    toon_splashscreen

    # Controleer of git is geïnstalleerd
    if ! command -v git &> /dev/null; then
        echo "Git is niet geïnstalleerd. Installeren..."
        sudo apt-get update
        sudo apt-get install -y git
    fi

    kloon_repository
    installeer_pakketten_uit_bestand

    echo "Script voltooid."
}

# Voer het hoofdscript uit
main