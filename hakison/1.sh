#!/bin/bash

# =================== THIẾT LẬP BIẾN VÀ HÀM ===================

# Thư mục chứa file APK và ảnh trên điện thoại/máy tính bảng
# Termux truy cập bộ nhớ trong qua đường dẫn này sau khi được cấp quyền
SOURCE_DIR="/sdcard/Download/Zalo"
ADB_COMMAND="adb"

# Thêm màu sắc để dễ nhìn hơn
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Hàm in tiêu đề cho các menu
print_header() {
    clear
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}                Trình cài đặt S.Mihome                 ${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo
}

# Hàm kiểm tra kết nối internet
check_internet() {
    echo -e "🔄 Đang kiểm tra kết nối Internet..."
    if ! ping -c 1 google.com &>/dev/null; then
        echo -e "${RED}❌ Không có kết nối Internet! Vui lòng kiểm tra lại mạng.${NC}"
        sleep 3
        exit 1
    fi
    echo -e "${GREEN}✅ Có kết nối Internet.${NC}"
    sleep 1
}

# Hàm cài đặt một file APK và kiểm tra kết quả
install_apk() {
    local apk_file=$1
    if [ -f "$apk_file" ]; then
        echo -e "    -> Đang cài ${YELLOW}$apk_file${NC}..."
        # Cài đặt và kiểm tra mã thoát
        if $ADB_COMMAND install -r -g "$apk_file"; then
            echo -e "    ${GREEN}✅ Cài đặt $apk_file thành công.${NC}"
        else
            echo -e "    ${RED}❌ Cài đặt $apk_file thất bại.${NC}"
        fi
    else
        echo -e "    ${YELLOW}⚠️ Không tìm thấy file $apk_file, bỏ qua.${NC}"
    fi
}

# =================== BẮT ĐẦU KỊCH BẢN ===================

# 1. KIỂM TRA MÔI TRƯỜNG
# Kiểm tra xem Termux đã được cấp quyền truy cập bộ nhớ chưa
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}❌ Không tìm thấy thư mục nguồn: $SOURCE_DIR${NC}"
    echo -e "   Vui lòng chạy lệnh 'termux-setup-storage' và cấp quyền cho Termux."
    sleep 5
    exit 1
fi

# Chuyển vào thư mục làm việc để dễ dàng tìm file
cd "$SOURCE_DIR" || exit

check_internet

# 2. MENU 1: KẾT NỐI VỚI TV
menu1() {
    while true; do
        print_header
        echo "Hướng dẫn kết nối ADB với TV Xiaomi:"
        echo "1. Vào Cài đặt -> Giới thiệu -> Nhấn vào 'Build number' 5-7 lần."
        echo "2. Quay lại Cài đặt -> Tùy chọn nhà phát triển."
        echo "3. Bật 'ADB Debugging' (Gỡ lỗi ADB)."
        echo "4. Đảm bảo TV và điện thoại đang kết nối chung một mạng Wi-Fi."
        echo

        read -p "Nhập địa chỉ IP của TV (vd: 192.168.1.100): " RAW_IP

        if [[ -z "$RAW_IP" ]]; then
            echo -e "${RED}❌ Bạn chưa nhập IP. Vui lòng thử lại.${NC}"
            sleep 2
            continue
        fi

        DEVICE_IP="${RAW_IP}:5555"

        echo "🔄 Đang ngắt kết nối cũ (nếu có)..."
        $ADB_COMMAND disconnect &>/dev/null
        sleep 1

        echo "🔄 Đang kết nối tới $DEVICE_IP..."
        # Hiển thị lỗi nếu có
        connection_output=$($ADB_COMMAND connect "$DEVICE_IP")
        echo "$connection_output"

        echo -e "${YELLOW}📺 Vui lòng nhấn 'Allow' hoặc 'Cho phép' trên màn hình TV...${NC}"
        sleep 8 # Thời gian chờ người dùng xác nhận trên TV

        # Kiểm tra kết nối
        if $ADB_COMMAND devices | grep -q "$RAW_IP.*device"; then
            echo -e "${GREEN}✅ Kết nối thành công tới $DEVICE_IP!${NC}"
            sleep 1
            preview_files # Hiển thị file để xác nhận
            menu2 # Chuyển sang menu chính
            break
        else
            echo -e "${RED}❌ Kết nối thất bại.${NC}"
            echo -e "   • Kiểm tra lại IP, đảm bảo đã bật ADB Debugging và xác nhận trên TV."
            sleep 4
        fi
    done
}

# 3. MENU 2: MENU CHỨC NĂNG CHÍNH
menu2() {
    while true; do
        print_header
        echo -e "TV đang kết nối tại: ${GREEN}$DEVICE_IP${NC}"
        echo
        echo "-- Cài đặt giao diện --"
        echo "1. Cài Launcher PROJECTIVY"
        echo "--------------------------"
        echo "2. Cài đặt tất cả ứng dụng (.apk) từ thư mục Download"
        echo "3. Chép tất cả ảnh nền (.jpg, .png) vào TV"
        echo "4. Khởi động lại TV (Reboot)"
        echo "5. Khởi động vào Recovery"
        echo "6. Ngắt và kết nối lại TV khác"
        echo "0. Thoát"
        echo

        read -p "→ Nhập tùy chọn của bạn [0-7]: " CHOICE

        case $CHOICE in
            1) install_projectivy ;;
            2) install_all_apks ;;
            3) copy_wallpapers ;;
            4) reboot_tv "normal" ;;
            5) reboot_tv "recovery" ;;
            6) menu1; break ;; # Quay lại menu1 để kết nối lại
            0) echo "👋 Tạm biệt!"; exit 0 ;;
            *) echo -e "${YELLOW}⚠️ Lựa chọn không hợp lệ, vui lòng chọn lại.${NC}"; sleep 2 ;;
        esac
    done
}

