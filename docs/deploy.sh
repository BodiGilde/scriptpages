#!/bin/bash

# Functie om een splashscreen weer te geven
toon_splashscreen() {
    clear
    
 echo " ___          _        _	            "             
 echo "| _ \_ _ ___ (_)___ __| |_           "
 echo "|  _/ '_/ _ \| / -_) _|  _|          "
 echo "|_|_|_| \___// \___\__|\__| ___ _  _ "
 echo "|   \ ___ _|__/ |___ _  _  / __| || |"
 echo "| |) / -_) '_ \ / _ \ || | \__ \ __ |"
 echo "|___/\___| .__/_\___/\_, | |___/_||_|"
 echo " ___   __|_| ___ __ _|__/ _          "
 echo "| _ ) | _ \ |_  )  \_  ) | |         "
 echo "| _ \_|  _/  / / () / /|_  _|        "
 echo "|___(_)_|   /___\__/___| |_|         "

    sleep 5
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

# Functie om vereiste pakketten te controleren en te installeren
controleer_en_installeer_pakketten() {
    local vereiste_pakketten=""

    case ${1,,} in
        *.zip)     vereiste_pakketten="unzip" ;;
        *.gz)      vereiste_pakketten="gzip" ;;
        *.bz2)     vereiste_pakketten="bzip2" ;;
        *.rar)     vereiste_pakketten="unrar" ;;
        *.7z)      vereiste_pakketten="p7zip-full" ;;
    esac

    if [ -n "$vereiste_pakketten" ]; then
        dialog --title "Pakket Installatie" --yesno "De volgende packages zijn vereist voor het unzippen: $vereiste_pakketten. Wilt u deze installeren?" 8 60
        response=$?
        if [ $response -eq 0 ]; then
            installeer_pakketten "$vereiste_pakketten"
        else
            toon_fout "Vereiste packages zijn niet geïnstalleerd. Kan niet doorgaan met unzippen."
            exit 1
        fi
    fi
}

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)
    local status=""

    for pakket in "${pakketten[@]}"; do
        if ! dpkg -s "$pakket" >/dev/null 2>&1; then
            status="${status}Bezig met installeren van ${pakket}...\n"
            dialog --title "Pakket Installatie" --infobox "$status" 10 50
            sudo apt-get install -y "$pakket" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                status="${status}${pakket} succesvol geïnstalleerd.\n"
            else
                status="${status}Installatie van ${pakket} mislukt.\n"
            fi
        else
            status="${status}${pakket} is al geïnstalleerd.\n"
        fi
        dialog --title "Pakket Installatie" --infobox "$status" 10 50
    done
    dialog --title "Pakket Installatie" --msgbox "$status" 10 50
}

# Functie om archieven te extraheren met sudo
extraheer_archief() {
    local bestand=$1
    controleer_en_installeer_pakketten "$bestand"
    case ${bestand,,} in
        *.zip)     sudo unzip "$bestand" ;;
        *.tar.gz|*.tgz)  sudo tar -xzvf "$bestand" ;;
        *.tar.bz2) sudo tar -xjvf "$bestand" ;;
        *.tar)     sudo tar -xvf "$bestand" ;;
        *.gz)      sudo gunzip "$bestand" ;;
        *.bz2)     sudo bunzip2 "$bestand" ;;
        *.rar)     sudo unrar x "$bestand" ;;
        *.7z)      sudo 7z x "$bestand" ;;
        *)         toon_fout "Niet ondersteund zip bestand" && return 1 ;;
    esac
    return $?
}

# Functie om project te downloaden en te extraheren
download_en_extraheer_project() {
    local invoer=$1
    if [[ "$invoer" =~ ^https?:// ]]; then
        # Invoer is een URL
        project_bestandsnaam=$(basename "$invoer")
        wget "$invoer" -O "$project_bestandsnaam"
        if [ $? -ne 0 ]; then
            toon_fout "Downloaden van het project mislukt."
            clear
            exit 1
        fi
        extraheer_archief "$project_bestandsnaam"
        sudo rm "$project_bestandsnaam"
    else
        # Invoer is een lokaal pad
        if [ -f "$invoer" ]; then
            extraheer_archief "$invoer"
        elif [ -d "$invoer" ]; then
            cp -r "$invoer"/* .
        else
            toon_fout "Ongeldig bestand of directory locatie."
            clear
            exit 1
        fi
    fi
}

# Hoofdscript begint hier

# Toon splashscreen
toon_splashscreen

# Installeer dialog altijd automatisch
echo "Vereist package dialog wordt geïnstalleerd..."
sudo apt-get update
sudo apt-get install -y dialog
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
installeer_pakketten "$pakketten"

# Stap 4: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Project Invoer" "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; then
    toon_fout "Project invoer is vereist."
    clear
    exit 1
fi

# Stap 5: Download en extraheer project
toon_voortgang "50"
download_en_extraheer_project "$project_invoer"

# Stap 6: Voltooiing
dialog --title "Voltooid" --msgbox "De deployment van het project is voltooid." 8 50

clear
