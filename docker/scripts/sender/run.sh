#!/usr/bin/env bash
#

##C&V      ##
# Constants #
#     &     #
# Variables #
##         ##
readonly C_DB_FILE="/app/db/zivotbot.db"

##F        ##
# Functions #
##         ##
function db_get_send_ids() {
  declare -a l_send_ids=()
  
  l_send_ids+=`echo "
SELECT acl.id
  FROM adv_completion_list acl
 WHERE acl.id_telegram_lov_notification = 1;
" | sqlite3 "${C_DB_FILE}"`

  if [[ ${#l_send_ids[*]} -eq 0 ]]; then
    return 1
  fi

  echo ${l_send_ids[@]}
  return 0
}

function db_send_notification() {
  local comp_id="${1}"

  tosend=`echo "
SELECT al.location, au.url
  FROM adv_completion_list acl
  JOIN adv_urls au         ON au.id = acl.id_adv_url
  JOIN adv_locations al    ON al.id = acl.id_adv_location
  JOIN travel_locations tl ON tl.id = acl.id_adv_location
  JOIN travel_times tt     ON tt.id = tl.id_travel_time
 WHERE 1 = 1
       AND acl.id = ${comp_id}
       AND acl.id_telegram_lov_notification = 1
       AND tt.minimum <= 60
 LIMIT 1;
" | sqlite3 "${C_DB_FILE}"`

  if [ -z ${tosend} ];
  then
    return 1
  fi

  echo ${tosend}
  return 0
}

function db_update_sendstatus() {
  local comp_id="${1}"
  local send_stat="${2}"
  
  echo "
UPDATE adv_completion_list
   SET id_telegram_lov_notification = ${send_stat}
 WHERE 1 = 1
       AND id = ${comp_id};
" | sqlite3 "${C_DB_FILE}"

  return
}

function db_get() {
  local rec_table="${1}"
  local rec_column="${2}"
  local rec_filter="${3}"
  
  res=`echo "
SELECT ${rec_column}
  FROM ${rec_table}
 WHERE ${rec_filter};
" | sqlite3 "${C_DB_FILE}"`

  if [ -z ${res} ]; then return 1; fi # not such a record in the db

  echo "${res}"
  return 0
}

function send_telegram() {
  local bot_id="${1}"
  local channel_id="${2}"
  local location="${3}"
  local url="${4}"

  res=`curl -sfk -X POST \
     -H 'Content-Type: application/json' \
     -d "{\"chat_id\": \"${channel_id}\", \"text\": \"${location}\n${url}\", \"disable_notification\": false}" \
     "https://api.telegram.org/${bot_id}/sendMessage" \
  | jq -r '.ok'`

  if ! ${res}; then
    return 1
  fi

  return 0
}

##M   ##
# Main #
##    ##
declare -a l_all_unsent_ids=(`db_get_send_ids`)

echo -e "\n========================================"
echo "DEBUG ### List of unsent ids:    ${l_all_unsent_ids[@]}"

for completion_id in ${l_all_unsent_ids[@]}; do

  echo "DEBUG ### Processing id:       ${completion_id}"

  # mark as don't send in DB
  tosend=`db_send_notification "${completion_id}"`
  tosend_err=$?
  if [[ ${tosend_err} -ne 0 ]]; then
    db_update_sendstatus "${completion_id}" 3
    echo "DEBUG ### DON'T SEND..."
    continue
  fi
	
  # send message to a telegram channel
  send_loc=`echo "${tosend}" | cut -f 1 -d '|'`
  send_url=`echo "${tosend}" | cut -f 2 -d '|'`

  echo "DEBUG ### Processing location: ${send_loc}"
  echo "DEBUG ### Processing url:      ${send_url}"

  send_tele_botid=`db_get "config_telegram" "bot_id" "name = 'Amalka'"`
  send_tele_channelid=`db_get "config_telegram" "channel_id" "name = 'Amalka'"`
	
  send_telegram "${send_tele_botid}" "${send_tele_channelid}" "${send_loc}" "${send_url}"
  if [[ $? -eq 0 ]]; then
    db_update_sendstatus "${completion_id}" 2
    echo "DEBUG ### WAS SENT..."
  fi
done

exit 0
