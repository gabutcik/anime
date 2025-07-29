#!/bin/bash
# anime.sh – anime & donghua downloader / streamer
# INI GRATIS, SILAHKAN DIMODIFIKASI

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CHANNEL_ID="UCVg6XW6LiG8y7ZP5l9nN3Rw"
MAX_RESULTS=20
ANICHIN_DOMAINS=("https://anichin.cafe" "https://anichin.team")
TMP_DIR="$HOME/tmp"
[[ -d "$TMP_DIR" ]] || mkdir -p "$TMP_DIR"

# ─────────────────────────────────────────────
# 1) YouTube (Muse Indonesia)
search_muse() {
    local q="$1"
    echo -e "${CYAN}[~] Mencari \"$q\" di Muse Indonesia...${RESET}"
    mapfile -t lines < <(
        yt-dlp --flat-playlist --skip-download --quiet \
               "ytsearch${MAX_RESULTS}:${q} site:youtube.com/c/${CHANNEL_ID}" \
               --print "%(title)s|%(id)s"
    )
    [[ ${#lines[@]} -eq 0 ]] && { echo -e "${RED}[!] Tidak ditemukan.${RESET}"; return 1; }

    for i in "${!lines[@]}"; do printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${lines[$i]%%|*}"; done
    read -rp "${YELLOW}[?] Pilih [1-${#lines[@]}]: ${RESET}" ch
    [[ ! "$ch" =~ ^[0-9]+$ ]] || (( ch<1 || ch>${#lines[@]} )) && { echo -e "${RED}[!] Pilihan tidak valid.${RESET}"; return 1; }
    id="${lines[$((ch-1))]##*|}"
    url="https://www.youtube.com/watch?v=$id"
    choose_action "$url"
}

# ─────────────────────────────────────────────
# 2) Anichin – ambil link & proses
search_anichin() {
    local q="$1"
    local html="$TMP_DIR/anichin.html"
    for dom in "${ANICHIN_DOMAINS[@]}"; do
        echo -e "${CYAN}[~] Mencari \"$q\" di $dom...${RESET}"
        curl -sL "$dom/?s=${q// /+}" > "$html"
        mapfile -t lines < <(
            pup 'div.animepost a attr{href}' < "$html" | paste -d "|" - <(
                pup 'div.animepost .title text{}' < "$html"
            )
        )
        [[ ${#lines[@]} -gt 0 ]] && break
    done
    [[ ${#lines[@]} -eq 0 ]] && { echo -e "${RED}[!] Tidak ditemukan di Anichin.${RESET}"; return 1; }

    for i in "${!lines[@]}"; do printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${lines[$i]##*|}"; done
    read -rp "${YELLOW}[?] Pilih [1-${#lines[@]}]: ${RESET}" ch
    [[ ! "$ch" =~ ^[0-9]+$ ]] || (( ch<1 || ch>${#lines[@]} )) && { echo -e "${RED}[!] Pilihan tidak valid.${RESET}"; return 1; }
    url="${lines[$((ch-1))]%%|*}"
    choose_action "$url"
}

# ─────────────────────────────────────────────
# 3) Pilih aksi
choose_action() {
    local url="$1"
    echo -e "\n${YELLOW}[?] Mau apa nih?${RESET}"
    echo "1) Streaming"
    echo "2) Download"
    read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" act
    case "$act" in
        1) choose_player "$url" ;;
        2) choose_res "$url" "download" ;;
        *) echo -e "${RED}[!] Pilihan tidak valid.${RESET}" ;;
    esac
}

# 4) Pilih player
choose_player() {
    local url="$1"
    echo -e "\n${YELLOW}[?] Player apa?${RESET}"
    echo "1) mpv"
    echo "2) vlc"
    read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" pl
    case "$pl" in
        1) choose_res "$url" "mpv" ;;
        2) choose_res "$url" "vlc" ;;
        *) echo -e "${RED}[!] Pilihan tidak valid.${RESET}" ;;
    esac
}

# 5) Pilih resolusi
choose_res() {
    local url="$1" mode="$2"
    echo -e "\n${CYAN}[~] Cek format/resolusi...${RESET}"
    mapfile -t res_list < <(yt-dlp -F "$url" 2>/dev/null | grep -E "^\d+\s" | awk '{print $1 " " $3}')
    [[ ${#res_list[@]} -eq 0 ]] && res="best" || {
        echo -e "\n${GREEN}[+] Pilih format/resolusi:${RESET}"
        for i in "${!res_list[@]}"; do printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${res_list[$i]}"; done
        read -rp "${YELLOW}[?] Pilih [1-${#res_list[@]}] atau Enter untuk 'best': ${RESET}" r
        [[ "$r" =~ ^[0-9]+$ ]] && (( r>=1 && r<=${#res_list[@]} )) && res="${res_list[$((r-1))]%% *}" || res="best"
    }
    case "$mode" in
        mpv) mpv --no-terminal --ytdl-format="$res" "$url" ;;
        vlc) vlc "$url" --ytdl-format="$res" ;;
        download) yt-dlp -f "$res" -o "%(title)s.%(ext)s" "$url" ;;
    esac
}

# ─────────────────────────────────────────────
# Menu utama
echo -e "${CYAN}╭──────────────────────────────────────────────╮"
echo -e "│        ${BOLD}PENCARIAN ANIMEK & DONGHUA${RESET}${CYAN}        │"
echo -e "╰──────────────────────────────────────────────╯${RESET}"

echo -e "${YELLOW}Pilih sumber:${RESET}"
echo "1) Muse Indonesia (YouTube)"
echo "2) Anichin"
read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" src

read -rp "${YELLOW}[?] Judul: ${RESET}" q
[[ -z "$q" ]] && { echo -e "${RED}[!] Judul tidak boleh kosong.${RESET}"; exit 1; }

case "$src" in
    1) search_muse "$q" ;;
    2) search_anichin "$q" ;;
    *) echo -e "${RED}[!] Pilihan tidak valid.${RESET}" ;;
esac
