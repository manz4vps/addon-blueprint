#!/bin/bash

# ==========================================
# Terminal Colors & UI Elements
# ==========================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

# Modern Emoji Status Indicators
INFO="${CYAN}💡 [INFO]${RESET}"
SUCCESS="${GREEN}✅ [SUCCESS]${RESET}"
ERROR="${RED}❌ [ERROR]${RESET}"
WARN="${YELLOW}⚠️ [WARNING]${RESET}"
LOADING="${MAGENTA}⏳ [WORKING]${RESET}"

# ==========================================
# Configuration 
# ==========================================
# ⚠️ REMEMBER TO USE A NEW, SECURE TOKEN!
T_P1="ghp_"
T_P2="YOUR_NEW_TOKEN_HERE" 
GITHUB_TOKEN="${T_P1}${T_P2}"

GITHUB_REPO="sdgamer8263-sketch/pterodactyl_extention1"
BRANCH="main"
API_URL_EX="https://api.github.com/repos/${GITHUB_REPO}/contents/ex?ref=${BRANCH}"
API_URL_TR="https://api.github.com/repos/${GITHUB_REPO}/contents/Trr?ref=${BRANCH}"
PTERODACTYL_DIR="/var/www/pterodactyl"

# ==========================================
# Pre-flight Checks
# ==========================================
clear
echo -e "${CYAN}${BOLD}🚀 Initializing SKA HOST Environment...${RESET}\n"

if [[ $EUID -ne 0 ]]; then
   echo -e "${ERROR} ${RED}This script must be run as root. Please use sudo.${RESET}" 
   exit 1
fi

if [ ! -d "$PTERODACTYL_DIR" ]; then
    echo -e "${ERROR} ${RED}Pterodactyl directory ($PTERODACTYL_DIR) not found.${RESET}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${WARN} ${YELLOW}'jq' is missing. Installing it now... ⚙️${RESET}"
    apt-get update -y -q > /dev/null 2>&1 && apt-get install -y jq -q > /dev/null 2>&1
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${WARN} ${YELLOW}'unzip' is missing. Installing it now... 📦${RESET}"
    apt-get update -y -q > /dev/null 2>&1 && apt-get install -y unzip -q > /dev/null 2>&1
fi

# ==========================================
# Function: Fetch & Prepare List
# ==========================================
fetch_and_prepare_list() {
    echo -e "\n${INFO} ${CYAN}Fetching available extensions from the cloud... ☁️${RESET}"
    
    if [ -n "$GITHUB_TOKEN" ] && [ "$GITHUB_TOKEN" != "ghp_YOUR_NEW_TOKEN_HERE" ]; then
        FILES_JSON_EX=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL_EX")
        FILES_JSON_TR=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL_TR")
    else
        FILES_JSON_EX=$(curl -s "$API_URL_EX")
        FILES_JSON_TR=$(curl -s "$API_URL_TR")
    fi

    if echo "$FILES_JSON_EX" | grep -q '"message":' || echo "$FILES_JSON_TRR" | grep -q '"message":'; then
        echo -e "${ERROR} ${RED}Failed to fetch from GitHub API. Check repo details. 🛑${RESET}"
        sleep 2
        return
    fi

    ALL_OPTIONS=()
    SORTED_OPTIONS=()

    # 1. Add Custom Script Options (Prefix with Script emoji for later)
    ALL_OPTIONS+=("Plugin Manager Addon|script|bash <(curl -s 'https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/Plugin%20Manager%20Addon.sh')|none")
    ALL_OPTIONS+=("Pterodactyl Region|script|bash <(curl -s https://exeyarikus.info/pterodactyl-region/install)|none")
    ALL_OPTIONS+=("SAGA Auto Suspension|script|bash <(curl -s https://raw.githubusercontent.com/sdgamer8263-sketch/EXD/main/ac.sh)|none")
   
    # 2. Fetch .blueprint files
    if echo "$FILES_JSON_EX" | grep -q '"name":'; then
        while IFS= read -r line; do
            raw_name=$(echo "$line" | cut -d'|' -f1)
            url=$(echo "$line" | cut -d'|' -f2)
            clean_name="${raw_name%.blueprint}"
            clean_name="${clean_name^}"
            ALL_OPTIONS+=("$clean_name|blueprint|$url|$raw_name")
        done < <(echo "$FILES_JSON_EX" | jq -r '.[] | select(.name | endswith(".blueprint")) | "\(.name)|\(.download_url)"')
    fi

    # 3. Fetch .zip files
    if echo "$FILES_JSON_TR" | grep -q '"name":'; then
        while IFS= read -r line; do
            raw_name=$(echo "$line" | cut -d'|' -f1)
            url=$(echo "$line" | cut -d'|' -f2)
            clean_name="${raw_name%.zip}"
            clean_name="${clean_name^}"
            ALL_OPTIONS+=("$clean_name|zip|$url|$raw_name")
        done < <(echo "$FILES_JSON_TR" | jq -r '.[] | select(.name | endswith(".zip")) | "\(.name)|\(.download_url)"')
    fi

    IFS=$'\n' SORTED_OPTIONS=($(sort -f <<<"${ALL_OPTIONS[*]}"))
    unset IFS
    
    echo -e "${SUCCESS} ${GREEN}Extensions loaded successfully! 🎉${RESET}"
    sleep 1
}

