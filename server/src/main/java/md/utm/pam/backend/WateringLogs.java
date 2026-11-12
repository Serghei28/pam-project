// WateringLogs: GreenGarden watering journal, scoped per user. Built on the
// Notes.java pattern; the catalog contract for this entity has no update:
// GET/POST /watering-logs, DELETE /watering-logs/{id}.

package md.utm.pam.backend;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/watering-logs")
public class WateringLogs {

	private final Db db;

	WateringLogs(Db db) {
		this.db = db;
	}

	/** Maps a database row to the JSON shape of the contract. */
	private static Map<String, Object> toJson(Map<String, Object> row) {
		return Map.of(
				"id", row.get("id"),
				"plantId", row.get("plant_id"),
				"date", row.get("date"),
				"note", row.get("note"),
				"createdAt", row.get("created_at"));
	}

	/** Finds a log by id, but only among the current user's logs. */
	private Map<String, Object> find(long userId, long id) {
		var rows = db.jdbc.queryForList(
				"SELECT * FROM watering_logs WHERE id = ? AND user_id = ?",
				id, userId);
		if (rows.isEmpty()) throw Errors.notFound("Watering log not found");
		return rows.get(0);
	}

	/**
	 * GET /watering-logs?page=1&limit=20&search=
	 * -> {items, page, limit, total}, newest watering first
	 */
	@GetMapping
	public Map<String, Object> list(@RequestAttribute("userId") long userId,
			@RequestParam(defaultValue = "") String page,
			@RequestParam(defaultValue = "") String limit,
			@RequestParam(defaultValue = "") String search) {
		int pageN = Math.max(parseIntOr(page, 1), 1);
		int limitN = Math.min(Math.max(parseIntOr(limit, 20), 1), 100);

		// Search by the note text
		String where = "user_id = ? AND note LIKE ?";
		String like = "%" + search + "%";

		int total = db.jdbc.queryForObject(
				"SELECT COUNT(*) FROM watering_logs WHERE " + where,
				Integer.class, userId, like);
		List<Map<String, Object>> rows = db.jdbc.queryForList(
				"SELECT * FROM watering_logs WHERE " + where
						+ " ORDER BY date DESC, id DESC LIMIT ? OFFSET ?",
				userId, like, limitN, (pageN - 1) * limitN);

		return Map.of(
				"items", rows.stream().map(WateringLogs::toJson).toList(),
				"page", pageN,
				"limit", limitN,
				"total", total);
	}

	/** POST /watering-logs {plantId, date, note} -> 201 log */
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> create(@RequestAttribute("userId") long userId,
			@RequestBody Map<String, Object> body) {
		long plantId = Plants.requirePlantId(db, userId, body);
		String date = Errors.isoInstantField(body, "date");
		if (date == null) date = Db.nowIso(); // watered "just now"
		String note = body.get("note") instanceof String s ? s.trim() : "";

		long id = db.insert(
				"INSERT INTO watering_logs (user_id, plant_id, date, note, "
						+ "created_at) VALUES (?, ?, ?, ?, ?)",
				userId, plantId, date, note, Db.nowIso());
		return toJson(find(userId, id));
	}

	/** DELETE /watering-logs/{id} -> 204 | 404 */
	@DeleteMapping("/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		find(userId, id); // 404 before deleting
		db.jdbc.update("DELETE FROM watering_logs WHERE id = ?", id);
	}

	/** Query params arrive as text; garbage falls back to the default. */
	private static int parseIntOr(String value, int fallback) {
		try {
			return Integer.parseInt(value);
		} catch (NumberFormatException e) {
			return fallback;
		}
	}
}
