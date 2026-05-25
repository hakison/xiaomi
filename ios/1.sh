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

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Không tìm thấy thư mục: $SOURCE_DIR${NC}"
    echo "👉 Copy APK vào: Files → iSH → mi"
    exit 1
fi

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
        echo "2. Cài đặt tất cả ứng dụng (.apk) từ thư mục xiaomi"
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

# Cài đặt Projectivy Launcher và các app đi kèm
install_projectivy() {
    
   $ADB_COMMAND shell service call alarm 3 s16 Asia/Bangkok >/dev/null 2>&1

   $ADB_COMMAND shell settings put global device_locales vi-VN >/dev/null 2>&1

   $ADB_COMMAND shell settings put global sys_locale vi-VN >/dev/null 2>&1

   $ADB_COMMAND shell settings put system system_locales vi-VN >/dev/null 2>&1

   $ADB_COMMAND shell settings put global heads_up_notifications_enabled 0 >/dev/null 2>&1

   $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1

   echo "🚀 Bắt đầu cài đặt Projectivy Launcher..."
    
   echo "Đang chạy p.apk ..." >/dev/null 2>&1
    install_apk "p.apk" >/dev/null 2>&1

   
   
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

    # Danh sách các app phụ trợ cần cài
    local apks_to_install=(
        "mstore.apk" "keyboard.apk" "katniss_2.2.0.apk" "dl.apk" 
        "an.apk" "youtube.apk" "cotivi.apk" "imedia.apk"
    )

    echo "🚀 Bắt đầu cài đặt các ứng dụng phụ trợ..." >/dev/null 2>&1
    for apk in "${apks_to_install[@]}"; do
        install_apk "$apk"
    done
    
    $ADB_COMMAND shell pm grant com.mitv.shareds android.permission.WRITE_SECURE_SETTINGS >/dev/null 2>&1
    $ADB_COMMAND shell pm grant com.mitv.shareds android.permission.CHANGE_CONFIGURATION >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure enabled_accessibility_services com.mitv.shareds/com.mitv.shareds.HomeService >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure accessibility_enabled 1 >/dev/null 2>&1
   
    $ADB_COMMAND shell pm grant com.spocky.projengmenu android.permission.WRITE_SECURE_SETTINGS >/dev/null 2>&1
    $ADB_COMMAND shell cmd appops set com.spocky.projengmenu READ_EXTERNAL_STORAGE allow >/dev/null 2>&1
    $ADB_COMMAND shell cmd appops set com.spocky.projengmenu WRITE_EXTERNAL_STORAGE allow >/dev/null 2>&1

    $ADB_COMMAND shell appops set com.google.android.katniss SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1
    
    $ADB_COMMAND shell ime enable com.liskovsoft.leankeyboard/.ime.LeanbackImeService >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure default_input_method com.liskovsoft.leankeyboard/.ime.LeanbackImeService >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1

    $ADB_COMMAND push projectivy.plbackup /sdcard/Download >/dev/null 2>&1

    copy_wallpapers
    echo -e "${GREEN}✅ Cài đặt Projectivy hoàn tất!${NC}"
    reboot_tv "normal"
}

# Sao chép ảnh nền vào TV
copy_wallpapers() {
    echo "🖼️ Bắt đầu chép ảnh nền (.jpg, .png) vào TV..."
    local count=0
    # Sử dụng vòng lặp for an toàn hơn với tên file có khoảng trắng
    for file in *.{jpg,jpeg,png,JPG,JPEG,PNG}; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local extension="${filename##*.}"
            echo "    -> Đang chép $filename..."
            $ADB_COMMAND push "$file" "/sdcard/DCIM_${count}.${extension}"
            count=$((count + 1))
        fi
    done

    if [ "$count" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠️ Không tìm thấy file ảnh nào.${NC}"
    else
        echo -e "${GREEN}✅ Đã chép $count ảnh vào thư mục /sdcard/DCIM/ trên TV.${NC}"
    fi
    sleep 3
}

# Cài đặt tất cả các file .apk trong thư mục nguồn
install_all_apks() {
    echo "🔧 Bắt đầu cài đặt tất cả các file .apk trong $SOURCE_DIR..."
    local apk_files=(*.apk)
    
    if [ ${#apk_files[@]} -eq 0 ] || [ ! -f "${apk_files[0]}" ]; then
        echo -e "   ${YELLOW}⚠️ Không tìm thấy file .apk nào.${NC}"
        sleep 3
        return
    fi

    for file in "${apk_files[@]}"; do
        install_apk "$file"
    done
    
    $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1
    $ADB_COMMAND shell monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
    $ADB_COMMAND shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1

    $ADB_COMMAND push projectivy.plbackup /sdcard/Download >/dev/null 2>&1


    echo -e "${GREEN}✅ Đã xử lý ${#apk_files[@]} file .apk.${NC}"
    sleep 3
    menu1
}


# Khởi động lại TV
reboot_tv() {
    local mode="$1"
    print_header
    echo "→ Reboot TV ($mode)"

    if [ "$mode" = "recovery" ]; then
        $ADB_COMMAND reboot recovery >/dev/null 2>&1 &
    else
        $ADB_COMMAND reboot >/dev/null 2>&1 &
    fi

    echo "→ Đã gửi lệnh reboot (không chờ phản hồi)"
    sleep 1

    echo "→ Ngắt kết nối ADB"
    $ADB_COMMAND disconnect >/dev/null 2>&1

    echo "→ Chờ TV khởi động lại..."
    sleep 8

    echo "→ Quay về Menu kết nối"
    sleep 1
    menu1
}

# =================== START ===================
menu1


