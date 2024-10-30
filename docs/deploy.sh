#!/bin/bash

# Vraag om de GitHub repository URL
read -p "Voer de GitHub repository URL in (bijv. gebruiker/repository): " repo_url

# Vraag om de authenticatiemethode
echo "Kies de authenticatiemethode:"
select auth_method in "Token" "Wachtwoord"; do
    case $auth_method in
        "Token")
            read -s -p "Voer uw GitHub persoonlijke toegangstoken in: " token
            echo
            # Schrijf de credentials naar een bestand in de RAM-disk
            echo "machine github.com login $token password x-oauth-basic" > /tmp/.netrc
            break
            ;;
        "Wachtwoord")
            read -p "Voer uw GitHub gebruikersnaam in: " username
            read -s -p "Voer uw GitHub wachtwoord in: " password
            echo
            # Schrijf de credentials naar een bestand in de RAM-disk
            echo "machine github.com login $username password $password" > /tmp/.netrc
            break
            ;;
        *)
            echo "Ongeldige optie $REPLY"
            ;;
    esac
done

# Stel de juiste permissies in voor het .netrc bestand
chmod 600 /tmp/.netrc

# Clone de repository lokaal met gebruik van de credentials in de RAM-disk
sudo git clone https://github.com/$repo_url

# Verwijder het .netrc bestand na gebruik
rm /tmp/.netrc

echo "Repository succesvol gecloned."
