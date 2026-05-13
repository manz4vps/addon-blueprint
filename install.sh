#!/bin/bash

# ==========================================
# MANZ4VPS PTERODACTYL ADDON INSTALLER
# ==========================================

# Terminal Colors & UI Elements
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

INFO="${CYAN}💡 [INFO]${RESET}"
SUCCESS="${GREEN}✅ [SUCCESS]${RESET}"
ERROR="${RED}❌ [ERROR]${RESET}"
WARN="${YELLOW}⚠️ [WARNING]${RESET}"
LOADING="${MAGENTA}🔄 [WORKING]${RESET}"

# ==========================================
# Configuration
# ==========================================
GITHUB_REPO="manz4vps/addon-blueprint"
BRANCH="main"
API_URL_EX="https://api.github.com/repos/${GITHUB_REPO}/contents/ex?ref=${BRANCH}"
PTERODACTYL_DIR="/var/www/pterodactyl"

# ==========================================
# Pre-flight Checks
# ==========================================
clear
echo -e "${CYAN}${BOLD}🚀 Initializing MANZ4VPS Installer...${RESET}\n"

if [[ $EUID -ne 0 ]]; then
   echo -e "${ERROR} ${RED}Script ini harus dijalankan sebagai root (gunakan sudo).${RESET}" 
   exit 1
fi

if [ ! -d "$PTERODACTYL_DIR" ]; then
    echo -e "${ERROR} ${RED}Folder Pterodactyl ($PTERODACTYL_DIR) tidak ditemukan.${RESET}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${WARN} ${YELLOW}'jq' belum terinstall. Menginstall sekarang... ⚙️${RESET}"
    apt-get update -y -q > /dev/null 2>&1 && apt-get install -y jq -q > /dev/null 2>&1
fi

# ==========================================
# Function: Eksekusi Install Blueprint
# ==========================================
install_blueprint() {
    local opt_name="$1"
    local opt_target="$2"
    local opt_filename="$3"

    echo -e "\n${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${INFO} ${WHITE}Memproses: ${BOLD}${YELLOW}$opt_name${RESET}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"

    cd "$PTERODACTYL_DIR" || return
    echo -e "${LOADING} ${CYAN}Mendownload: ${WHITE}$opt_filename${RESET} 📥"
    
    if wget -qO "$opt_filename" "$opt_target"; then
        echo -e "${LOADING} ${CYAN}Menginstall via Blueprint... 🛠️${RESET}"
        if blueprint -install "${opt_filename%.blueprint}"; then
            echo -e "${SUCCESS} ${GREEN}$opt_name berhasil diinstall! 🎉${RESET}"
            rm -f "$opt_filename"
        else
            echo -e "${ERROR} ${RED}Gagal menginstall $opt_name via blueprint! ❌${RESET}"
        fi
    else
        echo -e "${ERROR} ${RED}Gagal mendownload $opt_filename dari GitHub. ❌${RESET}"
    fi
}

