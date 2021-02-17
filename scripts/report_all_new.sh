#!/usr/bin/env bash
#

while :;
do
  date '+%Y-%m-%d %H:%M:%S'
  echo
  echo "
--
SELECT acl.id, al.location, au.url, acl.id_telegram_lov_notification, tt.minimum
  FROM adv_completion_list acl
  JOIN adv_urls au         ON au.id = acl.id_adv_url
  JOIN adv_locations al    ON al.id = acl.id_adv_location
  JOIN travel_locations tl ON tl.id = acl.id_adv_location
  JOIN travel_times tt     ON tt.id = tl.id_travel_time
 WHERE id_telegram_lov_notification = 1;
" | sqlite3 /opt/zivotbot/db/zivotbot.db
  sleep 5;
  clear;
done

exit 0
