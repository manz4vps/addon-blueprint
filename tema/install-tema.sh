#!/bin/bash

# ==========================================
# INSTALLER TEMA PREMIUM - MANZ4VPS (FIXED)
# ==========================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m'
BOLD='\033[1m'

PTERO_DIR="/var/www/pterodactyl"

# Cek Akses Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan sebagai root (gunakan sudo).${RESET}" 
   exit 1
fi

# Cek Folder Pterodactyl
if [ ! -d "$PTERO_DIR" ]; then
    echo -e "${RED}Folder Pterodactyl ($PTERO_DIR) tidak ditemukan.${RESET}"
    exit 1
fi

# Fungsi Install Tema
install_theme() {
    local THEME_NAME="$1"
    local THEME_FILE="$2"
    local THEME_URL="https://raw.githubusercontent.com/manz4vps/addon-blueprint/main/tema/$THEME_FILE"

    echo -e "\n${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${YELLOW}🚀 Memulai Instalasi Tema: ${BOLD}$THEME_NAME${RESET}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────────────────────────${RESET}"

    cd "$PTERO_DIR" || exit

    echo -e "${CYAN}[1/5] Mendownload file $THEME_FILE dari GitHub...${RESET}"
    wget -qO "$THEME_FILE" "$THEME_URL"

    if [ ! -f "$THEME_FILE" ]; then
        echo -e "${RED}❌ Gagal mendownload $THEME_FILE! Cek apakah file sudah diupload ke GitHub.${RESET}"
        return 1
    fi

    echo -e "${CYAN}[2/5] Mengekstrak file tema...${RESET}"
    apt-get install -y unzip > /dev/null 2>&1
    unzip -oq "$THEME_FILE"
    rm -f "$THEME_FILE"

    echo -e "${CYAN}[3/5] Memastikan NodeJS & Yarn terinstall (Mencegah error 'command not found')...${RESET}"
    # Install Node.js v20 dan Yarn secara otomatis
    apt-get install -y curl > /dev/null 2>&1
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null 2>&1
    npm i -g yarn > /dev/null 2>&1

    echo -e "${CYAN}[4/5] Menginstall dependencies panel (Yarn install)...${RESET}"
    yarn install > /dev/null 2>&1

    echo -e "${CYAN}[5/5] Membangun ulang panel (Proses ini butuh waktu 3-10 menit)...${RESET}"
    echo -e "${YELLOW}⚠️ JANGAN TUTUP TERMINAL SAAT PROSES INI BERJALAN! ⚠️${RESET}"

    export NODE_OPTIONS=--openssl-legacy-provider
    php artisan migrate --force
    yarn build:production
    php artisan view:clear
    php artisan optimize:clear

    # Fix Permissions biar Nginx/Apache gak Error 500
    echo -e "${CYAN}[INFO] Memperbaiki perizinan file...${RESET}"
    chown -R www-data:www-data "$PTERO_DIR"
    chmod -R 755 "$PTERO_DIR"/storage "$PTERO_DIR"/bootstrap/cache

    echo -e "\n${GREEN}✅ Instalasi Tema $THEME_NAME Selesai! Silakan refresh website panelmu.${RESET}"
    
    echo -n -e "\n${BOLD}${YELLOW}👉 Tekan ENTER untuk kembali ke menu...${RESET}" 
    read
}

# Menu Utama
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
    echo -e "${CYAN}╭──────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET}             🚀 ${BOLD}${MAGENTA}INSTALLER TEMA PREMIUM (.ZIP)${RESET} 🚀            ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}1.${RESET} 🎨 Tema Enigma (Biasa)                                  ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}2.${RESET} 💎 Tema Enigma Premium (v3.9)                           ${CYAN}│${RESET}"
    echo -e "${CYAN}│${RESET}  ${GREEN}3.${RESET} 🎨 Tema Arix                                            ${CYAN}│${RESET}"
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${CYAN}│${RESET}  ${RED}0.${RESET} Exit                                                    ${CYAN}│${RESET}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────╯${RESET}"
    
    echo -n -e "\n${BOLD}${MAGENTA}👉 Masukkan Pilihanmu [0-3]: ${RESET}"
    read choice

    case "$choice" in
        1) install_theme "Enigma (Biasa)" "enigma.zip" ;;
        2) install_theme "Enigma Premium" "enigmapremium.zip" ;;
        3) install_theme "Arix" "arix.zip" ;;
        0|00) echo -e "\n${GREEN}Keluar dari Installer. Have a good day bro! 👋${RESET}\n"; exit 0 ;;
        *) echo -e "\n${RED}Pilihan tidak valid! Coba lagi.${RESET}"; sleep 1 ;;
    esac
done