fetch_and_prepare_list

# ==========================================
# Interactive Menu Loop
# ==========================================
while true; do
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
   _____ _  __    _      _    _  ____   _____ _______ 
  / ____| |/ /   / \    | |  | |/ __ \ / ____|__   __|
 | (___ | ' /   / _ \   | |__| | |  | | (___    | |   
  \___ \|  <   / ___ \  |  __  | |  | |\___ \   | |   
  ____) | . \ / /   \ \ | |  | | |__| |____) |  | |   
 |_____/|_|\_/_/     \_\|_|  |_|\____/|_____/   |_|   
EOF
    echo -e "${RESET}"
    
    # Premium Header Box with modern rounded borders
    echo -e "${CYAN}╭──────────────────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET}                🚀 ${MAGENTA}${BOLD}SKA HOST (SDGAMER) - Panel Installer${RESET} 🚀               ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET} ✨ ${WHITE}Select an extension to install:${RESET}                                        ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    
    # Display Options in 2 Columns
    count=1
    total_options=${#SORTED_OPTIONS[@]}
    
    for opt in "${SORTED_OPTIONS[@]}"; do
        disp_name=$(echo "$opt" | cut -d'|' -f1)
        opt_type=$(echo "$opt" | cut -d'|' -f2)
        
        # Decide which emoji to show based on type
        if [[ "$opt_type" == "script" ]]; then
            icon="⚙️ "
        else
            icon="🧩"
        fi
        
        # Using 28 characters max width for names to accommodate emojis and spacing
        printf "${CYAN}│${RESET}  ${GREEN}%02d.${RESET} $icon ${WHITE}%-28s${RESET} " "$count" "${disp_name:0:28}"
        
        if (( count % 2 == 0 )); then
            # End of second column, close the box line
            echo -e "${CYAN}│${RESET}"
        elif (( count == total_options )); then
            # If total items are odd and this is the last item, pad the empty space
            printf "%-39s${CYAN}│${RESET}\n" " "
        fi
        
        ((count++))
    done
    
    # Premium Footer Box
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET}  ${YELLOW}🔄 R.${RESET} ${WHITE}Refresh Catalog${RESET}                       ${RED}🛑 0.${RESET} ${WHITE}Exit Installer${RESET}          ${CYAN}│${RESET}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────────╯${RESET}"

    echo -n -e "\n${BOLD}${MAGENTA}  👉 Enter your choice [0-$((count-1)), R]: ${RESET}"
    read choice

    if [[ "$choice" == "0" || "$choice" == "00" ]]; then
        echo -e "\n${SUCCESS} ${GREEN}Exiting SKA HOST Installer. Have a great day! 👋${RESET}\n"
        exit 0
    fi

    if [[ "${choice,,}" == "r" ]]; then
        fetch_and_prepare_list
        continue
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$count" ]; then
        echo -e "\n${ERROR} ${RED}Invalid Selection! Please enter a valid number or 'R'. 🚫${RESET}"
        sleep 2
        continue
    fi

    selected_index=$((choice-1))
    selected_data="${SORTED_OPTIONS[$selected_index]}"
    
    opt_name=$(echo "$selected_data" | cut -d'|' -f1)
    opt_type=$(echo "$selected_data" | cut -d'|' -f2)
    opt_target=$(echo "$selected_data" | cut -d'|' -f3)
    opt_filename=$(echo "$selected_data" | cut -d'|' -f4)

    echo -e "\n${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${INFO} ${WHITE}Selected Module: ${BOLD}${YELLOW}$opt_name${RESET} 🎯"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"

    if [[ "$opt_type" == "script" ]]; then
        echo -e "${LOADING} ${CYAN}Executing external script... ⚙️${RESET}"
        eval "$opt_target"
        
    elif [[ "$opt_type" == "blueprint" ]]; then
        cd "$PTERODACTYL_DIR" || exit 1
        echo -e "${LOADING} ${CYAN}Downloading blueprint: ${WHITE}$opt_filename${RESET} 📥"
        wget -qO "$opt_filename" "$opt_target"
        
        if [ $? -eq 0 ]; then
            echo -e "${LOADING} ${CYAN}Installing via Blueprint core... 🛠️${RESET}"
            blueprint -install "${opt_filename%.blueprint}"
            rm -f "$opt_filename"
            echo -e "\n${SUCCESS} ${GREEN}$opt_name Blueprint installed successfully! 🎉${RESET}"
        else
            echo -e "${ERROR} ${RED}Failed to download $opt_filename. ❌${RESET}"
        fi

    elif [[ "$opt_type" == "zip" ]]; then
        echo -e "${LOADING} ${CYAN}Preparing workspace for $opt_name... 🧹${RESET}"
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR" || exit 1
        
        echo -e "${LOADING} ${CYAN}Downloading package... 📥${RESET}"
        wget -qO "$opt_filename" "$opt_target"
        
        if [ $? -eq 0 ]; then
            echo -e "${LOADING} ${CYAN}Extracting files... 📦${RESET}"
            unzip -oq "$opt_filename"
            
            BP_FILE=$(find . -name "*.blueprint" | head -n 1)
            
            if [ -n "$BP_FILE" ]; then
                echo -e "${SUCCESS} ${GREEN}Found embedded blueprint: ${WHITE}$BP_FILE${RESET} 🔍"
                mv "$BP_FILE" "$PTERODACTYL_DIR/"
                cd "$PTERODACTYL_DIR" || exit 1
                
                BP_BASENAME=$(basename "$BP_FILE")
                echo -e "${LOADING} ${CYAN}Installing via Blueprint... 🛠️${RESET}"
                blueprint -install "${BP_BASENAME%.blueprint}"
                rm -f "$BP_BASENAME"
                echo -e "\n${SUCCESS} ${GREEN}$opt_name installed successfully! 🎉${RESET}"
            else
                echo -e "${WARN} ${YELLOW}No blueprint found. Starting manual integration... 🔧${RESET}"
                cp -rfT . "$PTERODACTYL_DIR"
                cd "$PTERODACTYL_DIR" || exit 1
                
                echo -e "${LOADING} ${CYAN}Building panel assets (This might take a moment) ☕...${RESET}"
                export NODE_OPTIONS=--openssl-legacy-provider
                yarn install > /dev/null 2>&1
                yarn build:production
                php artisan optimize:clear
                
                echo -e "\n${SUCCESS} ${GREEN}$opt_name manual addon installed successfully! 🎉${RESET}"
            fi
        else
            echo -e "${ERROR} ${RED}Failed to download package. ❌${RESET}"
            cd "$PTERODACTYL_DIR" || exit 1
        fi
        rm -rf "$TEMP_DIR"
    fi

    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -n -e "${BOLD}${YELLOW}  👉 Press ENTER to return to the main menu...${RESET}" 
    read
done
