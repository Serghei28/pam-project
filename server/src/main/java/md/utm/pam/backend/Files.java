// File upload/download. Bytes live in uploads/, metadata in the database.

package md.utm.pam.backend;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.time.Instant;
import java.util.Map;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletResponse;

@RestController
public class Files {

	/**
	 * Upload size cap: 5 MB — plenty for lab photos. Enforced by Tomcat via
	 * spring.servlet.multipart.* in application.properties, on Content-Length
	 * (rejected immediately) AND on counted bytes when the body is chunked;
	 * Errors.java maps the overflow to 400 VALIDATION_ERROR (the contract
	 * deliberately has no 413).
	 */
	static final long MAX_UPLOAD_BYTES = 5 * 1024 * 1024;

	private final Db db;
	private final File uploadsDir = new File("uploads");

	Files(Db db) {
		this.db = db;
		uploadsDir.mkdirs(); // creates uploads/ on first start
	}

	/** POST /files  (multipart, field "file") -> 201 {id, url, name, size, mimeType} */
	@PostMapping("/files")
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> upload(@RequestAttribute("userId") long userId,
			@RequestParam("file") MultipartFile file) throws IOException {
		// Belt and braces: Tomcat already enforced the cap while parsing, so
		// this only fires if the limit in application.properties disappears.
		if (file.getSize() > MAX_UPLOAD_BYTES) {
			throw Errors.validation("File too large: the upload limit is 5 MB ("
					+ MAX_UPLOAD_BYTES + " bytes)");
		}

		String name = file.getOriginalFilename() == null
				|| file.getOriginalFilename().isEmpty()
						? "file"
						: file.getOriginalFilename();
		String mimeType = file.getContentType() == null
				? "application/octet-stream"
				: file.getContentType();

		// Store under a unique name: no collisions, no path tricks.
		String safeName = name.replaceAll("[^A-Za-z0-9._-]", "_");
		File stored = new File(uploadsDir, micros() + "_" + safeName);
		// transferTo needs an absolute path (a relative one would land in the
		// servlet container's temp dir); the database keeps the relative one.
		file.transferTo(stored.getAbsoluteFile());

		long id = db.insert(
				"INSERT INTO files (user_id, name, mime_type, size, path, created_at) "
						+ "VALUES (?, ?, ?, ?, ?, ?)",
				userId, name, mimeType, file.getSize(), stored.getPath(), Db.nowIso());

		return Map.of(
				"id", id,
				"url", "/files/" + id,
				"name", name,
				"size", file.getSize(),
				"mimeType", mimeType);
	}

	/**
	 * GET /files/{id} -> the stored bytes with their original Content-Type | 404
	 * Public on purpose: lets a Flutter app show images by plain URL.
	 */
	@GetMapping("/files/{id}")
	public void download(@PathVariable long id, HttpServletResponse response)
			throws IOException {
		var rows = db.jdbc.queryForList("SELECT * FROM files WHERE id = ?", id);
		if (rows.isEmpty()) throw Errors.notFound("File not found");
		var row = rows.get(0);

		File file = new File((String) row.get("path"));
		if (!file.exists()) throw Errors.notFound("File not found");

		// Written straight to the servlet response, not via ResponseEntity:
		// Spring would parse the Content-Type with MediaType.parseMediaType,
		// which rejects exotic-but-harmless uploaded values (an unknown
		// charset, a malformed type) and would turn this download into a 500.
		// The raw header goes out verbatim — no charset appended, no
		// reformatting — exactly like the Dart reference.
		response.setHeader(HttpHeaders.CONTENT_TYPE, (String) row.get("mime_type"));
		// The stored Content-Type is client-supplied; nosniff stops
		// browsers from second-guessing it into something executable.
		response.setHeader("X-Content-Type-Options", "nosniff");
		// Anyone can upload text/html or image/svg+xml, so a direct
		// visit to this URL would run their scripts on our origin
		// (stored XSS). attachment = browsers download instead of
		// rendering; the CSP sandbox neutralizes anything that still
		// renders. <img> tags and Flutter's Image.network ignore
		// both, so images keep working.
		response.setHeader("Content-Disposition", "attachment");
		response.setHeader("Content-Security-Policy", "default-src 'none'; sandbox");
		response.setContentLengthLong(file.length());
		try (var in = new FileInputStream(file)) {
			in.transferTo(response.getOutputStream());
		}
	}

	/** Microseconds since epoch — a unique-enough prefix for stored names. */
	private static long micros() {
		Instant now = Instant.now();
		return now.getEpochSecond() * 1_000_000 + now.getNano() / 1_000;
	}
}
