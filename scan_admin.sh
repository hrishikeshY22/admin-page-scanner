#!/bin/bash
if ! command -v curl &>/dev/null; then
  echo "Error: curl is not installed. Please install curl and try again."
  exit 1
fi
usage() {
  echo "Usage: $0 -u <url> [-c concurrency] [-t timeout] [-a user_agent] [-d delay]"
  echo "   -u <url>         Target URL (include http:// or https://)"
  echo "   -c <concurrency> Number of concurrent processes (default: 10)"
  echo "   -t <timeout>     Timeout for each request in seconds (default: 5)"
  echo "   -a <user_agent>  Custom User-Agent string (optional)"
  echo "   -d <delay>       Delay in seconds between requests (default: 0)"
  echo "   -h               Show this help message"
  exit 1
}
concurrency=10
timeout=5
user_agent=""
delay=0
while getopts "u:c:t:a:d:h" opt; do
  case "$opt" in
    u) url=$OPTARG ;;
    c) concurrency=$OPTARG ;;
    t) timeout=$OPTARG ;;
    a) user_agent=$OPTARG ;;
    d) delay=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done
if [ -z "$url" ]; then
  usage
fi
echo "Checking if $url is reachable..."
if ! curl -s --head "$url" | head -n 1 | grep "HTTP/" &>/dev/null; then
  echo "Error: Unable to reach $url"
  exit 1
fi
echo -e "\033[0;32m"
LOG_FILE="scan_results.log"
HITS_FILE="admin_hits.log"
: > "$LOG_FILE"
: > "$HITS_FILE"
echo "Scanning URL: $url"
echo "Concurrency: $concurrency"
echo "Timeout: $timeout seconds"
if [ -n "$user_agent" ]; then
  echo "Custom User-Agent: $user_agent"
else
  echo "Using default User-Agent"
fi
if [ "$delay" != "0" ]; then
  echo "Delay between requests: ${delay}s"
