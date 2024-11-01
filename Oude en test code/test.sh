#!/bin/bash

# Installeert dialog wat vereist is voor de GUI
sudo apt install dialog

# Functie om systeemupdates en upgrades uit te voeren
update_upgrade() {
    # Bevestiging voordat de update en upgrade worden uitgevoerd
    dialog --title "Confirmation" --yesno "Do you want to perform system updates and upgrades?" 7 50
    if [ $? -ne 0 ]; then
        return  # Terug naar het hoofdmenu als geannuleerd
    fi

    # Voer de update uit
    dialog --title "Update & Upgrade" --infobox "Updates are being performed, this may take a while..." 7 50
    sudo apt-get update 2>&1 | dialog --progressbox "Updating packages..." 20 70
    if [ $? -eq 0 ]; then
        sudo apt-get upgrade -y 2>&1 | dialog --progressbox "Upgrading packages..." 20 70
        dialog --msgbox "Updates and upgrades completed." 7 50
    else
        dialog --msgbox "Error during updating/upgrading." 7 50
    fi

    # Automatisch terug naar het hoofdmenu
    return
}

# Functie om pakketten te installeren
install_packages() {
    # Definieer pakketten
    PACKAGES=("neofetch" "htop" "curl")  # Voeg hier nieuwe pakketten toe

    # Maak de checklist optie voor de installatie dynamisch
    CHECKLIST_OPTIONS=()
    for i in "${!PACKAGES[@]}"; do
        CHECKLIST_OPTIONS+=($((i + 1)) "${PACKAGES[$i]}" off)  # Dynamische checklist index
    done

    # Maak de checklist optie voor de installatie
    CHOICE=$(dialog --title "Install Packages" --checklist "Make installation choice:" 15 50 ${#PACKAGES[@]} "${CHECKLIST_OPTIONS[@]}" 3>&1 1>&2 2>&3)

    # Controleer of de gebruiker op "Cancel" heeft gedrukt
    if [ $? -ne 0 ]; then
        return  # Terug naar het hoofdmenu
    fi

    if [ -z "$CHOICE" ]; then
        # Geen pakketten geselecteerd, toon foutmelding
        dialog --msgbox "No packages selected for installation." 7 50
    else
        # Loop door de geselecteerde pakketten
        for package_id in $CHOICE; do
            # Gebruik de index om de juiste pakketnaam te verkrijgen
            PACKAGE_NAME=${PACKAGES[$((package_id - 1))]}  # -1 omdat de index begint bij 0

            if [ -n "$PACKAGE_NAME" ]; then
                # Installeer het pakket en gebruik de pakketnaam in de dialog
                sudo apt-get install -y "$PACKAGE_NAME" 2>&1 | dialog --progressbox "Installing $PACKAGE_NAME..." 20 70
            fi
        done
        dialog --msgbox "Installations completed." 7 50
    fi

    # Automatisch terug naar het hoofdmenu
    return
}

# Functie om een bestand te downloaden, met download-snelheidsmeter
download_file() {
    URL=$(dialog --title "Download File" --inputbox "Enter the file URL:" 8 50 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then return; fi  # Terug naar het hoofdmenu als geannuleerd

    if [ -z "$URL" ]; then
        dialog --msgbox "No URL provided. Download canceled." 7 50
        return
    fi

    DEST=$(dialog --title "Download File" --inputbox "Enter the storage location (e.g., /home/user/downloads):" 8 50 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then return; fi  # Terug naar het hoofdmenu als geannuleerd

    if [ -n "$URL" ] && [ -n "$DEST" ]; then
        mkdir -p "$DEST"
        # Gebruik wget met --show-progress om de download progressie en snelheid te tonen
        wget --progress=bar:force:noscroll -O "$DEST/$(basename "$URL")" "$URL" 2>&1 | \
        stdbuf -oL tr '\r' '\n' | dialog --title "Downloading File" --progressbox "Downloading file with progress..." 20 70
        if [ $? -eq 0 ]; then
            dialog --msgbox "File downloaded to $DEST." 7 50
        else
            dialog --msgbox "Error during downloading." 7 50
        fi
    else
        dialog --msgbox "Download canceled." 7 50
    fi

    # Automatisch terug naar het hoofdmenu
    return
}

# Hoofdmenu functie
main_menu() {
    while true; do
        OPTION=$(dialog --clear --title "Main Menu" --menu "Make a choice:" 15 50 4 \
            "1" "Update & Upgrade" \
            "2" "Install Packages" \
            "3" "Download File" 3>&1 1>&2 2>&3)

        # Controleer of de gebruiker "Cancel" heeft gekozen (Exit-status 1)
        if [ $? -ne 0 ]; then
            break  # Sluit het script af als de gebruiker "Cancel" kiest
        fi

        case $OPTION in
            1)
                update_upgrade
                ;;
            2)
                install_packages
                ;;
            3)
                download_file
                ;;
            *)
                dialog --msgbox "Invalid option, please try again." 5 40
                ;;
        esac
    done
    clear
}

# Start het hoofdmenu
main_menu