# ==========================================
# Function: Fetch & Prepare List
# ==========================================
fetch_and_prepare_list() {
    echo -e "\n${INFO} ${CYAN}Menyinkronkan addon dari GitHub... ☁️${RESET}"
    
    FILES_JSON_EX=$(curl -s "$API_URL_EX")

    if echo "$FILES_JSON_EX" | grep -q '"message":'; then
        echo -e "${ERROR} ${RED}Gagal mengambil data dari GitHub API. Cek kembali repo kamu. 🛑${RESET}"
        sleep 2
        return
    fi

    ALL_OPTIONS=()
    SORTED_OPTIONS=()

    if echo "$FILES_JSON_EX" | grep -q '"name":'; then
        while IFS= read -r line; do
            raw_name=$(echo "$line" | cut -d'|' -f1)
            url=$(echo "$line" | cut -d'|' -f2)
            clean_name="${raw_name%.blueprint}"
            clean_name="${clean_name^}"
            ALL_OPTIONS+=("$clean_name|blueprint|$url|$raw_name")
        done < <(echo "$FILES_JSON_EX" | jq -r '.[] | select(.name | endswith(".blueprint")) | "\(.name)|\(.download_url)"')
    fi

    IFS=$'\n' SORTED_OPTIONS=($(sort -f <<<"${ALL_OPTIONS[*]}"))
    unset IFS
    
    echo -e "${SUCCESS} ${GREEN}Daftar Addon berhasil dimuat! 🎉${RESET}"
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
  __  __          _   _  ______  _  _  __      __ _____   _____ 
 |  \/  |   /\   | \ | ||___  / | || | \ \    / /|  __ \ / ____|
 | \  / |  /  \  |  \| |   / /  | || |_ \ \  / / | |__) | (___  
 | |\/| | / /\ \ | . ` |  / /   |__   _| \ \/ /  |  ___/ \___ \ 
 | |  | |/ ____ \| |\  | / /__     | |    \  /   | |     ____) |
 |_|  |_/_/    \_\_| \_|/_____|    |_|     \/    |_|    |_____/ 
EOF
    echo -e "${RESET}"
    
    echo -e "${CYAN}╭──────────────────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET}                🚀 ${MAGENTA}${BOLD}MANZ4VPS - Pterodactyl Installer${RESET} 🚀                   ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET} ✨ ${WHITE}Pilih addon blueprint yang mau diinstall:${RESET}                                ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    
    count=1
    total_options=${#SORTED_OPTIONS[@]}
    
    for opt in "${SORTED_OPTIONS[@]}"; do
        disp_name=$(echo "$opt" | cut -d'|' -f1)
        icon="🧩"
        
        printf "${CYAN}│${RESET}  ${GREEN}%02d.${RESET} $icon ${WHITE}%-28s${RESET} " "$count" "${disp_name:0:28}"
        
        if (( count % 2 == 0 )); then
            echo -e "${CYAN}│${RESET}"
        elif (( count == total_options )); then
            printf "%-39s${CYAN}│${RESET}\n" " "
        fi
        
        ((count++))
    done
    
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET}  ${YELLOW}🔄 R.${RESET} ${WHITE}Refresh${RESET}      ${GREEN}🔥 A.${RESET} ${WHITE}Install Semua${RESET}      ${RED}🛑 0.${RESET} ${WHITE}Exit Installer${RESET}      ${CYAN}│${RESET}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────────╯${RESET}"
    
    echo -e "${YELLOW}  💡 Tips: Bisa pilih banyak sekaligus pakai spasi (Contoh: 1 3 4)${RESET}"
    echo -n -e "${BOLD}${MAGENTA}  👉 Masukkan Pilihanmu: ${RESET}"
    read choices

    # Fitur Exit
    if [[ "$choices" == "0" || "$choices" == "00" ]]; then
        echo -e "\n${SUCCESS} ${GREEN}Exiting. Have a great day, Bro! 👋${RESET}\n"
        exit 0
    fi

    # Fitur Refresh
    if [[ "${choices,,}" == "r" ]]; then
        fetch_and_prepare_list
        continue
    fi

    # Fitur Install Semua (ALL)
    if [[ "${choices,,}" == "a" || "${choices,,}" == "all" ]]; then
        echo -e "\n${YELLOW}🚀 GASKEUN INSTALL SEMUA ADDON...${RESET}"
        for opt in "${SORTED_OPTIONS[@]}"; do
            opt_name=$(echo "$opt" | cut -d'|' -f1)
            opt_target=$(echo "$opt" | cut -d'|' -f3)
            opt_filename=$(echo "$opt" | cut -d'|' -f4)
            install_blueprint "$opt_name" "$opt_target" "$opt_filename"
        done
        echo -e "\n${SUCCESS} ${GREEN}✅ SEMUA PROSES SELESAI!${RESET}"
        echo -n -e "${BOLD}${YELLOW}  👉 Press ENTER untuk kembali ke menu...${RESET}" 
        read
        continue
    fi

    # Fitur Multi-Select (Spasi) atau Single Select
    valid_selection=false
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_options" ]; then
            valid_selection=true
            selected_index=$((choice-1))
            selected_data="${SORTED_OPTIONS[$selected_index]}"
            
            opt_name=$(echo "$selected_data" | cut -d'|' -f1)
            opt_target=$(echo "$selected_data" | cut -d'|' -f3)
            opt_filename=$(echo "$selected_data" | cut -d'|' -f4)
            
            install_blueprint "$opt_name" "$opt_target" "$opt_filename"
        else
            echo -e "${ERROR} ${RED}Pilihan [$choice] tidak valid! Dilewati...${RESET}"
            sleep 1
        fi
    done

    if [ "$valid_selection" = true ]; then
        echo -e "\n${SUCCESS} ${GREEN}✅ PROSES SELESAI!${RESET}"
        echo -n -e "${BOLD}${YELLOW}  👉 Press ENTER untuk kembali ke menu...${RESET}" 
        read
    fi
done
