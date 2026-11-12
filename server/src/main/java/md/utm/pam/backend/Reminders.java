// Reminders: GreenGarden care reminders, scoped per user. A copy of the
// Notes.java pattern: paginated list with search, create with validation
// (400), get/put/delete with 404. PUT is how the app marks one done.

package md.utm.pam.backend;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/reminders")
public class Reminders {

	/** Kinds of care - the same names as ReminderType in the app. */
	private static final List<String> TYPES =
			List.of("wipeLeaves", "fertilize", "spray", "repot");

	private final Db db;

	Reminders(Db db) {
		this.db = db;
	}

	/** Validated fields of a POST/PUT body. */
	private record Fields(long plantId, String type, String dueDate,
			boolean isDone) {
	}

	/** Maps a database row to the JSON shape of the contract. */
	private static Map<String, Object> toJson(Map<String, Object> row) {
		return Map.of(
				"id", row.get("id"),
				"plantId", row.get("plant_id"),
				"type", row.get("type"),
				"dueDate", row.get("due_date"),
				"isDone", ((Number) row.get("is_done")).intValue() == 1,
				"createdAt", row.get("created_at"));
	}

	/** Finds a reminder by id, but only among the current user's reminders. */
	private Map<String, Object> find(long userId, long id) {
		var rows = db.jdbc.queryForList(
				"SELECT * FROM reminders WHERE id = ? AND user_id = ?", id, userId);
		if (rows.isEmpty()) throw Errors.notFound("Reminder not found");
		return rows.get(0);
	}

	/** Validates a POST/PUT body: plantId, type, dueDate required. */
	private Fields parse(long userId, Map<String, Object> body) {
		long plantId = Plants.requirePlantId(db, userId, body);
		String type = Errors.stringField(body, "type");
		if (type == null || !TYPES.contains(type)) {
			throw Errors.validation("type must be one of " + TYPES);
		}
		String dueDate = Errors.isoInstantField(body, "dueDate");
		if (dueDate == null) throw Errors.validation("dueDate is required");
		Object done = body.get("isDone");
		if (done != null && !(done instanceof Boolean)) {
			throw Errors.validation("isDone must be true or false");
		}
		return new Fields(plantId, type, dueDate, Boolean.TRUE.equals(done));
	}

	/**
	 * GET /reminders?page=1&limit=20&search=
	 * -> {items, page, limit, total}, nearest due date first
	 */
	@GetMapping
	public Map<String, Object> list(@RequestAttribute("userId") long userId,
			@RequestParam(defaultValue = "") String page,
			@RequestParam(defaultValue = "") String limit,
			@RequestParam(defaultValue = "") String search) {
		int pageN = Math.max(parseIntOr(page, 1), 1);
		int limitN = Math.min(Math.max(parseIntOr(limit, 20), 1), 100);

		// Search by the reminder type (e.g. search=spray)
		String where = "user_id = ? AND type LIKE ?";
		String like = "%" + search + "%";

		int total = db.jdbc.queryForObject(
				"SELECT COUNT(*) FROM reminders WHERE " + where,
				Integer.class, userId, like);
		List<Map<String, Object>> rows = db.jdbc.queryForList(
				"SELECT * FROM reminders WHERE " + where
						+ " ORDER BY due_date ASC, id ASC LIMIT ? OFFSET ?",
				userId, like, limitN, (pageN - 1) * limitN);

		return Map.of(
				"items", rows.stream().map(Reminders::toJson).toList(),
				"page", pageN,
				"limit", limitN,
				"total", total);
	}

	/** POST /reminders {plantId, type, dueDate, isDone} -> 201 reminder */
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> create(@RequestAttribute("userId") long userId,
			@RequestBody Map<String, Object> body) {
		Fields f = parse(userId, body);

		long id = db.insert(
				"INSERT INTO reminders (user_id, plant_id, type, due_date, "
						+ "is_done, created_at) VALUES (?, ?, ?, ?, ?, ?)",
				userId, f.plantId(), f.type(), f.dueDate(), f.isDone() ? 1 : 0,
				Db.nowIso());
		return toJson(find(userId, id));
	}

	/** GET /reminders/{id} -> 200 reminder | 404 */
	@GetMapping("/{id}")
	public Map<String, Object> get(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		return toJson(find(userId, id));
	}

	/** PUT /reminders/{id} {same fields as POST} -> 200 updated | 404 */
	@PutMapping("/{id}")
	public Map<String, Object> update(@RequestAttribute("userId") long userId,
			@PathVariable long id, @RequestBody Map<String, Object> body) {
		find(userId, id); // 404 before anything else
		Fields f = parse(userId, body);

		db.jdbc.update("UPDATE reminders SET plant_id = ?, type = ?, "
				+ "due_date = ?, is_done = ? WHERE id = ?",
				f.plantId(), f.type(), f.dueDate(), f.isDone() ? 1 : 0, id);
		return toJson(find(userId, id));
	}

	/** DELETE /reminders/{id} -> 204 | 404 */
	@DeleteMapping("/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		find(userId, id); // 404 before deleting
		db.jdbc.update("DELETE FROM reminders WHERE id = ?", id);
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
