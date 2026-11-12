// Standard error responses. Every error in the API has the same shape:
//   {"error": {"code": "SOME_CODE", "message": "human readable text"}}
//
// Handlers never build error responses by hand — they `throw
// Errors.validation("...")` / `Errors.notFound("...")` / etc., and the
// @RestControllerAdvice below turns EVERY exception (ours and Spring's own)
// into the standard envelope. No Whitelabel page, ever.

package md.utm.pam.backend;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import org.springframework.boot.web.servlet.error.ErrorController;
import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class Errors {

	/** The exception the route handlers throw; carries status + error code. */
	static class ApiException extends RuntimeException {
		final int status;
		final String code;

		ApiException(int status, String code, String message) {
			super(message);
			this.status = status;
			this.code = code;
		}
	}

	// Factories, so handlers read like the contract: `throw Errors.notFound(...)`.

	static ApiException validation(String message) {
		return new ApiException(400, "VALIDATION_ERROR", message);
	}

	static ApiException unauthorized() {
		return unauthorized("Missing or invalid token");
	}

	static ApiException unauthorized(String message) {
		return new ApiException(401, "UNAUTHORIZED", message);
	}

	static ApiException notFound(String message) {
		return new ApiException(404, "NOT_FOUND", message);
	}

	static ApiException emailTaken() {
		return new ApiException(409, "EMAIL_TAKEN",
				"An account with this email already exists");
	}

	/** The standard error body: {"error": {"code": ..., "message": ...}}. */
	static Map<String, Object> body(String code, String message) {
		return Map.of("error", Map.of("code", code, "message", message));
	}

	/** Returns body[key] as a trimmed non-empty string, or null when missing. */
	static String stringField(Map<String, Object> body, String key) {
		return body.get(key) instanceof String s && !s.isBlank() ? s.trim() : null;
	}

	// -----------------------------------------------------------------------
	// The global exception -> envelope mapping (Spring calls these for every
	// exception that escapes a handler, an interceptor or body parsing).
	// -----------------------------------------------------------------------

	@ExceptionHandler(ApiException.class)
	ResponseEntity<Map<String, Object>> apiError(ApiException e) {
		return ResponseEntity.status(e.status).body(body(e.code, e.getMessage()));
	}

	/** Malformed/missing JSON body (Jackson could not parse it) -> 400. */
	@ExceptionHandler(HttpMessageNotReadableException.class)
	ResponseEntity<Map<String, Object>> badJson(HttpMessageNotReadableException e) {
		return apiError(validation("Body must be a JSON object"));
	}

	/** Garbage in a numeric path variable (GET /notes/7abc) -> 404, not 500. */
	@ExceptionHandler(MethodArgumentTypeMismatchException.class)
	ResponseEntity<Map<String, Object>> badPathVariable(
			MethodArgumentTypeMismatchException e) {
		return apiError(notFound("Resource not found"));
	}

	/**
	 * Unknown route, or a known path with the wrong method -> 404 with the
	 * standard envelope, exactly like the reference router (which treats
	 * both as "no such route"; the contract has no 405).
	 */
	@ExceptionHandler({ NoHandlerFoundException.class,
			NoResourceFoundException.class,
			HttpRequestMethodNotSupportedException.class })
	ResponseEntity<Map<String, Object>> routeNotFound(Exception e) {
		return apiError(notFound("Route not found"));
	}

	/** Upload over the 5 MB cap (Content-Length or counted chunked bytes). */
	@ExceptionHandler(MaxUploadSizeExceededException.class)
	ResponseEntity<Map<String, Object>> uploadTooLarge(
			MaxUploadSizeExceededException e) {
		return apiError(validation("File too large: the upload limit is 5 MB ("
				+ Files.MAX_UPLOAD_BYTES + " bytes)"));
	}

	/** Corrupt multipart body (bad boundary, truncated part, ...) -> 400. */
	@ExceptionHandler(MultipartException.class)
	ResponseEntity<Map<String, Object>> badMultipart(MultipartException e) {
		return apiError(validation("Malformed multipart/form-data body"));
	}

	/** Multipart body without the required "file" field -> 400. */
	@ExceptionHandler(MissingServletRequestPartException.class)
	ResponseEntity<Map<String, Object>> missingPart(
			MissingServletRequestPartException e) {
		return apiError(validation("Missing multipart field 'file'"));
	}

	/** Wrong Content-Type on a JSON endpoint -> 400 (the contract has no 415). */
	@ExceptionHandler(HttpMediaTypeNotSupportedException.class)
	ResponseEntity<Map<String, Object>> badMediaType(
			HttpMediaTypeNotSupportedException e) {
		return apiError(validation("Body must be JSON (Content-Type: application/json)"));
	}

	/** Anything else is a bug — same envelope, code INTERNAL, and a log line. */
	@ExceptionHandler(Exception.class)
	ResponseEntity<Map<String, Object>> internal(Exception e) {
		e.printStackTrace();
		return ResponseEntity.status(500).body(body("INTERNAL", "Internal server error"));
	}

	/** The contract's error code for an HTTP status (used by the safety nets). */
	static String codeFor(int status) {
		return switch (status) {
			case 400 -> "VALIDATION_ERROR";
			case 401 -> "UNAUTHORIZED";
			case 404 -> "NOT_FOUND";
			case 409 -> "EMAIL_TAKEN";
			default -> "INTERNAL";
		};
	}

	/**
	 * Safety net for errors raised below Spring MVC (in the container or a
	 * filter), which never reach the handlers above. Registering our own
	 * ErrorController replaces Boot's Whitelabel one.
	 */
	@RestController
	static class Fallback implements ErrorController {
		@RequestMapping("/error")
		ResponseEntity<Map<String, Object>> error(HttpServletRequest request) {
			Object status = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
			int code = status instanceof Integer i ? i : 500;
			return ResponseEntity.status(code)
					.body(body(codeFor(code), "Request failed with status " + code));
		}
	}

	/**
	 * Deepest safety net: errors Tomcat itself rejects before (or outside)
	 * the servlet — e.g. an URI with an encoded slash (%2F) — never reach
	 * Spring at all; Tomcat's built-in ErrorReportValve would answer them
	 * with its own HTML page. This replacement (registered in
	 * BackendApplication) writes the standard JSON envelope instead.
	 */
	public static class JsonErrorReportValve
			extends org.apache.catalina.valves.ErrorReportValve {
		@Override
		protected void report(org.apache.catalina.connector.Request request,
				org.apache.catalina.connector.Response response, Throwable t) {
			int status = response.getStatus();
			// Same guards as the valve we replace: only real, unreported
			// errors with nothing written yet.
			if (status < 400 || response.getContentWritten() > 0
					|| !response.setErrorReported()) {
				return;
			}
			try {
				response.setContentType("application/json");
				var writer = response.getReporter();
				if (writer != null) {
					writer.write("{\"error\":{\"code\":\"" + codeFor(status)
							+ "\",\"message\":\"Request failed with status "
							+ status + "\"}}");
					response.finishResponse();
				}
			} catch (Exception e) {
				// Reporting must never throw; worst case the body stays empty.
			}
		}
	}
}
