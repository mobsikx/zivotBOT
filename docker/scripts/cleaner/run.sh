#!/usr/bin/env bash
#

# :: CLEANER ::

readonly C_DB_FILE="/app/db/zivotbot.db"

declare -a l_records=(`echo "
--
SELECT acl.id, au.id
  FROM adv_completion_list acl
  JOIN adv_urls au         ON au.id = acl.id_adv_url;
" | sqlite3 ${C_DB_FILE}`)

for rec in ${l_records[@]}
do
  compl_id=`echo ${rec} | cut -f 1 -d '|'`
  url_id=`echo ${rec} | cut -f 2 -d '|'`
  
  url=`echo "
SELECT url
  FROM adv_urls
 WHERE id = ${url_id};
  " | sqlite3 ${C_DB_FILE}`
 
  is_reserved=`google-chrome --no-sandbox --headless --disable-gpu --dump-dom ${url} 2>/dev/null | grep -ci 'Rezervováno'` 
  not_exists=`google-chrome --no-sandbox --headless --disable-gpu --dump-dom ${url} 2>/dev/null | grep -ci 'inzerát neexistuje'`
  if [[ ${not_exists} -ne 0 ]] || [[ ${is_reserved} -ne 0 ]]; then
    echo "Removing:"
    echo -e "\tadv_completion_list id = ${compl_id}"
    echo -e "\tadv_urls id            = ${url_id}"
    echo -e "\turl                    = ${url}"
    echo "===================================="
  
    echo "
DELETE
  FROM adv_completion_list
 WHERE id = ${compl_id};
 
DELETE
  FROM adv_urls
 WHERE id = ${url_id};
    " | sqlite3 ${C_DB_FILE}
  fi
done

exit 0
