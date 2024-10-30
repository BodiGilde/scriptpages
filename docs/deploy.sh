#!/bin/bash

# Functie om een splashscreen weer te geven
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V1.4.0-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4
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

    # Stel de setup_url in op basis van de opgegeven versie
    case $versie in
        NodeJS23) setup_url="https://deb.nodesource.com/setup_23.x" ;;
        NodeJS22) setup_url="https://deb.nodesource.com/setup_22.x" ;;
        NodeJS21) setup_url="https://deb.nodesource.com/setup_21.x" ;;
        NodeJS20) setup_url="https://deb.nodesource.com/setup_20.x" ;;
        NodeJS18) setup_url="https://deb.nodesource.com/setup_18.x" ;;
        NodeJSLTS) setup_url="https://deb.nodesource.com/setup_lts.x" ;;
        NodeJSCurrent) setup_url="https://deb.nodesource.com/setup_current.x" ;;
        *) echo "Onbekende versie: $versie" && return 1 ;;
    esac

    if [ -n "$setup_url" ]; then
        echo "Bezig met installeren van ${versie}..."
        
        # Controleer of curl is geïnstalleerd
        if ! dpkg -s curl >/dev/null 2>&1; then
            echo "curl is niet geïnstalleerd. Installeren van curl..."
            if ! sudo apt-get install -y curl; then
                echo "Installatie van curl mislukt."
                return 1
            fi
        fi

        # Download en voer het setup script uit
        if curl -fsSL "$setup_url" -o nodesource_setup.sh; then
            echo "Setup script gedownload."
            if sudo bash nodesource_setup.sh; then
                echo "Setup script uitgevoerd."
                if sudo apt-get install -y nodejs; then
                    installed_version=$(node -v)
                    echo "${versie} is succesvol geïnstalleerd. Geïnstalleerde versie: $installed_version"
                else
                    echo "Installatie van nodejs mislukt."
                    return 1
                fi
            else
                echo "Uitvoeren van setup script mislukt."
                return 1
            fi
        else
            echo "Downloaden van setup script mislukt."
            return 1
        fi
        
        sudo rm nodesource_setup.sh  # Verwijder het setup script
    fi
}

# Start van het hoofdscript
toon_splashscreen

echo "Kies een optie voor GitHub clone:"
echo "1. Clone met Personal Access Token"
echo "2. Clone met gebruikersnaam/wachtwoord"
read -p "Keuze (1/2): " keuze

case $keuze in
    1)
        read -p "Voer de GitHub repository URL in (formaat: https://github.com/gebruiker/repo.git): " repo_url
        read -s -p "Voer je Personal Access Token in: " token
        echo
        
        # Controleer of de URL het juiste formaat heeft
        if [[ $repo_url =~ ^https://github\.com/([^/]+)/([^/]+)\.git$ ]]; then
            username=${BASH_REMATCH[1]}
            repo=${BASH_REMATCH[2]}
            # Construeer de URL met token
            clone_url="https://${token}@github.com/${username}/${repo}.git"
            git clone "$clone_url"
            cd "$repo"
        else
            echo "Ongeldige GitHub URL. Gebruik het formaat: https://github.com/gebruiker/repo.git"
            exit 1
        fi
        ;;
    2)
        read -p "Voer de GitHub repository URL in (formaat: https://github.com/gebruiker/repo.git): " repo_url
        
        # Controleer of de URL het juiste formaat heeft
        if [[ $repo_url =~ ^https://github\.com/([^/]+)/([^/]+)\.git$ ]]; then
            git clone "$repo_url"
            repo_name=${BASH_REMATCH[2]}
            cd "$repo_name"
        else
            echo "Ongeldige GitHub URL. Gebruik het formaat: https://github.com/gebruiker/repo.git"
            exit 1
        fi
        ;;
    *)
        echo "Ongeldige keuze"
        exit 1
        ;;
esac

# Update pakketbeheerder
sudo apt-get update

# Installeer pakketten uit pak.txt als het bestaat
if [ -f "pak.txt" ]; then
    echo "Installeren van pakketten uit pak.txt..."
    pakketten=$(cat pak.txt)
    installeer_pakketten "$pakketten"
else
    echo "pak.txt niet gevonden"
fi

# Verwijder het deploy script
cd ..
sudo rm -f deploy.sh

echo "Installatie voltooid!"
