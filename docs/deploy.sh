#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V1.0.6-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

# Functie om foutmeldingen weer te geven
toon_fout() {
    echo "Fout: $1"
    echo "Druk op Enter om door te gaan..."
    read
}

# Functie om gebruikersinvoer te krijgen
krijg_invoer() {
    local prompt="$1"
    local input=""
    echo "$prompt"
    read -r input
    echo "$input"
}

# Functie om wachtwoord invoer te krijgen
krijg_wachtwoord() {
    local prompt="$1"
    local password=""
    echo "$prompt"
    read -s password
    echo "$password"
}

# Functie om voortgang weer te geven
toon_voortgang() {
    echo "Voortgang: $1"
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
            toon_fout "Onbekende versie: $versie"
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
        if GIT_ASKPASS="echo $wachtwoord" git clone "$repo_url"; then
            echo "Project succesvol gedownload."
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

# Installeer curl, git en jq altijd automatisch
echo "Vereiste packages curl, git en jq worden geïnstalleerd..."
if sudo apt-get update && sudo apt-get install -y curl git jq; then
    echo "Curl, git en jq zijn succesvol geïnstalleerd."
else
    echo "Installatie van curl, git of jq mislukt. Script wordt beëindigd."
    exit 1
fi

# Stap 1: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; then
    toon_fout "Project invoer is vereist."
    exit 1
fi

# Stap 2: Invoer voor gebruikersnaam en wachtwoord voor private repositories
gebruikersnaam=$(krijg_invoer "Voer uw gebruikersnaam in voor de private repository:")
if [ -z "$gebruikersnaam" ]; then
    toon_fout "Gebruikersnaam is vereist."
    exit 1
fi

wachtwoord=$(krijg_wachtwoord "Voer uw wachtwoord in voor de private repository:")
if [ -z "$wachtwoord" ]; then
    toon_fout "Wachtwoord is vereist."
    exit 1
fi

# Stap 3: Download project
toon_voortgang "Project wordt gedownload..."
if download_project "$project_invoer" "$gebruikersnaam" "$wachtwoord"; then
    echo "Project succesvol gedownload."
else
    toon_fout "Er is een fout opgetreden tijdens de project download."
    exit 1
fi

# Stap 4: Lees pakketten van pak.txt
if [ -f "pak.txt" ]; then
    pakketten=$(cat pak.txt)
else
    toon_fout "pak.txt niet gevonden in de gedownloade projectmap."
    exit 1
fi

# Stap 5: Installeer pakketten
echo "$pakketten" | while IFS= read -r package; do
    toon_voortgang "Bezig met installeren van $package..."
    installeer_pakketten "$package"
done

echo "De deployment van het project is voltooid."
echo "Druk op Enter om af te sluiten..."
read
clear