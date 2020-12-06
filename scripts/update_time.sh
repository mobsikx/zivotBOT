#!/usr/bin/env bash
#

C_COMPL_ID="${1}"
C_TIME_MIN="${2}"

function get_send_status() {
  local id="${1}"

  echo "
SELECT id_telegram_lov_notification
  FROM adv_completion_list
 WHERE id = ${id};
" | sqlite3 /opt/zivotbot/db/zivotbot.db

  return
}

function set_send_status() {
  local id="${1}"
  local status="${2}"


  echo "
UPDATE adv_completion_list
   SET id_telegram_lov_notification = ${status}
 WHERE id = ${id};
" | sqlite3 /opt/zivotbot/db/zivotbot.db

  return
}

function update_time_minimum() {
  local id="${1}"
  local t_min="${2}"

  echo "
UPDATE travel_times
   SET minimum = ${t_min}
 WHERE id = ( 
              SELECT tt.id
                FROM adv_completion_list acl
                JOIN adv_urls au         ON au.id = acl.id_adv_url
                JOIN adv_locations al    ON al.id = acl.id_adv_location
                JOIN travel_locations tl ON tl.id = acl.id_adv_location
                JOIN travel_times tt     ON tt.id = tl.id_travel_time
               WHERE acl.id = ${id}
            );
" | sqlite3 /opt/zivotbot/db/zivotbot.db

  return
}

if [[ ${C_TIME_MIN} -le 60 ]]; then
  if [[ $(get_send_status "${C_COMPL_ID}") -ne 2 ]]; then
    set_send_status "${C_COMPL_ID}" 1
  fi
else
  set_send_status "${C_COMPL_ID}" 3
fi

update_time_minimum "${C_COMPL_ID}" "${C_TIME_MIN}"

exit 0
