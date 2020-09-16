#!/usr/bin/env bash
#

C_COMPL_ID="${1}"

function get_url_id() {
  local completion_id="${1}"
  local url_id=0

  url_id=`echo "
SELECT id_adv_url
  FROM adv_completion_list
 WHERE id = ${completion_id};
" | sqlite3 /opt/zivotbot/db/zivotbot.db`

  echo "${url_id}"
  return
}

function delete_records() {
  local completion_id="${1}"
  local url_id="${2}"
  
  echo "
DELETE
  FROM adv_completion_list
 WHERE id = ${completion_id};

DELETE
  FROM adv_urls
 WHERE id = ${url_id};
" | sqlite3 /opt/zivotbot/db/zivotbot.db

  return
}

C_URL_ID=`get_url_id "${C_COMPL_ID}"`
delete_records "${C_COMPL_ID}" "${C_URL_ID}"

exit 0
