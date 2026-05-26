#!/bin/sh
CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
TARGET_DIR="$HOME/tv"; SCRIPT_PATH="$0"
cleanup() {
    trap - EXIT INT TERM HUP QUIT
    echo "${YELLOW}\n[!] Đang dọn dẹp hệ thống...${NC}"
    [ -d "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"
    [ -f "$SCRIPT_PATH" ] && rm -f "$SCRIPT_PATH"
    pkill -9 adb >/dev/null 2>&1; exit 0
}
trap cleanup EXIT INT TERM HUP QUIT
clear
echo "${CYAN}${BOLD}=========================================="
echo "${YELLOW}        VIỆT XIAOMI - 0343.22.08.93"
echo "${CYAN}==========================================${NC}"
echo "${BLUE}[1/3] Đang cấu hình cài đặt...${NC}"
apk update && apk add android-tools git bash coreutils curl nmap openssl && apk upgrade
echo "\n${BLUE}[2/3] Đang tải dữ liệu từ Việt Xiaomi...${NC}"
[ -d "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"

REPO_URL="https://github.com"

if git clone --depth 1 "$REPO_URL" "$TARGET_DIR"; then
    echo -e "\n${GREEN}[✓] Tải dữ liệu mới nhất thành công!${NC}"
else
    echo -e "\n${RED}${BOLD}[!] LỖI: Kết nối thất bại hoặc sai link...${NC}"
    exit 1
fi
if [ -d "$TARGET_DIR" ]; then
    echo "${BLUE}[3/3] Đang chuẩn bị khởi chạy...${NC}"
    cd "$TARGET_DIR" || exit 1
    MAIN_SCRIPT="$TARGET_DIR/ios/1.sh"
    if [ -f "$MAIN_SCRIPT" ]; then
        sed -i 's/\r$//' "$MAIN_SCRIPT" && chmod +x "$MAIN_SCRIPT"
        echo "${CYAN}${BOLD}>>> BẮT ĐẦU CÀI ĐẶT HỆ THỐNG...${NC}"
        sleep 2
        trap - EXIT INT TERM HUP QUIT
        [ -f "$SCRIPT_PATH" ] && rm -f "$SCRIPT_PATH"
        exec bash "$MAIN_SCRIPT"
    else
        echo -e "\n${RED}${BOLD}[!] LỖI: Không tìm thấy file 1.sh trong thư mục ios!${NC}"
        exit 1
    fi
else
    echo -e "\n${RED}${BOLD}[!] LỖI: Không tìm thấy thư mục cài đặt!${NC}"
    exit 1
fi
