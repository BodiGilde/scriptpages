#!/bin/bash

# Maak een tijdelijke RAM-disk aan met tmpfs
ramdisk=$(mktemp -d)
mount -t tmpfs -o size=1M tmpfs $ramdisk

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
            echo "machine github.com login $token password x-oauth-basic" > $ramdisk/.netrc
            break
            ;;
        "Wachtwoord")
            read -p "Voer uw GitHub gebruikersnaam in: " username
            read -s -p "Voer uw GitHub wachtwoord in: " password
            echo
            # Schrijf de credentials naar een bestand in de RAM-disk
            echo "machine github.com login $username password $password" > $ramdisk/.netrc
            break
            ;;
        *)
            echo "Ongeldige optie $REPLY"
            ;;
    esac
done

# Stel de juiste permissies in voor het .netrc bestand
chmod 600 $ramdisk/.netrc

# Clone de repository lokaal met gebruik van de credentials in de RAM-disk
GIT_CURL_VERBOSE=1 GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true GIT_CONFIG_NOSYSTEM=1 GIT_SSL_NO_VERIFY=true git -c http.extraheader="AUTHORIZATION: basic $(echo -n $username:$password | base64)" clone https://github.com/$repo_url

# Ontkoppel en verwijder de RAM-disk na gebruik
umount $ramdisk
rm -rf $ramdisk

echo "Repository succesvol gecloned."
