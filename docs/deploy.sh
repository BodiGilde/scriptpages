#!/bin/bash

# Function to display error messages
show_error() {
    dialog --title "Error" --msgbox "$1" 8 50
}

# Function to get user input
get_input() {
    dialog --title "$1" --inputbox "$2" 8 60 3>&1 1>&2 2>&3
}

# Function to show progress
show_progress() {
    echo "$1" | dialog --title "Progress" --gauge "Please wait..." 8 50 0
}

# Function to check and install packages
install_packages() {
    local packages=($1)
    local total=${#packages[@]}
    local counter=0
    local status=""

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            counter=$((counter + 1))
            progress=$((counter * 100 / total))
            status="${status}Installing ${package}...\n"
            dialog --title "Package Installation" --infobox "$status" 10 50
            sudo apt-get install -y "$package" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                status="${status}${package} installed successfully.\n"
            else
                status="${status}Failed to install ${package}.\n"
            fi
        else
            status="${status}${package} is already installed.\n"
        fi
        dialog --title "Package Installation" --infobox "$status" 10 50
    done
    dialog --title "Package Installation" --msgbox "$status" 10 50
}

# Function to check and remove packages
remove_packages() {
    local packages=($1)
    local total=${#packages[@]}
    local counter=0
    local status=""

    for package in "${packages[@]}"; do
        if dpkg -s "$package" >/dev/null 2>&1; then
            counter=$((counter + 1))
            progress=$((counter * 100 / total))
            status="${status}Removing ${package}...\n"
            dialog --title "Package Removal" --infobox "$status" 10 50
            sudo apt-get remove -y "$package" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                status="${status}${package} removed successfully.\n"
            else
                status="${status}Failed to remove ${package}.\n"
            fi
        else
            status="${status}${package} is not installed.\n"
        fi
        dialog --title "Package Removal" --infobox "$status" 10 50
    done
    dialog --title "Package Removal" --msgbox "$status" 10 50
    dialog --title "Success" --msgbox "Package removal completed successfully! Press any key to continue." 10 50
    clear
    exit 0
}

# Function to check and install required packages
check_and_install_packages() {
    local required_packages=""

    case ${1,,} in
        *.zip)     required_packages="unzip" ;;
        *.tar.gz|*.tgz|*.tar|*.tar.bz2) required_packages="tar" ;;
        *.gz)      required_packages="gzip" ;;
        *.bz2)     required_packages="bzip2" ;;
        *.rar)     required_packages="unrar" ;;
        *.7z)      required_packages="p7zip-full" ;;
    esac

    if [ -n "$required_packages" ]; then
        dialog --title "Package Installation" --yesno "The following packages are required: $required_packages. Do you want to install them?" 8 60
        response=$?
        if [ $response -eq 0 ]; then
            install_packages "$required_packages"
        else
            show_error "Required packages are not installed. Cannot proceed with extraction."
            exit 1
        fi
    fi
}

# Function to extract archives with sudo
extract_archive() {
    local file=$1
    check_and_install_packages "$file"
    case ${file,,} in
        *.zip)     sudo unzip "$file" ;;
        *.tar.gz|*.tgz)  sudo tar -xzvf "$file" ;;
        *.tar.bz2) sudo tar -xjvf "$file" ;;
        *.tar)     sudo tar -xvf "$file" ;;
        *.gz)      sudo gunzip "$file" ;;
        *.bz2)     sudo bunzip2 "$file" ;;
        *.rar)     sudo unrar x "$file" ;;
        *.7z)      sudo 7z x "$file" ;;
        *)         show_error "Unsupported archive format" && return 1 ;;
    esac
    return $?
}

# Main script starts here

# Step 1: Choose to install or remove packages
action=$(dialog --title "Action" --menu "Choose an action:" 10 50 2 1 "Install Packages" 2 "Remove Packages" 3>&1 1>&2 2>&3)
if [ -z "$action" ]; then
    show_error "No action selected."
    clear
    exit 1
fi

# Step 2: Input for package/dependencies URL
package_url=$(get_input "Package Input" "Enter package/dependencies URL:")
if [ -z "$package_url" ]; then
    show_error "Package URL is required."
    clear
    exit 1
fi

# Step 3: Read packages from URL
packages=$(curl -s "$package_url")
if [ -z "$packages" ]; then
    show_error "Failed to read package list from URL."
    clear
    exit 1
fi

# Step 4: Install or remove packages based on user choice
if [ "$action" -eq 1 ]; then
    install_packages "$packages"
else
    remove_packages "$packages"
fi

# Step 5: Input for project archive
project_input=$(get_input "Project Input" "Enter project archive URL:")
if [ -z "$project_input" ]; then
    show_error "Project input is required."
    clear
    exit 1
fi

# Step 6: Download project
show_progress "50"
project_filename=$(basename "$project_input")
wget "$project_input" -O "$project_filename"
if [ $? -ne 0 ]; then
    show_error "Failed to download the project."
    clear
    exit 1
fi

# Step 7: Choose location
dialog --title "Location" --yesno "Do you want to use the default location?" 8 50
response=$?

if [ $response -eq 1 ]; then
    custom_location=$(get_input "Custom Location" "Enter the custom location:")
    if [ -z "$custom_location" ]; then
        show_error "Custom location is required."
        clear
        exit 1
    fi
    sudo mkdir -p "$custom_location"
    sudo mv "$project_filename" "$custom_location"
    cd "$custom_location" || exit
else
    dialog --title "Info" --msgbox "Using default location." 8 50
fi

# Step 8: Extract project
show_progress "75"
extract_archive "$project_filename"
if [ $? -ne 0 ]; then
    show_error "Failed to extract the project."
    clear
    exit 1
fi

# Remove the archive file after successful extraction
sudo rm "$project_filename"

# Step 9: Completion
dialog --title "Completed" --msgbox "Deployment process completed successfully!" 8 50

clear
