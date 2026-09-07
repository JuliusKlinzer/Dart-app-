-- Online-Spiele: ein Schnelles Spiel oder Finisher, zwei Orte, zwei Geraete.
--
-- Zwei Freunde stehen an zwei Scheiben, telefonieren und spielen gegeneinander.
-- Bisher hat einer mitgeschrieben und der andere blind vertraut. Jetzt liegt
-- der Spielstand auf dem Server: beide sehen ihn, beide duerfen eintragen.
--
-- Auch hier kennt der Server keine Dart-Regeln. `state` ist das laufende
-- Spiel, wie es der Client fuehrt (S.game) -- opakes JSON, das bei jeder
-- Aenderung als Ganzes ersetzt wird. `seq` ist die Versionsnummer: wer
-- schreibt, nennt die Version, die er kennt; ist sie nicht mehr aktuell, war
-- der andere schneller und bekommt den neuen Stand zurueck statt zu
-- ueberschreiben.

CREATE TABLE live_games (
  id         TEXT PRIMARY KEY,                 -- vom Client vergeben (= Spiel-Id) -> idempotent
  kind       TEXT NOT NULL,                    -- quick | finisher | cricket | rtw
  state      TEXT NOT NULL,                    -- JSON des laufenden Spiels
  seq        INTEGER NOT NULL,                 -- Versionsnummer, global steigend
  status     TEXT NOT NULL DEFAULT 'offen',    -- offen | zu
  created_by TEXT NOT NULL REFERENCES users(id),
  updated_by TEXT REFERENCES users(id),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  ended_at   TEXT
);
CREATE INDEX live_games_status ON live_games(status);

-- Wer mitspielt, sieht das Spiel auf seinem Geraet und darf mitschreiben.
CREATE TABLE live_game_players (
  game_id TEXT NOT NULL REFERENCES live_games(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  PRIMARY KEY (game_id, user_id)
);
CREATE INDEX live_game_players_user ON live_game_players(user_id);

INSERT INTO counters (name, value) VALUES ('live_seq', 0);
