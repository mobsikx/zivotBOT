#!/usr/bin/env bash
#

# delete from completion list
declare -a l_todel=(`
echo "
SELECT acl.id
  FROM adv_completion_list acl
  JOIN adv_urls au         ON au.id = acl.id_adv_url
  JOIN adv_locations al    ON al.id = acl.id_adv_location
  JOIN travel_locations tl ON tl.id = acl.id_adv_location
  JOIN travel_times tt     ON tt.id = tl.id_travel_time
 WHERE al.location_hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
" | sqlite3 /opt/zivotbot/db/zivotbot.db`)

declare -a l_todel+=(`
echo "
SELECT id FROM (
  SELECT COUNT(au.url) AS url_count, MAX(acl.id) AS id
    FROM adv_completion_list acl
    JOIN adv_urls au         ON au.id = acl.id_adv_url
    JOIN adv_locations al    ON al.id = acl.id_adv_location
    JOIN travel_locations tl ON tl.id = acl.id_adv_location
    JOIN travel_times tt     ON tt.id = tl.id_travel_time
  GROUP BY au.url)
WHERE url_count > 1;
" | sqlite3 /opt/zivotbot/db/zivotbot.db`)

readarray -t l_uniq < <(printf '%s\0' "${l_todel[@]}" | sort -unz | xargs -0n1)

for d in ${l_uniq[@]}
do
  echo "
DELETE FROM adv_completion_list WHERE id = ${d};
" | sqlite3 /opt/zivotbot/db/zivotbot.db
done

# delete from location list
declare -a l_todel=(`
echo "
SELECT id
  FROM adv_locations
 WHERE location_hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
" | sqlite3 /opt/zivotbot/db/zivotbot.db`)

for d in ${l_uniq[@]}
do
  echo "
DELETE FROM adv_locations WHERE id = ${d};
DELETE FROM travel_locations WHERE id_adv_location = ${d};
" | sqlite3 /opt/zivotbot/db/zivotbot.db
done

exit 0