fi
echo ""
admin_paths=(
  "admin/" "administrator/" "login.php" "administration/" "admin1/" "admin2/" "admin3/" "admin4/" "admin5/" 
  "moderator/" "webadmin/" "adminarea/" "bb-admin/" "adminLogin/" "admin_area/" "panel-administracion/" "instadmin/" 
  "memberadmin/" "administratorlogin/" "adm/" "account.asp" "admin/account.asp" "admin/index.asp" "admin/login.asp" 
  "admin/admin.asp" "login.aspx" "admin_area/admin.asp" "admin_area/login.asp" "admin/account.html" "admin/index.html" 
  "admin/login.html" "admin/admin.html" "admin_area/admin.html" "admin_area/login.html" "admin_area/index.html" 
  "admin_area/index.asp" "bb-admin/index.asp" "bb-admin/login.asp" "bb-admin/admin.asp" "bb-admin/index.html" 
  "bb-admin/login.html" "bb-admin/admin.html" "admin/home.html" "admin/controlpanel.html" "admin.html" "admin/cp.html" 
  "cp.html" "administrator/index.html" "administrator/login.html" "administrator/account.html" "administrator.html" 
  "login.html" "modelsearch/login.html" "moderator.html" "moderator/login.html" "moderator/admin.html" "account.html" 
  "controlpanel.html" "admincontrol.html" "admin_login.html" "panel-administracion/login.html" "admin/home.asp" 
  "admin/controlpanel.asp" "admin.asp" "pages/admin/admin-login.asp" "admin/admin-login.asp" "admin-login.asp" 
  "admin/cp.asp" "cp.asp" "administrator/account.asp" "administrator.asp" "acceso.asp" "login.asp" "modelsearch/login.asp" 
  "moderator.asp" "moderator/login.asp" "administrator/login.asp" "moderator/admin.asp" "controlpanel.asp" 
  "admin/account.html" "adminpanel.html" "webadmin.html" "administration" "pages/admin/admin-login.html" 
  "admin/admin-login.html" "webadmin/index.html" "webadmin/admin.html" "webadmin/login.html" "user.asp" "user.html" 
  "admincp/index.asp" "admincp/login.asp" "admincp/index.html" "admin/adminLogin.html" "adminLogin.html" "admin/adminLogin.html" 
  "home.html" "adminarea/index.html" "adminarea/admin.html" "adminarea/login.html" "panel-administracion/index.html" 
  "panel-administracion/admin.html" "modelsearch/index.html" "modelsearch/admin.html" "admin/admin_login.html" 
  "admincontrol/login.html" "adm/index.html" "adm.html" "admincontrol.asp" "admin/account.asp" "adminpanel.asp" 
  "webadmin.asp" "webadmin/index.asp" "webadmin/admin.asp" "webadmin/login.asp" "admin/admin_login.asp" "admin_login.asp" 
  "panel-administracion/login.asp" "adminLogin.asp" "admin/adminLogin.asp" "home.asp" "admin.asp" "adminarea/index.asp" 
  "adminarea/admin.asp" "adminarea/login.asp" "admin-login.html" "panel-administracion/index.asp" "panel-administracion/admin.asp" 
  "modelsearch/index.asp" "modelsearch/admin.asp" "administrator/index.asp" "admincontrol/login.asp" "adm/admloginuser.asp" 
  "admloginuser.asp" "admin2.asp" "admin2/login.asp" "admin2/index.asp" "adm/index.asp" "adm.asp" "affiliate.asp" 
  "adm_auth.asp" "memberadmin.asp" "administratorlogin.asp" "siteadmin/login.asp" "siteadmin/index.asp" "siteadmin/login.html" 
  "memberadmin/" "administratorlogin/" "adm/" "admin/account.php" "admin/index.php" "admin/login.php" "admin/admin.php" 
  "admin/account.php" "admin_area/admin.php" "admin_area/login.php" "siteadmin/login.php" "siteadmin/index.php" "siteadmin/login.html" 
  "admin/account.html" "admin/index.html" "admin/login.html" "admin/admin.html" "admin_area/index.php" "bb-admin/index.php" 
  "bb-admin/login.php" "bb-admin/admin.php" "admin/home.php" "admin_area/login.html" "admin_area/index.html" 
  "admin/controlpanel.php" "admin.php" "admincp/index.asp" "admincp/login.asp" "admincp/index.html" "admin/account.html" 
  "adminpanel.html" "webadmin.html" "webadmin/index.html" "webadmin/admin.html" "webadmin/login.html" "admin/admin_login.html" 
  "admin_login.html" "panel-administracion/login.html" "admin/cp.php" "cp.php" "administrator/index.php" "administrator/login.php" 
  "nsw/admin/login.php" "webadmin/login.php" "admin/admin_login.php" "admin_login.php" "administrator/account.php" "administrator.php" 
  "admin_area/admin.html" "pages/admin/admin-login.php" "admin/admin-login.php" "admin-login.php" "bb-admin/index.html" 
  "bb-admin/login.html" "acceso.php" "bb-admin/admin.html" "admin/home.html" "login.php" "modelsearch/login.php" "moderator.php" 
  "moderator/login.php" "moderator/admin.php" "account.php" "pages/admin/admin-login.html" "admin/admin-login.html" 
  "admin-login.html" "controlpanel.php" "admincontrol.php" "admin/adminLogin.html" "adminLogin.html" "admin/adminLogin.html" 
  "home.html" "rcjakar/admin/login.php" "adminarea/index.html" "adminarea/admin.html" "webadmin.php" "webadmin/index.php" 
  "webadmin/admin.php" "admin/controlpanel.html" "admin.html" "admin/cp.html" "cp.html" "adminpanel.php" "moderator.html" 
  "administrator/index.html" "administrator/login.html" "user.html" "administrator/account.html" "administrator.html" "login.html" 
  "modelsearch/login.html" "moderator/login.html" "adminarea/login.html" "panel-administracion/index.html" "panel-administracion/admin.html" 
  "modelsearch/index.html" "modelsearch/admin.html" "admincontrol/login.html" "adm/index.html" "adm.html" "moderator/admin.html" 
  "user.php" "account.html" "controlpanel.html" "admincontrol.html" "panel-administracion/login.php" "wp-login.php" 
  "adminLogin.php" "admin/adminLogin.php" "home.php" "admin.php" "adminarea/index.php" "adminarea/admin.php" "adminarea/login.php" 
  "panel-administracion/index.php" "panel-administracion/admin.php" "modelsearch/index.php" "modelsearch/admin.php" 
  "admincontrol/login.php" "adm/admloginuser.php" "admloginuser.php" "admin2.php" "admin2/login.php" "admin2/index.php" 
  "usuarios/login.php" "adm/index.php" "adm.php" "affiliate.php" "adm_auth.php" "memberadmin.php" "administratorlogin.php" 
  "memberadmin/" "administratorlogin/" "adm/" "admin/account.js" "admin/index.js" "admin/login.js" "admin/admin.js" "admin/account.js" 
  "admin_area/admin.js" "admin_area/login.js" "siteadmin/login.js" "siteadmin/index.js" "siteadmin/login.html" "admin/account.html" 
  "admin/index.html" "admin/login.html" "admin/admin.html" "admin_area/index.js" "bb-admin/index.js" "bb-admin/login.js" "bb-admin/admin.js" 
  "admin/home.js" "admin_area/login.html" "admin_area/index.html" "admin/controlpanel.js" "admin.js" "admincp/index.asp" "admincp/login.asp" 
  "admincp/index.html" "admin/account.html" "adminpanel.html" "webadmin.html" "webadmin/index.html" "webadmin/admin.html" 
  "webadmin/login.html" "admin/admin_login.html" "admin_login.html" "panel-administracion/login.html" "admin/cp.js" "cp.js" 
  "administrator/index.js" "administrator/login.js" "nsw/admin/login.js" "webadmin/login.js" "admin/admin_login.js" "admin_login.js" 
  "administrator/account.js" "administrator.js" "admin_area/admin.html" "pages/admin/admin-login.js" "admin/admin-login.js" 
  "admin-login.js" "bb-admin/index.html" "bb-admin/login.html" "bb-admin/admin.html" "admin/home.html" "login.js" "modelsearch/login.js" 
  "moderator.js" "moderator/login.js" "moderator/admin.js" "account.js" "pages/admin/admin-login.html" "admin/admin-login.html" 
  "admin-login.html" "controlpanel.js" "admincontrol.js" "admin/adminLogin.html" "adminLogin.html" "admin/adminLogin.html" 
  "home.html" "rcjakar/admin/login.js" "adminarea/index.html" "adminarea/admin.html" "webadmin.js" "webadmin/index.js" "acceso.js" 
  "webadmin/admin.js" "admin/controlpanel.html" "admin.html" "admin/cp.html" "cp.html" "adminpanel.js" "moderator.html" 
  "administrator/index.html" "administrator/login.html" "user.html" "administrator/account.html" "administrator.html" "login.html" 
  "modelsearch/login.html" "moderator/login.html" "adminarea/login.html" "panel-administracion/index.html" "panel-administracion/admin.html" 
  "modelsearch/index.html" "modelsearch/admin.html" "admincontrol/login.html" "adm/index.html" "adm.html" "moderator/admin.html" 
  "user.brf" "account.html" "controlpanel.html" "admincontrol.html" "panel-administracion/login.brf" "wp-login.brf" "adminLogin.brf" 
  "admin/adminLogin.brf" "home.brf" "admin.brf" "adminarea/index.brf" "adminarea/admin.brf" "adminarea/login.brf" 
  "panel-administracion/index.brf" "panel-administracion/admin.brf" "modelsearch/index.brf" "modelsearch/admin.brf" 
  "admincontrol/login.brf" "adm/admloginuser.brf" "admloginuser.brf" "admin2.brf" "admin2/login.brf" "admin2/index.brf" 
  "usuarios/login.brf" "adm/index.brf" "adm.brf" "affiliate.brf" "adm_auth.brf" "memberadmin.brf" "administratorlogin.brf" 
  "cpanel" "cpanel.php" "cpanel.html"
)
check_admin_page() {
    local path="$1"
    local base_url="$url"
    if [[ "$base_url" != */ ]] && [[ "$path" != /* ]]; then
        base_url="${base_url}/"
    fi
    local full_url="${base_url}${path}"
    local curl_opts=( -s -o /tmp/curl_content.txt -w "%{http_code}" --max-time "$timeout" --connect-timeout "$timeout" )
    if [ -n "$user_agent" ]; then
        curl_opts+=( -A "$user_agent" )
    fi
    local response
    response=$(curl "${curl_opts[@]}" "$full_url")
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $full_url - HTTP $response" >> "$LOG_FILE"
    if [ "$response" -eq 200 ]; then
        if grep -qiE "login|admin" /tmp/curl_content.txt; then
            echo "_____________________________________________________________"
            echo ""
            echo -e "\033[92m :::: ALERT::: POSSIBLE ADMIN PAGE FOUND ::: $full_url"
            echo "_____________________________________________________________"
            echo "$full_url" >> "$HITS_FILE"
        else
            echo "**** 200 Received, but no admin-related keywords found ::: $full_url"
        fi
    else
        echo -e "\033[91m **** NOT FOUND ::: $full_url"
    fi
    if [ "$delay" != "0" ]; then
        sleep "$delay"
    fi
}
trap 'echo -e "\n[-] Scan interrupted by user."; exit 1' INT
export -f check_admin_page
export url timeout user_agent delay LOG_FILE HITS_FILE
echo "[+] Starting process... Press CTRL+C to stop..."
sleep 1
printf "%s\n" "${admin_paths[@]}" | xargs -I {} -P "$concurrency" bash -c 'check_admin_page "$@"' _ {}
wait
echo -e "\033[0m"
found_count=$(wc -l < "$HITS_FILE")
total_count=$(printf "%s\n" "${admin_paths[@]}" | wc -l)
echo "Scan complete. Admin pages found: $found_count out of $total_count"
echo "Detailed log saved in: $LOG_FILE"
echo "Admin hits saved in: $HITS_FILE"
