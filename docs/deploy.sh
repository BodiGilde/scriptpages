#!/bin/bash

# Functie om een splashscreen weer te geven met korte informatie over het script
toon_splashscreen() {
    clear 
    echo
    echo "X+++++++++++++++++++++++X"
    echo "| Project Deploy Script |"
    echo "| V0.8-PreProd          |"
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

# Functie om vereiste pakketten te controleren en te installeren
controleer_en_installeer_pakketten() {
    local vereiste_pakketten=""

    # Controleer het bestandstype en bepaal welke pakketten nodig zijn
    case ${1,,} in
        *.zip)     vereiste_pakketten="unzip" ;;
        *.gz)      vereiste_pakketten="gzip" ;;
        *.bz2)     vereiste_pakketten="bzip2" ;;
        *.rar)     vereiste_pakketten="unrar" ;;
        *.7z)      vereiste_pakketten="p7zip-full" ;;
    esac

    # Als er vereiste pakketten zijn, vraag de gebruiker om toestemming om ze te installeren
    if [ -n "$vereiste_pakketten" ]; then
        dialog --title "Pakket Installatie" --yesno "De volgende packages zijn vereist voor het unzippen: $vereiste_pakketten. Wilt u deze installeren?" 8 60
        response=$?
        if [ $response -eq 0 ]; then
            installeer_pakketten "$vereiste_pakketten"  # Installeer de vereiste pakketten
        else
            toon_fout "Vereiste packages zijn niet geïnstalleerd. Kan niet doorgaan met unzippen."
            exit 1
        fi
    fi
}

# Functie om pakketten te installeren
installeer_pakketten() {
    local pakketten=($1)

    # Installeer elk pakket dat nog niet is geïnstalleerd
    for pakket in "${pakketten[@]}"; do
        if [[ "$pakket" == nodejs* ]]; then
            local versie=${pakket#nodejs}  # Haal de versie uit de pakketnaam
            installeer_nodejs "$versie"  # Installeer Node.js met de opgegeven versie
        else
            if ! dpkg -s "$pakket" >/dev/null 2>&1; then  # Controleer of het pakket al is geïnstalleerd
                dialog --title "Pakket Installatie" --infobox "Bezig met installeren van ${pakket}..." 10 50
                sudo apt-get install -y "$pakket" 2>&1 | dialog --title "Pakket Installatie" --progressbox 20 70  # Toon de installatie output in een dialoogvenster
                if [ $? -eq 0 ]; then
                    dialog --title "Pakket Installatie" --msgbox "${pakket} succesvol geïnstalleerd." 8 50
                else
                    dialog --title "Pakket Installatie" --msgbox "Installatie van ${pakket} mislukt." 8 50
                fi
            else
                dialog --title "Pakket Installatie" --msgbox "${pakket} is al geïnstalleerd." 8 50
            fi
        fi
    done
}

# Functie om Node.js te installeren
installeer_nodejs() {
    local versie=$1  # Haal de versie uit de argumenten

    # Installeer curl als het nog niet is geïnstalleerd
    if ! dpkg -s curl >/dev/null 2>&1; then
        dialog --title "curl Installatie" --infobox "curl wordt geïnstalleerd..." 10 50
        sudo apt-get install -y curl 2>&1 | dialog --title "curl Installatie" --progressbox 20 70
    fi

    # Download het setup script
    dialog --title "Node.js Installatie" --infobox "NodeSource setup script downloaden voor Node.js versie $versie..." 10 50
    curl -fsSL https://deb.nodesource.com/setup_${versie}.x -o nodesource_setup.sh 2>&1 | dialog --title "Node.js Installatie" --progressbox 20 70

    # Voer het setup script uit
    dialog --title "Node.js Installatie" --infobox "NodeSource setup script uitvoeren..." 10 50
    sudo bash nodesource_setup.sh 2>&1 | dialog --title "Node.js Installatie" --progressbox 20 70

    # Installeer Node.js
    dialog --title "Node.js Installatie" --infobox "Node.js installeren..." 10 50
    sudo apt-get install -y nodejs 2>&1 | dialog --title "Node.js Installatie" --progressbox 20 70

    # Verifieer de installatie
    node -v 2>&1 | dialog --title "Node.js Installatie" --msgbox "Node.js versie $versie succesvol geïnstalleerd. Versie: $(node -v)" 8 50

    # Verwijder het setup script
    sudo rm nodesource_setup.sh
}

# Functie om archieven te extraheren met sudo
extraheer_archief() {
    local bestand=$1
    controleer_en_installeer_pakketten "$bestand"  # Controleer en installeer vereiste pakketten
    case ${bestand,,} in
        *.zip)     sudo unzip "$bestand" ;;  # Extraheer een zip-bestand
        *.tar.gz|*.tgz)  sudo tar -xzvf "$bestand" ;;  # Extraheer een tar.gz-bestand
        *.tar.bz2) sudo tar -xjvf "$bestand" ;;  # Extraheer een tar.bz2-bestand
        *.tar)     sudo tar -xvf "$bestand" ;;  # Extraheer een tar-bestand
        *.gz)      sudo gunzip "$bestand" ;;  # Extraheer een gz-bestand
        *.bz2)     sudo bunzip2 "$bestand" ;;  # Extraheer een bz2-bestand
        *.rar)     sudo unrar x "$bestand" ;;  # Extraheer een rar-bestand
        *.7z)      sudo 7z x "$bestand" ;;  # Extraheer een 7z-bestand
        *)         toon_fout "Niet ondersteund zip bestand" && return 1 ;;  # Toon een foutmelding voor niet-ondersteunde bestandstypen
    esac
    return $?
}

# Functie om project te downloaden en te extraheren
download_en_extraheer_project() {
    local invoer=$1
    if [[ "$invoer" =~ ^https?:// ]]; then
        # Invoer is een URL
        project_bestandsnaam=$(basename "$invoer")
        wget "$invoer" -O "$project_bestandsnaam"  # Download het projectbestand
        if [ $? -ne 0 ]; then
            toon_fout "Downloaden van het project mislukt."
            clear
            exit 1
        fi
        extraheer_archief "$project_bestandsnaam"  # Extraheer het gedownloade projectbestand
        sudo rm "$project_bestandsnaam"  # Verwijder het gedownloade bestand na extractie
    else
        # Invoer is een lokaal pad
        if [ -f "$invoer" ]; then
            extraheer_archief "$invoer"  # Extraheer het lokale projectbestand
        elif [ -d "$invoer" ]; then
            cp -r "$invoer"/* .  # Kopieer de inhoud van de lokale directory naar de huidige directory
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
installeer_pakketten "$pakketten"

# Stap 4: Invoer voor projectarchief of map
project_invoer=$(krijg_invoer "Project Invoer" "Voer projectarchief URL of lokaal pad in:")
if [ -z "$project_invoer" ]; then
    toon_fout "Project invoer is vereist."
    clear
    exit 1
fi

# Stap 5: Download en extraheer project
toon_voortgang "50"  # Toon voortgangsbalk op 50%
download_en_extraheer_project "$project_invoer"

# Stap 6: Voltooiing
dialog --title "Voltooid" --msgbox "De deployment van het project is voltooid." 8 50  # Toon voltooiingsbericht

clear  # Wis het scherm na voltooiing
