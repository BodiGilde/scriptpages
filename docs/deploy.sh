#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V1.4.0-Pre-Prod       |"
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

# Functie om gebruikersinvoer te vragen met een timeout
vraag_input() {
    local prompt=$1
    local default_value=$2
    local timeout=60
    local input=""
    local timer=0

    echo "$prompt"
    echo "Je hebt $timeout seconden om te antwoorden."
    echo "Druk op Enter om de standaardwaarde te gebruiken: $default_value"
    
    # Start een achtergrondproces om de timer bij te houden
    (
        while [ $timer -lt $timeout ]; do
            sleep 1
            ((timer++))
            echo -ne "\rResterend: $(($timeout-$timer)) seconden...   \r"
        done
        echo -e "\nTimeout bereikt."
    ) &
    timer_pid=$!

    # Lees gebruikersinvoer
    read -t $timeout input
    read_status=$?

    # Stop de timer
    kill $timer_pid 2>/dev/null
    wait $timer_pid 2>/dev/null

    if [ $read_status -eq 0 ]; then
        if [ -z "$input" ]; then
            echo "Standaardwaarde wordt gebruikt: $default_value"
            echo "$default_value"
        else
            echo "Ingevoerde waarde: $input"
            echo "$input"
        fi
    else
        echo "Timeout. Standaardwaarde wordt gebruikt: $default_value"
        echo "$default_value"
    fi
}

# Functie om een privé GitHub-repository te klonen
kloon_repository() {
    local repo_url
    local repo_naam
    local gebruikersnaam
    local wachtwoord

    # Vraag om repository URL
    repo_url=$(vraag_input "Voer de URL van de GitHub-repository in (of plak deze):" "https://github.com/gebruiker/repo.git")
    repo_naam=$(basename -s .git "$repo_url")

    # Vraag om gebruikersnaam
    gebruikersnaam=$(vraag_input "Voer je GitHub-gebruikersnaam in:" "standaard_gebruiker")

    # Vraag om wachtwoord
    echo "Voer je GitHub-wachtwoord of personal access token in:"
    echo "Je hebt 60 seconden om te antwoorden."
    read -s -t 60 wachtwoord
    wachtwoord_status=$?
    echo

    if [ $wachtwoord_status -ne 0 ]; then
        echo "Timeout bij wachtwoordinvoer."
        return 1
    fi

    if [ -z "$wachtwoord" ]; then
        echo "Geen wachtwoord ingevoerd."
        return 1
    fi

    echo "Bezig met klonen van de repository..."
    if git clone "https://${gebruikersnaam}:${wachtwoord}@${repo_url#https://}" "$repo_naam"; then
        echo "Repository succesvol gekloond naar $repo_naam"
        cd "$repo_naam" || exit
        return 0
    else
        echo "Klonen van de repository is mislukt."
        return 1
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

    # Probeer de repository te klonen, blijf het proberen tot het lukt of de gebruiker afbreekt
    while ! kloon_repository; do
        echo "Wil je het opnieuw proberen? (j/n)"
        read -n 1 -r antwoord
        echo
        if [[ ! $antwoord =~ ^[Jj]$ ]]; then
            echo "Script wordt afgebroken."
            exit 1
        fi
    done

    installeer_pakketten_uit_bestand

    echo "Script voltooid."
}

# Voer het hoofdscript uit
main