#!/usr/bin/env bash
#
set -e

##C&V       ##
#  Consts
#    &
# Variables #
##         ##
readonly C_LIST_FILE="/app/tmp/list.dump"
readonly C_DB_FILE="/app/db/zivotbot.db"
readonly C_NEXT_TUESDAY=$(date -d "next Tuesday" '+%d.%m.%Y')
declare -a l_locs_to=("Praha,,Hlavn%C3%AD%20nádraž%C3%AD" "Praha%20Masarykovo%20n." "Praha,,Ládv%C3%AD" "Praha,,Kobylisy" "Praha-Holešovice")
declare -a l_station_types=("200003" "100003")
declare -a l_links=()
declare -a l_travel_times=()
declare -a l_travel_minutes=()

##F        ##
# Functions #
##         ##
# pro prevod diakritiky v url
function uriencode() {
  jq -nr --arg v "$1" '$v|@uri'
}

function strip_location() {
  local loc_fullname="${1}"
  local loc_stripped=""
  
  if [[ $(echo "${loc_fullname}" | grep -c 'okres') -gt 0 ]]
  then
    loc_stripped=$(echo "${loc_fullname}" | cut -f 1 -d ',')
  else
    loc_stripped=$(echo "${loc_fullname}" | cut -f 2- -d ',')
    loc_stripped=${loc_stripped#?}
  fi
  
  echo ${loc_stripped}
  return
}

function travel_minutes() {
  local t_fullstring="${1}"
  local t_hod="0"
  local t_min="0"
  
  t_hod=$(echo ${t_fullstring} | grep -oP '\d+ hod' | cut -f 1 -d ' ')
  if [ -z ${t_hod} ]; then t_hod="0"; fi
  t_min=$(echo ${t_fullstring} | grep -oP '\d+ min' | cut -f 1 -d ' ')
  if [ -z ${t_min} ]; then t_min="0"; fi

  echo $(( ${t_hod} * 60 + ${t_min} ))
  return
}

function find_minimum() {
  local l_array=($@)

  readarray -t l_sorted < <(printf '%s\0' "${l_array[@]}" | sort -unz | xargs -0n1)

  echo ${l_sorted[0]}
  return
}

function db_adv_present() {
  local hash="${1}"
  local which_hash="`echo \"${2}\" | tr 'A-Z' 'a-z'`" # url or location

  adv_id=`echo "SELECT MAX(id) FROM adv_list WHERE ${which_hash}_hash = '"${hash}"';" | sqlite3 "${C_DB_FILE}"`
  if [ -z ${adv_id} ]; then return 1; fi # not a such record in the db

  echo "${adv_id}"
  return 0
}

function db_notification_present() {
  local adv_id="${1}"

  notif_id=`echo "SELECT MAX(id) FROM adv_notifications WHERE id_adv_list = ${adv_id};" | sqlite3 "${C_DB_FILE}"`

  if [ -z ${notif_id} ]; then return 1; fi # not a such record in the db

  echo "${notif_id}"
  return 0
}

function db_traveltime_present() {
  local adv_id="${1}"

  trav_id=`echo "SELECT MAX(id) FROM adv_traveltime WHERE id_adv_list = ${adv_id};" | sqlite3 "${C_DB_FILE}"`

  if [ -z ${trav_id} ]; then return 1; fi # not a such record in the db

  echo "${trav_id}"
  return 0
}

##M   ##
# Main #
##    ##
# ziskej prehled inzeratu
google-chrome --no-sandbox --headless --disable-gpu --dump-dom 'https://www.sreality.cz/hledani/prodej/domy/rodinne-domy,vily,chalupy,pamatky-jine,zemedelske-usedlosti/stredocesky-kraj?pois_in_place_distance=1.5&per_page=100&pois_in_place=1%7C2&navic=samostatny&stav=po-rekonstrukci,novostavby,dobry-stav,velmi-dobry-stav&plocha-od=90&plocha-do=10000000000&cena-od=0&cena-do=5000000&plocha-pozemku-od=0&plocha-pozemku-od=500&plocha-pozemku-do=2000&bez-aukce=1' > ${C_LIST_FILE} 2>/dev/null

# postahuj detaily inzeratu
l_links=(`grep -ioE '<a ng-href="/detail.* ng-click="' ${C_LIST_FILE} | cut -f 2 -d '"' | sort -u`)
idx=0
for l in ${l_links[@]}
do
  sha_link=$(echo -n "https://sreality.cz${l}" | sha256sum -t | awk '{ print $1 }')
  google-chrome --no-sandbox --headless --disable-gpu --dump-dom https://sreality.cz${l} > "/app/tmp/detail-${idx}.dump" 2>/dev/null
  loc=$(grep -oiE '<span class="location-text ng-binding">.*</span>' "/app/tmp/detail-${idx}.dump" | cut -f 2 -d '>' | cut -f 1 -d '<')
  sha_loc=$(echo -n "${loc}" | sha256sum -t | awk '{ print $1 }')
  
  loc_from=`strip_location "${loc}"`
  loc_from=`uriencode "${loc_from}"`
  #echo ${sha_link}
  #echo ${sha_loc}
  
  for loc_to in ${l_locs_to[@]}
  do
    for station_type in ${l_station_types[@]}
    do
      curl -sfkL 'https://idos.idnes.cz/vlakyautobusymhdvse/spojeni/vysledky/?date='${C_NEXT_TUESDAY}'&time=05:00&f='${loc_from}'&fc='${station_type}'&t='${loc_to}'&tc='${station_type} >> /app/tmp/idos-${idx}.dump 2>/dev/null
    done
  done
  
  IFS=$'\n'
  l_travel_times=(`cat /app/tmp/idos-${idx}.dump | grep -oiE 'Celkový čas.*(hod|min)' | cut -f 2 -d '>'`)
  for travel_time in ${l_travel_times[@]}
  do
    l_travel_minutes+=(`travel_minutes "${travel_time}"`)
  done
  unset IFS
 
  find_minimum "${l_travel_minutes[@]}" 
  
  idx=$(( ${idx} + 1))
  l_travel_minutes=()
done

exit 0
