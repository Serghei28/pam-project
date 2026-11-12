// Plants: GreenGarden entity, scoped per user. A copy of the Notes.java
// pattern: paginated list with search, create with validation (400),
// get/put/delete with 404 (someone else's plant looks like a missing one).

package md.utm.pam.backend;

import java.util.LinkedHashMap;
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
@RequestMapping("/plants")
public class Plants {

	/** Same bounds as the plant form in the app (L3 validation). */
	private static final int MIN_INTERVAL = 1;
	private static final int MAX_INTERVAL = 365;

	private final Db db;

	Plants(Db db) {
		this.db = db;
	}

	/** Validated fields of a POST/PUT body. */
	private record Fields(String name, String species, String photoUrl,
			int wateringIntervalDays, String lastWateredAt) {
	}

	/**
	 * Maps a database row to the JSON shape of the contract.
	 * LinkedHashMap, not Map.of: photoUrl may be null.
	 */
	private static Map<String, Object> toJson(Map<String, Object> row) {
		var json = new LinkedHashMap<String, Object>();
		json.put("id", row.get("id"));
		json.put("name", row.get("name"));
		json.put("species", row.get("species"));
		json.put("photoUrl", row.get("photo_url"));
		json.put("wateringIntervalDays", row.get("watering_interval_days"));
		json.put("lastWateredAt", row.get("last_watered_at"));
		json.put("createdAt", row.get("created_at"));
		return json;
	}

	/** Finds a plant by id, but only among the current user's plants. */
	private Map<String, Object> find(long userId, long id) {
		var rows = db.jdbc.queryForList(
				"SELECT * FROM plants WHERE id = ? AND user_id = ?", id, userId);
		if (rows.isEmpty()) throw Errors.notFound("Plant not found");
		return rows.get(0);
	}

	/**
	 * Validates a POST/PUT body. lastWateredAt is optional: when missing,
	 * defaultLastWateredAt is used (now on create, the stored value on update).
	 */
	private static Fields parse(Map<String, Object> body,
			String defaultLastWateredAt) {
		String name = Errors.stringField(body, "name");
		if (name == null) throw Errors.validation("name is required");
		String species = body.get("species") instanceof String s ? s.trim() : "";
		String photoUrl = Errors.stringField(body, "photoUrl");

		if (!(body.get("wateringIntervalDays") instanceof Number n)
				|| n.doubleValue() != n.intValue()) {
			throw Errors.validation("wateringIntervalDays must be an integer");
		}
		int interval = n.intValue();
		if (interval < MIN_INTERVAL || interval > MAX_INTERVAL) {
			throw Errors.validation("wateringIntervalDays must be between "
					+ MIN_INTERVAL + " and " + MAX_INTERVAL);
		}

		String lastWateredAt = Errors.isoInstantField(body, "lastWateredAt");
		if (lastWateredAt == null) lastWateredAt = defaultLastWateredAt;
		return new Fields(name, species, photoUrl, interval, lastWateredAt);
	}

	/**
	 * For entities that point at a plant (watering logs, reminders):
	 * body.plantId must be an integer id of one of the user's plants.
	 * Someone else's plant is treated like a missing one.
	 */
	static long requirePlantId(Db db, long userId, Map<String, Object> body) {
		if (!(body.get("plantId") instanceof Number n)
				|| n.doubleValue() != n.longValue()) {
			throw Errors.validation("plantId must be an integer");
		}
		long plantId = n.longValue();
		int count = db.jdbc.queryForObject(
				"SELECT COUNT(*) FROM plants WHERE id = ? AND user_id = ?",
				Integer.class, plantId, userId);
		if (count == 0) throw Errors.validation("plantId: plant not found");
		return plantId;
	}

	/** GET /plants?page=1&limit=20&search=  -> {items, page, limit, total} */
	@GetMapping
	public Map<String, Object> list(@RequestAttribute("userId") long userId,
			@RequestParam(defaultValue = "") String page,
			@RequestParam(defaultValue = "") String limit,
			@RequestParam(defaultValue = "") String search) {
		int pageN = Math.max(parseIntOr(page, 1), 1);
		int limitN = Math.min(Math.max(parseIntOr(limit, 20), 1), 100);

		// Search by plant name or species
		String where = "user_id = ? AND (name LIKE ? OR species LIKE ?)";
		String like = "%" + search + "%";

		int total = db.jdbc.queryForObject(
				"SELECT COUNT(*) FROM plants WHERE " + where,
				Integer.class, userId, like, like);
		List<Map<String, Object>> rows = db.jdbc.queryForList(
				"SELECT * FROM plants WHERE " + where
						+ " ORDER BY id DESC LIMIT ? OFFSET ?",
				userId, like, like, limitN, (pageN - 1) * limitN);

		return Map.of(
				"items", rows.stream().map(Plants::toJson).toList(),
				"page", pageN,
				"limit", limitN,
				"total", total);
	}

	/**
	 * POST /plants {name, species, photoUrl, wateringIntervalDays,
	 * lastWateredAt} -> 201 plant
	 */
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> create(@RequestAttribute("userId") long userId,
			@RequestBody Map<String, Object> body) {
		Fields f = parse(body, Db.nowIso());

		long id = db.insert(
				"INSERT INTO plants (user_id, name, species, photo_url, "
						+ "watering_interval_days, last_watered_at, created_at) "
						+ "VALUES (?, ?, ?, ?, ?, ?, ?)",
				userId, f.name(), f.species(), f.photoUrl(),
				f.wateringIntervalDays(), f.lastWateredAt(), Db.nowIso());
		return toJson(find(userId, id));
	}

	/** GET /plants/{id} -> 200 plant | 404 */
	@GetMapping("/{id}")
	public Map<String, Object> get(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		return toJson(find(userId, id));
	}

	/** PUT /plants/{id} {same fields as POST} -> 200 updated plant | 404 */
	@PutMapping("/{id}")
	public Map<String, Object> update(@RequestAttribute("userId") long userId,
			@PathVariable long id, @RequestBody Map<String, Object> body) {
		var existing = find(userId, id); // 404 before anything else
		Fields f = parse(body, (String) existing.get("last_watered_at"));

		db.jdbc.update("UPDATE plants SET name = ?, species = ?, photo_url = ?, "
				+ "watering_interval_days = ?, last_watered_at = ? WHERE id = ?",
				f.name(), f.species(), f.photoUrl(),
				f.wateringIntervalDays(), f.lastWateredAt(), id);
		return toJson(find(userId, id));
	}

	/**
	 * DELETE /plants/{id} -> 204 | 404. Cascade: the plant's watering logs
	 * and reminders go with it (SQLite does not enforce REFERENCES by default).
	 */
	@DeleteMapping("/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		find(userId, id); // 404 before deleting
		db.jdbc.update("DELETE FROM watering_logs WHERE plant_id = ?", id);
		db.jdbc.update("DELETE FROM reminders WHERE plant_id = ?", id);
		db.jdbc.update("DELETE FROM plants WHERE id = ?", id);
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
