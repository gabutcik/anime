#!/bin/bash
# INI GRATIS KOK, SILAHKAN BOLEH DIMODIFIKASI LAGI

BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CHANNEL_ID="UCVg6XW6LiG8y7ZP5l9nN3Rw"
MAX_RESULTS=20
ANICHIN_DOMAIN="https://anichin.cafe"

# Fungsi untuk mencari di Muse Indonesia (YouTube)
search_muse() {
    local query="$1"
    echo -e "${CYAN}[~] Mencari \"$query\" di Muse Indonesia...${RESET}"

    mapfile -t lines < <(
        yt-dlp --flat-playlist --skip-download --quiet \
               "ytsearch${MAX_RESULTS}:${query} site:youtube.com/c/${CHANNEL_ID}" \
               --print "%(title)s|%(id)s"
    )

    [[ ${#lines[@]} -eq 0 ]] && {
        echo -e "${RED}[!] Tidak ditemukan.${RESET}"; return 1
    }

    echo -e "\n${GREEN}[+] Ditemukan ${#lines[@]} hasil:${RESET}"
    for i in "${!lines[@]}"; do
        printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${lines[$i]%%|*}"
    done

    read -rp "${YELLOW}[?] Pilih [1-${#lines[@]}]: ${RESET}" ch
    [[ ! "$ch" =~ ^[0-9]+$ ]] || (( ch<1 || ch>${#lines[@]} )) && {
        echo -e "${RED}[!] Pilihan tidak valid.${RESET}"; return 1
    }

    video_id="${lines[$((ch-1))]##*|}"
    url="https://www.youtube.com/watch?v=${video_id}"
    choose_action "$url"
}

# Fungsi untuk mencari di Anichin
search_anichin() {
    local keyword="$1"
    local tmp="/tmp/anichin.html"
    echo -e "${CYAN}[~] Mencari \"$keyword\" di Anichin...${RESET}"

    curl -sL "${ANICHIN_DOMAIN}/?s=${keyword// /+}" > "$tmp"

    mapfile -t lines < <(
        pup 'div.animepost a attr{href}' < "$tmp" | paste -d "|" - <(
            pup 'div.animepost .title text{}' < "$tmp"
        )
    )

    [[ ${#lines[@]} -eq 0 ]] && {
        echo -e "${RED}[!] Tidak ditemukan di Anichin.${RESET}"; return 1
    }

    echo -e "\n${GREEN}[+] Ditemukan ${#lines[@]} hasil:${RESET}"
    for i in "${!lines[@]}"; do
        printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${lines[$i]##*|}"
    done

    read -rp "${YELLOW}[?] Pilih [1-${#lines[@]}]: ${RESET}" ch
    [[ ! "$ch" =~ ^[0-9]+$ ]] || (( ch<1 || ch>${#lines[@]} )) && {
        echo -e "${RED}[!] Pilihan tidak valid.${RESET}"; return 1
    }

    url="${lines[$((ch-1))]%%|*}"
    choose_action "$url"
}

# Fungsi pilih aksi: stream / download / resolusi
choose_action() {
    local url="$1"
    echo -e "\n${YELLOW}[?] Mau apa nih?${RESET}"
    echo "1) Streaming"
    echo "2) Download"
    read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" act

    case "$act" in
        1)
            choose_player "$url"
            ;;
        2)
            choose_res "$url" "download"
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid.${RESET}"
            ;;
    esac
}

# Pilih player
choose_player() {
    local url="$1"
    echo -e "\n${YELLOW}[?] Player apa?${RESET}"
    echo "1) mpv"
    echo "2) vlc"
    read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" pl

    case "$pl" in
        1)
            choose_res "$url" "mpv"
            ;;
        2)
            choose_res "$url" "vlc"
            ;;
        *)
            echo -e "${RED}[!] Pilihan tidak valid.${RESET}"
            ;;
    esac
}

# Pilih resolusi
choose_res() {
    local url="$1"
    local mode="$2"
    echo -e "\n${CYAN}[~] Cek resolusi tersedia...${RESET}"

    mapfile -t res_list < <(
        yt-dlp -F "$url" | grep -E "^\d+\s" | awk '{print $1 " " $3}'
    )

    [[ ${#res_list[@]} -eq 0 ]] && {
        echo -e "${RED}[!] Gagal ambil resolusi, pakai default.${RESET}"
        res="best"
    } || {
        echo -e "\n${GREEN}[+] Pilih resolusi:${RESET}"
        for i in "${!res_list[@]}"; do
            printf "${BOLD}%2d${RESET}. %s\n" "$((i+1))" "${res_list[$i]}"
        done
        read -rp "${YELLOW}[?] Pilih [1-${#res_list[@]}] atau tekan Enter untuk 'best': ${RESET}" r
        [[ "$r" =~ ^[0-9]+$ ]] && (( r>=1 && r<=${#res_list[@]} )) \
            && res="${res_list[$((r-1))]%% *}" \
            || res="best"
    }

    case "$mode" in
        mpv)
            mpv --no-terminal --ytdl-format="$res" "$url"
            ;;
        vlc)
            vlc "$url" --ytdl-format="$res"
            ;;
        download)
            echo -e "${GREEN}[+] Downloading...${RESET}"
            yt-dlp -f "$res" -o "%(title)s.%(ext)s" "$url"
            ;;
    esac
}

# Menu utama
echo -e "${CYAN}╭──────────────────────────────────────────────╮"
echo -e "│        ${BOLD}PENCARIAN ANIMEK & DONGHUA${RESET}${CYAN}        │"
echo -e "╰──────────────────────────────────────────────╯${RESET}"

echo -e "${YELLOW}Pilih sumber:${RESET}"
echo "1) Muse Indonesia (YouTube)"
echo "2) Anichin"
read -rp "${YELLOW}[?] Pilih [1-2]: ${RESET}" src

read -rp "${YELLOW}[?] Masukkan judul: ${RESET}" q
[[ -z "$q" ]] && { echo -e "${RED}[!] Judul tidak boleh kosong.${RESET}"; exit 1; }

case "$src" in
    1) search_muse "$q" ;;
    2) search_anichin "$q" ;;
    *) echo -e "${RED}[!] Pilihan tidak valid.${RESET}" ;;
esac