# =================== CÁC HÀM CHỨC NĂNG ===================

# Cài đặt Projectivy Launcher và các app đi kèm
install_projectivy() {


   $ADB_COMMAND shell service call alarm 3 s16 Asia/Bangkok >/dev/null 2>&1
   $ADB_COMMAND shell settings put global device_locales vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put global sys_locale vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put system system_locales vi-VN >/dev/null 2>&1
   $ADB_COMMAND shell settings put global heads_up_notifications_enabled 0 >/dev/null 2>&1
   $ADB_COMMAND shell settings put global stay_on_while_plugged_in 3 >/dev/null 2>&1
    
    
    echo "Đang chạy p.apk ..." >/dev/null 2>&1
    install_apk -g "p.apk" >/dev/null 2>&1

   
   

   

   $ADB_COMMAND shell monkey -p com.spocky.projengmenu -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
   $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
   $ADB_COMMAND shell cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1
   

   

   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.tvhome >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.tvhome >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.android.tv.settings >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.tvqs >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.tweather >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.screensaver >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.shop >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.duokan.videodaily >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.tv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.mitv.cloudcontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.miui.tv.analytics >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.smarthome.tv >/dev/null 2>&1
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
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.wfdsinkhelperservice >/dev/null 2>&1
   $ADB_COMMAND shell pm disable-user --user 0 com.xiaomi.mitv.tvpush.tvpushservice >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.tvhome >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.android.tv.settings >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.tvqs >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.tweather >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.screensaver >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.shop >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.duokan.videodaily >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.tv.gallery >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.mitv.cloudcontrol >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.miui.tv.analytics >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.smarthome.tv >/dev/null 2>&1
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
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.wfdsinkhelperservice >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.tvpush.tvpushservice >/dev/null 2>&1
   $ADB_COMMAND shell pm uninstall --user 0 com.xiaomi.mitv.tvmanager >/dev/null 2>&1

    # Danh sách các app phụ trợ cần cài
    local apks_to_install=(
        "mstore.apk" "keyboard.apk" "katniss_2.2.0.apk"
        "an.apk" "youtube.apk" "rophim.apk" "cotivi.apk" "imedia.apk"
    )

    echo "🚀 Bắt đầu cài đặt các ứng dụng phụ trợ..."
    for apk in "${apks_to_install[@]}"; do
        install_apk "$apk"
    done
    

    copy_wallpapers
    adb push projectivy.plbackup /sdcard/Download
     
    $ADB_COMMAND shell pm grant com.mitv.shareds android.permission.WRITE_SECURE_SETTINGS >/dev/null 2>&1
    $ADB_COMMAND shell pm grant com.mitv.shareds android.permission.CHANGE_CONFIGURATION >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure enabled_accessibility_services com.mitv.shareds/com.mitv.shareds.HomeService >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure accessibility_enabled 1 >/dev/null 2>&1

    $ADB_COMMAND shell pm grant com.spocky.projengmenu android.permission.WRITE_SECURE_SETTINGS >/dev/null 2>&1
    $ADB_COMMAND shell cmd appops set com.spocky.projengmenu MANAGE_EXTERNAL_STORAGE allow >/dev/null 2>&1
    $ADB_COMMAND shell cmd appops set com.spocky.projengmenu READ_EXTERNAL_STORAGE allow >/dev/null 2>&1
    $ADB_COMMAND shell cmd appops set com.spocky.projengmenu WRITE_EXTERNAL_STORAGE allow >/dev/null 2>&1
    $ADB_COMMAND shell appops set com.google.android.katniss SYSTEM_ALERT_WINDOW allow >/dev/null 2>&1
    $ADB_COMMAND shell ime enable com.liskovsoft.leankeyboard/.ime.LeanbackImeService >/dev/null 2>&1
    $ADB_COMMAND shell settings put secure default_input_method com.liskovsoft.leankeyboard/.ime.LeanbackImeService >/dev/null 2>&1
    $ADB_COMMAND shell am start -n com.spocky.projengmenu/.ui.home.MainActivity >/dev/null 2>&1



    echo -e "${GREEN}✅ Cài đặt Projectivy hoàn tất!${NC}"
    reboot_tv "normal"
}

# Khởi động lại TV
reboot_tv() {
    local mode=$1 # "normal" or "recovery"
    print_header
    if [ "$mode" == "recovery" ]; then
        echo -e "${YELLOW}✅ TV sẽ khởi động lại vào chế độ RECOVERY.${NC}"
        command_to_run="reboot recovery"
    else
        echo -e "${GREEN}✅ Cài đặt hoàn tất! TV sẽ khởi động lại ngay bây giờ.${NC}"
        command_to_run="reboot"
    fi

    echo "========================================================"
    for i in {3..1}; do
        echo -ne "Khởi động lại sau $i giây... \r"
        sleep 1
    done
    echo
    echo "Đang gửi lệnh khởi động lại..."
    $ADB_COMMAND "$command_to_run"
    sleep 3
    exit 0
}

# =================== GỌI HÀM CHÍNH ===================
menu1
