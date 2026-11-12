// Authentication: register/login/me, BCrypt passwords, JWT (HS256).

package md.utm.pam.backend;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.Map;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.HandlerInterceptor;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@RestController
public class Auth implements HandlerInterceptor {

	/** Secret used to sign JWTs. Override with the JWT_SECRET env variable. */
	static final String JWT_SECRET =
			System.getenv().getOrDefault("JWT_SECRET", "dev-secret-change-me");

	private final Db db;

	Auth(Db db) {
		this.db = db;
	}

	// -----------------------------------------------------------------------
	// Route handlers
	// -----------------------------------------------------------------------

	/** POST /auth/register  {email, password, name} -> 201 {token, user} */
	@PostMapping("/auth/register")
	@ResponseStatus(HttpStatus.CREATED)
	public Map<String, Object> register(@RequestBody Map<String, Object> body) {
		String email = Errors.stringField(body, "email");
		String password = Errors.stringField(body, "password");
		String name = Errors.stringField(body, "name");
		if (email == null || !email.contains("@")) {
			throw Errors.validation("A valid email is required");
		}
		if (password == null) throw Errors.validation("password is required");
		if (name == null) throw Errors.validation("name is required");

		var existing = db.jdbc.queryForList(
				"SELECT id FROM users WHERE email = ?", email);
		if (!existing.isEmpty()) throw Errors.emailTaken();

		long id = db.insert(
				"INSERT INTO users (email, password_hash, name, created_at) "
						+ "VALUES (?, ?, ?, ?)",
				email, hashPassword(password), name, Db.nowIso());

		return Map.of(
				"token", issueToken(id),
				"user", Map.of("id", id, "email", email, "name", name));
	}

	/** POST /auth/login  {email, password} -> 200 {token, user} */
	@PostMapping("/auth/login")
	public Map<String, Object> login(@RequestBody Map<String, Object> body) {
		String email = Errors.stringField(body, "email");
		String password = Errors.stringField(body, "password");
		if (email == null || password == null) {
			throw Errors.unauthorized("Invalid email or password");
		}

		var rows = db.jdbc.queryForList("SELECT * FROM users WHERE email = ?", email);
		if (rows.isEmpty()
				|| !verifyPassword(password, (String) rows.get(0).get("password_hash"))) {
			throw Errors.unauthorized("Invalid email or password");
		}

		var user = rows.get(0);
		return Map.of(
				"token", issueToken(((Number) user.get("id")).longValue()),
				"user", Map.of("id", user.get("id"), "email", user.get("email"),
						"name", user.get("name")));
	}

	/** GET /me  (Bearer) -> 200 {id, email, name} */
	@GetMapping("/me")
	public Map<String, Object> me(@RequestAttribute("userId") long userId) {
		var rows = db.jdbc.queryForList(
				"SELECT id, email, name FROM users WHERE id = ?", userId);
		if (rows.isEmpty()) throw Errors.unauthorized();
		var user = rows.get(0);
		return Map.of("id", user.get("id"), "email", user.get("email"),
				"name", user.get("name"));
	}

	// -----------------------------------------------------------------------
	// Auth "middleware": a HandlerInterceptor that runs before every route
	// listed in BackendApplication.addInterceptors(). On success it puts the
	// user id into the request; handlers read it with @RequestAttribute.
	// -----------------------------------------------------------------------

	@Override
	public boolean preHandle(HttpServletRequest request,
			HttpServletResponse response, Object handler) throws IOException {
		String header = request.getHeader("Authorization");
		Long userId = header != null && header.startsWith("Bearer ")
				? verifyToken(header.substring("Bearer ".length()))
				: null;
		if (userId == null) {
			response.setStatus(401);
			response.setContentType("application/json");
			response.getWriter().write("{\"error\":{\"code\":\"UNAUTHORIZED\","
					+ "\"message\":\"Missing or invalid token\"}}");
			return false; // stop: the handler never runs
		}
		request.setAttribute("userId", userId);
		return true;
	}

	// -----------------------------------------------------------------------
	// JWT (HS256), implemented by hand so you can see exactly how it works.
	// A JWT is:  base64url(header) . base64url(payload) . signature
	// where signature = HMAC-SHA256("header.payload", secret).
	// -----------------------------------------------------------------------

	private static final ObjectMapper JSON = new ObjectMapper();

	/** Creates a token for [userId], valid for 7 days. `sub` holds the user id. */
	static String issueToken(long userId) {
		long now = System.currentTimeMillis() / 1000;
		String header = b64Json(Map.of("alg", "HS256", "typ", "JWT"));
		String payload = b64Json(Map.of(
				"sub", String.valueOf(userId),
				"iat", now,
				"exp", now + 7 * 24 * 60 * 60)); // 7 days
		return header + "." + payload + "." + sign(header + "." + payload);
	}

	/** Returns the user id from a valid token, or null when invalid/expired. */
	static Long verifyToken(String token) {
		String[] parts = token.split("\\.");
		if (parts.length != 3) return null;
		// MessageDigest.isEqual compares in constant time — no timing leaks.
		byte[] expected = sign(parts[0] + "." + parts[1]).getBytes(StandardCharsets.UTF_8);
		byte[] actual = parts[2].getBytes(StandardCharsets.UTF_8);
		if (!MessageDigest.isEqual(expected, actual)) return null;
		try {
			JsonNode payload = JSON.readTree(Base64.getUrlDecoder().decode(parts[1]));
			long now = System.currentTimeMillis() / 1000;
			if (now >= payload.get("exp").asLong()) return null;
			return Long.parseLong(payload.get("sub").asText());
		} catch (Exception e) {
			return null; // bad base64 / bad JSON / missing claims: all invalid
		}
	}

	private static String b64Json(Map<String, Object> data) {
		try {
			return b64(JSON.writeValueAsBytes(data));
		} catch (JsonProcessingException e) {
			throw new IllegalStateException(e); // cannot happen for a Map
		}
	}

	private static String sign(String data) {
		try {
			Mac mac = Mac.getInstance("HmacSHA256");
			mac.init(new SecretKeySpec(
					JWT_SECRET.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
			return b64(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
		} catch (GeneralSecurityException e) {
			throw new IllegalStateException(e); // HmacSHA256 always exists
		}
	}

	private static String b64(byte[] bytes) {
		return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
	}

	// -----------------------------------------------------------------------
	// Passwords: BCrypt via spring-security-crypto — only the crypto JAR, so
	// no Spring Security filter chain appears in front of our routes. BCrypt
	// salts itself; the stored string embeds algorithm, cost and salt.
	// -----------------------------------------------------------------------

	private static final BCryptPasswordEncoder BCRYPT = new BCryptPasswordEncoder();

	static String hashPassword(String password) {
		return BCRYPT.encode(password);
	}

	static boolean verifyPassword(String password, String stored) {
		return BCRYPT.matches(password, stored);
	}
}
