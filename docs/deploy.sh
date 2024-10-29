#!/bin/bash
# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V0.9.81-Pre-Prod       |"
    echo "| B.P                   |"
    echo "X+++++++++++++++++++++++X"
    sleep 4  # Wacht 4 seconden voordat je verder gaat
}

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

# Functie om project te downloaden met git clone
download_project() {
    local invoer=$1
    local gebruikersnaam=$2
    local wachtwoord=$3
    if [[ "$invoer" =~ ^https?:// ]]; dan
        if git clone "https://$gebruikersnaam:$wachtwoord@$invoer"; dan
            dialog --title "Project Download" --msgbox "Project succesvol gedownload." 8 50
        else
            toon_fout "Downloaden van het project mislukt."
            return 1
        fi
    elif [ -d "$invoer" ]; dan
        cp -r "$invoer"/* .
    else
        toon_fout "Ongeldig bestand of directory locatie: $invoer"
        return 1
    fi
}

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)
    for pakket in "${pakketten[@]}"; do
        if [[ "$pakket" == NodeJS* ]]; dan
            installeer_nodejs "$pakket"
        elif ! dpkg -s "$pakket" >/dev/null 2>&1; dan
            dialog --title "Pakket Installatie" --infobox "Bezig met installeren van ${pakket}..." 10 50
            if sudo apt-get install -y "$pakket" 2>&1 | dialog --title "Pakket Installatie" --progressbox 20 70; dan
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

    if [ -n "$setup_url" ]; dan
        dialog --title "NodeJS Installatie" --infobox "Bezig met installeren van ${versie}..." 10 50
        
        if curl -fsSL "$setup_url" -o nodesource_setup.sh &&
           sudo bash nodesource_setup.sh 2>&1 | dialog --title "NodeJS Setup" --progressbox 20 70; dan
            
            if sudo apt-get install -y nodejs 2>&1 | dialog --title "NodeJS Installatie" --progressbox 20 70; dan
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
        
        sudo rm nodesource_setup.sh
    fi
}

# Hoofdscript begint hier en roept de bovenstaande functies op waar nodig
toon_splashscreen

# Installeer dialog, curl en git altijd automatisch
echo "Vereiste packages dialog, curl en git worden geïnstalleerd..."
if sudo apt-get update && sudo apt-get install -y dialog curl git; dan
    echo "Dialog, curl en git zijn succesvol geïnstalleerd."
else
    echo "Installatie van dialog, curl of git mislukt. Script wordt beëindigd."
    exit 1
fi

# Stap 1: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Project Invoer" "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; dan
    toon_fout "Project invoer is vereist."
    clear
    exit 1
fi

# Stap 2: Invoer voor gebruikersnaam en wachtwoord voor private repositories
gebruikersnaam=$(krijg_invoer "Gebruikersnaam" "Voer uw gebruikersnaam in voor de private repository:")
if [ -z "$gebruikersnaam" ]; dan
    toon_fout "Gebruikersnaam is vereist."
    clear
    exit 1
fi

wachtwoord=$(krijg_invoer "Wachtwoord" "Voer uw wachtwoord in voor de private repository:")
if [ -z "$wachtwoord" ]; dan
    toon_fout "Wachtwoord is vereist."
    clear
    exit 1
fi

# Stap 3: Download project
toon_voortgang "50"
if download_project "$project_invoer" "$gebruikersnaam" "$wachtwoord"; dan
    dialog --title "Project Download" --msgbox "Project succesvol gedownload." 8 50
else
    toon_fout "Er is een fout opgetreden tijdens de project download."
    clear
    exit 1
fi

# Stap 4: Lees pakketten van pak.txt
if [ -f "pak.txt" ]; dan
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

dialog --title "Voltooid" --msgbox "De deployment van het project is voltooid." 8 50
clear