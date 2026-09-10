-- Testkonten: nur zum Ausprobieren nach einem Deploy da.
--
-- Ein Konto mit test = 1 (und jedes Spiel, an dem es beteiligt war) bekommt
-- nur zu sehen, wer sieht_test = 1 hat. Alle anderen Geraete kennen die
-- Testspieler nicht, und ihre Spiele laufen dort nie ein. Auf dem Geraet
-- des Testers zaehlen sie ausserdem in keine Statistik (Client-Flag).
ALTER TABLE users ADD COLUMN test INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN sieht_test INTEGER NOT NULL DEFAULT 0;

UPDATE users SET test = 1 WHERE email IN ('test1@blink180.de', 'test2@blink180.de');
UPDATE users SET sieht_test = 1 WHERE email = 'julius.klinzer@outlook.de';

-- Bisherige Testspiele weg: als Grabstein mit neuer Folgenummer, damit die
-- Loeschung beim naechsten Abgleich jedes Geraet erreicht. Die Nummern
-- werden vorher in einer Hilfstabelle vergeben (Zaehler + laufende Nummer),
-- sonst aenderte sich die Zaehlung waehrend des UPDATE unter den Haenden.
CREATE TEMP TABLE testspiele AS
  SELECT g.id AS id, ROW_NUMBER() OVER (ORDER BY g.seq) AS nr
    FROM games g
   WHERE g.deleted_at IS NULL
     AND g.id IN (SELECT gp.game_id FROM game_players gp JOIN users tu ON tu.id = gp.user_id WHERE tu.test = 1);

UPDATE games
   SET deleted_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now'),
       seq = (SELECT value FROM counters WHERE name = 'game_seq')
           + (SELECT nr FROM testspiele t WHERE t.id = games.id)
 WHERE id IN (SELECT id FROM testspiele);

UPDATE counters SET value = (SELECT COALESCE(MAX(seq), 0) FROM games) WHERE name = 'game_seq';
DROP TABLE testspiele;
