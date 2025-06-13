#!/bin/bash

# LineageOS Environment Setup Tool
# For Debian distros

clear

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# OEM List
OEM_LIST=("lge" "mediatek" "motorola" "nothing" "nubia" "oplus" "oneplus" "realme" "samsung" "sony" "xiaomi")

# Functions for Setup LineageOS Environments
setup_environment() {
    echo "1) Install build packages"
    echo "2) Install libncurses5 (for Ubuntu 23.0 and up)"
    echo "0) Back"
    read -p "Choose an option: " env_choice

    case $env_choice in
        1)
            echo -e "${GREEN}Installing build packages...${NC}"
            sudo apt update
            sudo apt install -y bc bison build-essential curl flex g++-multilib gcc-multilib \
            git gnupg gperf imagemagick lib32readline-dev lib32z1-dev \
            libssl-dev libxml2-utils lzop pngcrush rsync schedtool \
            squashfs-tools xsltproc zip zlib1g-dev git-lfs
            ;;
        2)
            echo -e "${GREEN}Installing libncurses5...${NC}"
            wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb && sudo dpkg -i libtinfo5_6.3-2_amd64.deb && rm -f libtinfo5_6.3-2_amd64.deb
            wget https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb && sudo dpkg -i libncurses5_6.3-2_amd64.deb && rm -f libncurses5_6.3-2_amd64.deb
            ;;
        0)
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Functions for Google Platform Tools
install_platform_tools() {
    echo "1) Install platform-tools and configure ~/.bashrc"
    echo "2) Install repo command and configure ~/.bashrc"
    echo "0) Back"
    read -p "Choose an option: " pt_choice

    case $pt_choice in
        1)
            echo -e "${GREEN}Installing Google platform-tools...${NC}"
            mkdir -p ~/bin
            cd ~/bin
            wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
            unzip -o platform-tools-latest-linux.zip
            echo 'export PATH=$HOME/bin/platform-tools:$PATH' >> ~/.bashrc
            source ~/.bashrc
            echo -e "${GREEN}platform-tools installed and PATH updated.${NC}"
            ;;
        2)
            echo -e "${GREEN}Installing repo command...${NC}"
            mkdir -p ~/bin
            curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
            chmod a+x ~/bin/repo
            echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
            source ~/.bashrc
            echo -e "${GREEN}repo command installed and PATH updated.${NC}"
            ;;
        0)
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
}

# Function to Sync LineageOS Source
sync_source() {
    echo "Select branch to sync:"
    echo "1) lineage-21.0"
    echo "2) lineage-22.0"
    echo "3) lineage-22.1"
    echo "4) lineage-22.2"
    echo "0) Back"
    read -p "Branch: " branch_choice

    case $branch_choice in
        1) branch="lineage-21.0";;
        2) branch="lineage-22.0";;
        3) branch="lineage-22.1";;
        4) branch="lineage-22.2";;
        0) return;;
        *) echo "Invalid option"; return;;
    esac

    echo "Select number of jobs (1-10):"
    read -p "Jobs: " jobs
    if [[ "$jobs" -ge 1 && "$jobs" -le 10 ]]; then
        mkdir -p ~/android/lineage
        cd ~/android/lineage
        repo init --depth=1 -u https://github.com/LineageOS/android.git -b "$branch" --git-lfs
        repo sync -j"$jobs"
        echo -e "${GREEN}Source synced to ~/android/lineage"
    else
        echo "Invalid number of jobs."
    fi
}

# Function to Sync OEM hardware repo
sync_oem_repo() {
    echo "Select branch for roomservice manifest:"
    echo "1) lineage-21"
    echo "2) lineage-22.0"
    echo "3) lineage-22.1"
    echo "4) lineage-22.2"
    echo "0) Back"
    read -p "Branch: " branch_choice

    case $branch_choice in
        1) branch="lineage-21";;
        2) branch="lineage-22.0";;
        3) branch="lineage-22.1";;
        4) branch="lineage-22.2";;
        0) return;;
        *) echo "Invalid option"; return;;
    esac

    echo "Select OEM to sync:"
    for i in "${!OEM_LIST[@]}"; do
        printf "%d) %s\n" $((i+1)) "${OEM_LIST[$i]}"
    done
    echo "0) Back"
    read -p "OEM: " oem_choice

    if [[ "$oem_choice" -ge 1 && "$oem_choice" -le ${#OEM_LIST[@]} ]]; then
        oem="${OEM_LIST[$((oem_choice-1))]}"
        manifest_dir=~/android/lineage/.repo/local_manifests
        mkdir -p "$manifest_dir"

        cat <<EOF > "$manifest_dir/roomservice.xml"
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <project name="LineageOS/android_hardware_${oem}" path="hardware/${oem}" remote="github" revision="${branch}"/>
</manifest>
EOF

        echo -e "${GREEN}Manifest created for $oem at $manifest_dir${NC}"

        cd ~/android/lineage
        repo sync -j4 hardware/${oem}
        echo -e "${GREEN}$oem hardware repo synced successfully.${NC}"

    elif [[ "$oem_choice" -eq 0 ]]; then
        return
    else
        echo "Invalid OEM option"
    fi
}

# Function to enable CCACHE
enable_ccache() {
    echo -e "${GREEN}Enabling CCACHE...${NC}"
    sudo apt update
    sudo apt install -y ccache

    grep -qxF 'export USE_CCACHE=1' ~/.bashrc || echo 'export USE_CCACHE=1' >> ~/.bashrc
    grep -qxF 'export CCACHE_EXEC=/usr/bin/ccache' ~/.bashrc || echo 'export CCACHE_EXEC=/usr/bin/ccache' >> ~/.bashrc
    grep -qxF 'export CCACHE_DIR=$HOME/.ccache' ~/.bashrc || echo 'export CCACHE_DIR=$HOME/.ccache' >> ~/.bashrc

    export USE_CCACHE=1
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_DIR=$HOME/.ccache

    ccache -M 50G

    echo -e "${GREEN}CCACHE enabled and configured (50GB cache size).${NC}"
}

# Main menu
while true; do
    echo -e "\n${GREEN}LineageOS Environment Tools${NC}"
    echo "1) Setup LineageOS Environments for Debian based OS"
    echo "2) Install the Google platform-tools"
    echo "3) Sync LineageOS source"
    echo "4) Sync OEM hardware repo"
    echo "5) Enable CCACHE"
    echo "0) Exit"
    read -p "Choose an option: " main_choice

    case $main_choice in
        1) setup_environment;;
        2) install_platform_tools;;
        3) sync_source;;
        4) sync_oem_repo;;
        5) enable_ccache;;
        0) echo "Exiting."; exit 0;;
        *) echo "Invalid option";;
    esac
done
