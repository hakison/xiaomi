#!/bin/bash

# =================== THIẾT LẬP BIẾN ===================

# Thư mục chứa APK & ảnh trong iSH (Files → iSH → mi)
SOURCE_DIR="/root/mi"

# adb trong Alpine Linux (iSH)
ADB_COMMAND="/usr/bin/adb"

# Màu hiển thị
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Huỷ bẫy trap cũ để ép iSH không báo lỗi signal specification
trap - EXIT INT TERM ERR
trap '$ADB_COMMAND disconnect >/dev/null 2>&1; exit' INT TERM

# =================== HÀM DÙNG CHUNG ===================

print_header() {
    clear
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}           Trình cài đặt S.Mihome 0946.018.018          ${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo
}

check_adb() {
    if ! $ADB_COMMAND version >/dev/null 2>&1; then
        echo -e "${RED}❌ adb chưa sẵn sàng. Hãy chạy:${NC}"
        echo "apk add android-tools bash"
        exit 1
    fi
}

install_apk() {
    local apk_file="$1"
    if [ -f "$apk_file" ]; then
        echo -e "→ Cài ${GREEN}$apk_file${NC}"
        if $ADB_COMMAND install -r -g "$apk_file"; then
            echo -e "${GREEN}✓ Thành công${NC}"
        else
            echo -e "${RED}✗ Thất bại${NC}"
        fi
    else
        echo -e "${RED}⚠ Không thấy $apk_file${NC}"
    fi
}

# =================== KIỂM TRA MÔI TRƯỜNG ===================

# Tự động tạo thư mục nếu người dùng chưa kịp tạo để tránh lỗi đứng script
[ ! -d "$SOURCE_DIR" ] && mkdir -p "$SOURCE_DIR"

cd "$SOURCE_DIR" || exit 1
check_adb

# =================== MENU 1: KẾT NỐI TV ===================

menu1() {
    while true; do
        print_header
        echo "Bật ADB Debugging trên TV Xiaomi"
        echo "TV & iPhone phải cùng Wi-Fi"
        echo

        read -p "Nhập IP TV (vd: 192.168.1.100): " RAW_IP
        [ -z "$RAW_IP" ] && continue

        DEVICE_IP="${RAW_IP}:5555"

        echo
        echo "→ Ngắt kết nối cũ"
        $ADB_COMMAND disconnect >/dev/null 2>&1

        echo "→ Kết nối tới $DEVICE_IP"
        $ADB_COMMAND connect "$DEVICE_IP"

        echo -e "${GREEN}👉 Nhấn Allow trên TV${NC}"
        sleep 8

        if $ADB_COMMAND devices | grep -q "$RAW_IP"; then
            echo -e "${GREEN}✓ Kết nối thành công${NC}"
            sleep 1
            menu2
            break
        else
            echo -e "${RED}✗ Kết nối thất bại${NC}"
            sleep 3
        fi
    done
}

# =================== MENU 2 ===================

menu2() {
    while true; do
        print_header
        echo -e "TV đang kết nối tại: ${GREEN}$DEVICE_IP${NC}"
        echo
        echo "-- Cài đặt giao diện --"
        echo "1. Cài Launcher PROJECTIVY"
        echo "--------------------------"
        echo "2. Cài đặt tất cả ứng dụng (.apk) từ thư mục mi"
        echo "3. Chép tất cả ảnh nền (.jpg, .png) vào TV"
        echo "4. Khởi động lại TV (Reboot)"
        echo "5. Khởi động vào Recovery"
        echo "6. Ngắt và kết nối lại TV khác"
        echo "0. Thoát"
        echo

        read -p "→ Nhập tùy chọn của bạn [0-6]: " CHOICE

        case $CHOICE in
            1) install_projectivy ;;
            2) install_all_apks ;;
            3) copy_wallpapers ;;
            4) reboot_tv "normal" ;;
            5) reboot_tv "recovery" ;;
            6) menu1; break ;; 
            0) echo "👋 Tạm biệt!"; exit 0 ;;
            *) echo -e "${YELLOW}⚠️ Lựa chọn không hợp lệ, vui lòng chọn lại.${NC}"; sleep 2 ;;
        esac
    done
}

# =================== CHỨC NĂNG ===================

install_projectivy() {
   $ADB_COMMAND shell service call alarm 3 s16 Asia/Bangkok >/dev/null 2>&1
   $ADB_COMMAND shell settings put global device_locales vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put global sys_locale vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put system system_locales vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put global heads_up_notifications_enabled 0 >/dev/null 2>&1
   $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1

   echo "🚀 Bắt đầu cài đặt Projectivy Launcher..."
   install_apk "p.apk"
   
   $ADB_COMMAND shell monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
   $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
   $ADB_COMMAND shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1

   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.tvhome >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.android.tv.settings >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.tweather >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.screensaver >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.shop >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.duokan.videodaily >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.tv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.cloudcontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.miui.tv.analytics >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.voicecontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.upgrade >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.appstore >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.calendar >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.handbook >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.wakeupservice >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.screenrecorder >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.droidlogic.imageplayer >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.sohu.inputmethod.sogou.tv >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.karaoke.service >/dev/null 2>&1
   
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.tvhome >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.android.tv.settings >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.tweather >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.screensaver >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.shop >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.duokan.videodaily >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.tv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.cloudcontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.miui.tv.analytics >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.voicecontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.upgrade >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.appstore >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.calendar >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.handbook >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.wakeupservice >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.screenrecorder >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.droidlogic.imageplayer >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.sohu.inputmethod.sogou.tv >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.karaoke.service >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.tvmanager >/dev/null 2>&1

    # Danh sách ứng dụng phụ trợ tự cài
    local apks_to_install=("mstore.apk" "keyboard.apk" "youtube.apk" "imedia.apk")
    echo "🚀 Cài các app phụ trợ..."
    for apk in "${apks_to_install[@]}"; do
        install_apk "$apk"
    done
    echo -e "${GREEN}✓ Hoàn tất cấu hình Launcher!${NC}"
    sleep 2
}

install_all_apks() {
    print_header
    echo "🔄 Đang quét và cài tất cả file .apk..."
    local count=0
    for file in *.apk; do
        if [ -f "$file" ]; then
            install_apk "$file"
            count=$((count+1))
        fi
    done
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}⚠ Không tìm thấy file .apk nào trong /root/mi${NC}"
    else
        echo -e "${GREEN}✓ Đã cài đặt xong $count ứng dụng.${NC}"
    fi
    sleep 3
}

copy_wallpapers() {
    print_header
    echo "🔄 Đang chép ảnh nền sang TV (/sdcard/Pictures)..."
    local count=0
    for ext in jpg jpeg png; do
        for file in *.$ext *.${ext^^}; do
            if [ -f "$file" ]; then
                echo "-> Đang chép $file"
                $ADB_COMMAND push "$file" "/sdcard/Pictures/"
                count=$((count+1))
            fi
        done
    done
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}⚠ Không tìm thấy file ảnh .jpg hoặc .png nào.${NC}"
    else
        echo -e "${GREEN}✓ Đã chép thành công $count ảnh nền.${NC}"
    fi
    sleep 3
}

reboot_tv() {
    local mode="$1"
    print_header
    if [ "$mode" = "recovery" ]; then
        echo -e "${YELLOW}⚡ TV đang khởi động vào Recovery...${NC}"
        $ADB_COMMAND reboot recovery
    else
        echo -e "${GREEN}🔄 TV đang khởi động lại bình thường...${NC}"
        $ADB_COMMAND reboot
    fi
    sleep 3
}

# =================== KHỞI CHẠY ===================
menu1