// PAM backend template - Java/Spring Boot port.
//
// Start:  ./gradlew bootRun   (first run downloads Gradle + dependencies)
// Env:    PORT (default 8080), JWT_SECRET (default dev-secret-change-me)

package md.utm.pam.backend;

import java.io.IOException;
import java.util.Map;

import org.apache.catalina.core.StandardHost;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@SpringBootApplication
@RestController
public class BackendApplication implements WebMvcConfigurer {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

	/** GET /health -> 200 {"status":"ok"} — liveness check, no auth. */
	@GetMapping("/health")
	public Map<String, String> health() {
		return Map.of("status", "ok");
	}

	private final Auth auth;

	BackendApplication(Auth auth) {
		this.auth = auth;
	}

	/**
	 * Which routes require a Bearer token (Auth implements the interceptor).
	 * Everything NOT listed here is public: /health, /auth/register,
	 * /auth/login and GET /files/{id} — downloads work by plain URL so a
	 * Flutter app can show images without headers.
	 * Register your own entity's routes here, next to /notes.
	 */
	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		registry.addInterceptor(auth)
				.addPathPatterns("/me", "/notes", "/notes/*", "/files");
	}

	/**
	 * Requests Tomcat rejects before Spring even runs (e.g. an URI with an
	 * encoded slash, %2F) are answered by Tomcat's own error valve — an HTML
	 * page. Swap it for ours, which writes the contract's JSON envelope
	 * (Errors.JsonErrorReportValve).
	 */
	@Bean
	public WebServerFactoryCustomizer<TomcatServletWebServerFactory> containerErrors() {
		return factory -> factory.addContextCustomizers(context -> {
			if (context.getParent() instanceof StandardHost host) {
				host.setErrorReportValveClass(
						Errors.JsonErrorReportValve.class.getName());
			}
		});
	}

	/**
	 * Permissive CORS so a Flutter *web* build can call the API during the
	 * labs. A plain servlet filter (runs before routing): answers the
	 * OPTIONS preflight directly and stamps the headers on every response.
	 */
	@Bean
	public OncePerRequestFilter corsFilter() {
		return new OncePerRequestFilter() {
			@Override
			protected void doFilterInternal(HttpServletRequest request,
					HttpServletResponse response, FilterChain chain)
					throws ServletException, IOException {
				response.setHeader("Access-Control-Allow-Origin", "*");
				response.setHeader("Access-Control-Allow-Methods",
						"GET, POST, PUT, DELETE, OPTIONS");
				response.setHeader("Access-Control-Allow-Headers",
						"Origin, Content-Type, Authorization");
				if ("OPTIONS".equals(request.getMethod())) {
					response.setStatus(200); // preflight: done, skip routing
					return;
				}
				chain.doFilter(request, response);
			}
		};
	}
}
