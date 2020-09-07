-- init script
CREATE TABLE IF NOT EXISTS config_telegram (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  bot_id TEXT NOT NULL,
  channel_id TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS config_advertisement (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS telegram_lov_notifications (
  id INTEGER PRIMARY KEY,
  status TEXT NOT NULL
);

-- =====================================

-- DROP TABLE travel_times;
-- DROP TABLE travel_locations;
-- DROP TABLE adv_locations;
-- DROP TABLE adv_urls;
-- DROP TABLE adv_completion_list;

CREATE TABLE IF NOT EXISTS adv_completion_list (
  id INTEGER PRIMARY KEY,                  
  id_adv_url INTEGER NOT NULL,
  id_adv_location INTEGER NOT NULL,
  id_telegram_lov_notification INTEGER DEFAULT 1,
  FOREIGN KEY(id_adv_url) REFERENCES adv_urls(id),
  FOREIGN KEY(id_adv_location) REFERENCES adv_locations(id)
  FOREIGN KEY(id_telegram_lov_notification) REFERENCES telegram_lov_notifications(id)
);

CREATE TABLE IF NOT EXISTS adv_urls (
  id INTEGER PRIMARY KEY,
  url TEXT NOT NULL,
  url_hash TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS index_adv_url_hash ON adv_urls(url_hash);

CREATE TABLE IF NOT EXISTS adv_locations (
  id INTEGER PRIMARY KEY,
  location TEXT NOT NULL,
  location_hash TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS index_adv_location_hash ON adv_locations(location_hash);

CREATE TABLE IF NOT EXISTS travel_locations (
  id INTEGER PRIMARY KEY,
  id_adv_location INTEGER NOT NULL,
  id_travel_time INTEGER NOT NULL,
  FOREIGN KEY(id_adv_location) REFERENCES adv_locations(id),
  FOREIGN KEY(id_travel_time) REFERENCES travel_times(id)
);

CREATE TABLE IF NOT EXISTS travel_times (
  id INTEGER PRIMARY KEY,
  minimum INTEGER NOT NULL
);

-- ====================================

INSERT OR REPLACE INTO config_telegram (id, name, bot_id, channel_id)
                VALUES (1, "Amalka", "bot1302263842:AAHPyLeCMfOcj1qxS8f9RqdLtmizOtqzvog", "-1001361596126");
INSERT OR REPLACE INTO config_advertisement (id, name, url)
                VALUES (1, 'search_sreality', 'https://www.sreality.cz/hledani/prodej/domy/pamatky-jine,rodinne-domy,vily,chalupy,zemedelske-usedlosti/stredocesky-kraj?per_page=1000&stav=po-rekonstrukci,novostavby,dobry-stav,velmi-dobry-stav&plocha-od=90&plocha-do=10000000000&cena-od=0&cena-do=5000000&plocha-pozemku-od=500&plocha-pozemku-do=2000&bez-aukce=1');

INSERT OR REPLACE INTO telegram_lov_notifications (id, status)
                VALUES (1, 'TBD');
INSERT OR REPLACE INTO telegram_lov_notifications (id, status)
                VALUES (2, 'SENT');
INSERT OR REPLACE INTO telegram_lov_notifications (id, status)
                VALUES (3, 'NOT_SENT');          
