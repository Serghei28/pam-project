// SQLite setup. app.db is created automatically on first start.
//
// To add your own entity: add a CREATE TABLE below, then copy the pattern
// of Notes.java for its routes.

package md.utm.pam.backend;

import java.sql.Statement;
import java.time.Instant;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Component;

@Component
public class Db {

	/** Parameterized SQL everywhere — visible queries, no ORM in between. */
	final JdbcTemplate jdbc;

	/** Opens the database and applies the schema (idempotent) at startup. */
	Db(JdbcTemplate jdbc) {
		this.jdbc = jdbc;
		jdbc.execute("""
				CREATE TABLE IF NOT EXISTS users (
				  id            INTEGER PRIMARY KEY AUTOINCREMENT,
				  email         TEXT    NOT NULL UNIQUE,
				  password_hash TEXT    NOT NULL,
				  name          TEXT    NOT NULL,
				  created_at    TEXT    NOT NULL
				)""");
		jdbc.execute("""
				CREATE TABLE IF NOT EXISTS notes (
				  id         INTEGER PRIMARY KEY AUTOINCREMENT,
				  user_id    INTEGER NOT NULL REFERENCES users (id),
				  title      TEXT    NOT NULL,
				  content    TEXT    NOT NULL DEFAULT '',
				  created_at TEXT    NOT NULL
				)""");
		// GreenGarden: plants of a user. last_watered_at is needed by the app
		// to compute the next watering date (last + interval).
		jdbc.execute("""
				CREATE TABLE IF NOT EXISTS plants (
				  id                     INTEGER PRIMARY KEY AUTOINCREMENT,
				  user_id                INTEGER NOT NULL REFERENCES users (id),
				  name                   TEXT    NOT NULL,
				  species                TEXT    NOT NULL DEFAULT '',
				  photo_url              TEXT,
				  watering_interval_days INTEGER NOT NULL,
				  last_watered_at        TEXT    NOT NULL,
				  created_at             TEXT    NOT NULL
				)""");
		// GreenGarden: watering journal. A log belongs to a plant of the user.
		jdbc.execute("""
				CREATE TABLE IF NOT EXISTS watering_logs (
				  id         INTEGER PRIMARY KEY AUTOINCREMENT,
				  user_id    INTEGER NOT NULL REFERENCES users (id),
				  plant_id   INTEGER NOT NULL REFERENCES plants (id),
				  date       TEXT    NOT NULL,
				  note       TEXT    NOT NULL DEFAULT '',
				  created_at TEXT    NOT NULL
				)""");
		jdbc.execute("""
				CREATE TABLE IF NOT EXISTS files (
				  id         INTEGER PRIMARY KEY AUTOINCREMENT,
				  user_id    INTEGER NOT NULL REFERENCES users (id),
				  name       TEXT    NOT NULL,
				  mime_type  TEXT    NOT NULL,
				  size       INTEGER NOT NULL,
				  path       TEXT    NOT NULL,
				  created_at TEXT    NOT NULL
				)""");
	}

	/** Runs an INSERT and returns the generated (AUTOINCREMENT) row id. */
	long insert(String sql, Object... args) {
		var keyHolder = new GeneratedKeyHolder();
		jdbc.update(con -> {
			var ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
			for (int i = 0; i < args.length; i++) {
				ps.setObject(i + 1, args[i]);
			}
			return ps;
		}, keyHolder);
		return keyHolder.getKey().longValue();
	}

	/** Current UTC time in ISO-8601 — the format used for all timestamps. */
	static String nowIso() {
		return Instant.now().toString();
	}
}
