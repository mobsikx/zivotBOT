#!/usr/bin/env bash
#

# :: CLEANER ::

readonly C_DB_FILE="/app/db/zivotbot.db"

declare -a l_records=(`echo "
--
SELECT acl.id, au.id, tl.id
  FROM adv_completion_list acl
  JOIN adv_urls au         ON au.id = acl.id_adv_url
  JOIN adv_locations al    ON al.id = acl.id_adv_location
  JOIN travel_locations tl ON tl.id = acl.id_adv_location
  JOIN travel_times tt     ON tt.id = tl.id_travel_time;
" | sqlite3 ${C_DB_FILE}`)

for rec in ${l_records[@]}
do
  compl_id=`echo ${rec} | cut -f 1 -d '|'`
  url_id=`echo ${rec} | cut -f 2 -d '|'`
  travloc_id=`echo ${rec} | cut -f 3 -d '|'`
  
  url=`echo "
SELECT url
  FROM adv_urls
 WHERE id = ${url_id};
  " | sqlite3 ${C_DB_FILE}`
  
  not_exists=`google-chrome --no-sandbox --headless --disable-gpu --dump-dom ${url} 2>/dev/null | grep -ci 'inzerát neexistuje'`
  if [[ ${not_existst} -ne 0 ]]; then
    echo "Removing:"
    echo -e "\tadv_completion_list id = ${compl_id}"
    echo -e "\adv_urls id             = ${url_id}"
    echo -e "\ttravel_locations id    = ${travloc_id}"
    echo -e "\turl                    = ${url}"
  
    echo "
DELETE
  FROM adv_completion_list
 WHERE id = ${compl_id};
 
DELETE
  FROM travel_locations
 WHERE id = ${travloc_id};
 
DELETE
  FROM adv_urls
 WHERE id = ${url_id};
    " | sqlite3 ${C_DB_FILE}
  fi
done

exit 0
