// Notes: the example CRUD entity, scoped per user.
//
// THIS FILE IS THE TEMPLATE FOR YOUR OWN ENTITIES.
// To add e.g. "recipes": copy this file to Recipes.java, rename the table
// and the fields, add a CREATE TABLE in Db.java, and list the new paths in
// BackendApplication.addInterceptors(). That's the whole recipe.

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
@RequestMapping("/notes")
public class Notes {

	private final Db db;

	Notes(Db db) {
		this.db = db;
	}

	/** Maps a database row to the JSON shape of the contract. */
	private static Map<String, Object> toJson(Map<String, Object> row) {
		return Map.of(
				"id", row.get("id"),
				"title", row.get("title"),
				"content", row.get("content"),
				"createdAt", row.get("created_at"));
	}

	/**
	 * Finds a note by id, but only among the current user's notes.
	 * Someone else's note is indistinguishable from a missing one (404).
	 */
	private Map<String, Object> find(long userId, long id) {
		var rows = db.jdbc.queryForList(
				"SELECT * FROM notes WHERE id = ? AND user_id = ?", id, userId);
		if (rows.isEmpty()) throw Errors.notFound("Note not found");
		return rows.get(0);
	}

	/** GET /notes?page=1&limit=20&search=  -> {items, page, limit, total} */
	@GetMapping
	public Map<String, Object> list(@RequestAttribute("userId") long userId,
			@RequestParam(defaultValue = "") String page,
			@RequestParam(defaultValue = "") String limit,
			@RequestParam(defaultValue = "") String search) {
		int pageN = Math.max(parseIntOr(page, 1), 1);
		int limitN = Math.min(Math.max(parseIntOr(limit, 20), 1), 100);

		String where = "user_id = ? AND (title LIKE ? OR content LIKE ?)";
		// %/_ in the search term act as LIKE wildcards (parameterized, so
		// safe — purely a semantic quirk).
		String like = "%" + search + "%";

		int total = db.jdbc.queryForObject(
				"SELECT COUNT(*) FROM notes WHERE " + where,
				Integer.class, userId, like, like);
		List<Map<String, Object>> rows = db.jdbc.queryForList(
				"SELECT * FROM notes WHERE " + where
						+ " ORDER BY id DESC LIMIT ? OFFSET ?",
				userId, like, like, limitN, (pageN - 1) * limitN);

		return Map.of(
				"items", rows.stream().map(Notes::toJson).toList(),
				"page", pageN,
				"limit", limitN,
				"total", total);
	}

	/** POST /notes  {title, content} -> 201 note */
	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> create(@RequestAttribute("userId") long userId,
			@RequestBody Map<String, Object> body) {
		String title = Errors.stringField(body, "title");
		if (title == null) throw Errors.validation("title is required");
		String content = body.get("content") instanceof String s ? s : "";

		long id = db.insert(
				"INSERT INTO notes (user_id, title, content, created_at) "
						+ "VALUES (?, ?, ?, ?)",
				userId, title, content, Db.nowIso());
		return toJson(find(userId, id));
	}

	/** GET /notes/{id} -> 200 note | 404 */
	@GetMapping("/{id}")
	public Map<String, Object> get(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		return toJson(find(userId, id));
	}

	/** PUT /notes/{id}  {title, content} -> 200 updated note | 404 */
	@PutMapping("/{id}")
	public Map<String, Object> update(@RequestAttribute("userId") long userId,
			@PathVariable long id, @RequestBody Map<String, Object> body) {
		find(userId, id); // 404 (or someone else's note) before anything else
		String title = Errors.stringField(body, "title");
		if (title == null) throw Errors.validation("title is required");
		String content = body.get("content") instanceof String s ? s : "";

		db.jdbc.update("UPDATE notes SET title = ?, content = ? WHERE id = ?",
				title, content, id);
		return toJson(find(userId, id));
	}

	/** DELETE /notes/{id} -> 204 | 404 */
	@DeleteMapping("/{id}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@RequestAttribute("userId") long userId,
			@PathVariable long id) {
		find(userId, id); // 404 before deleting
		db.jdbc.update("DELETE FROM notes WHERE id = ?", id);
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
