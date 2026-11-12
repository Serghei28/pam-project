> **GreenGarden backend — выбран Java-порт шаблона (Java 17+, Spring Boot 3.5). Запуск: `./gradlew bootRun` → http://localhost:8080 (env `PORT`, `JWT_SECRET`).**

# Java + Spring Boot — portul Java

Portul Java al backend-șablonului PAM. Implementează exact
[`../openapi.yaml`](../openapi.yaml); vezi README-ul șablonului
(`../README_RO.md` / `_RU` / `_EN`) pentru contract și reguli.

## Pornire

```bash
./gradlew bootRun
```

Atât. Nu ai nevoie de Gradle sau Maven instalat — wrapper-ul (`gradlew` +
`gradle/wrapper/`) descarcă la **prima rulare** distribuția Gradle și apoi
dependențele din Maven Central (durează câteva minute o singură dată; după
aceea pornirea e rapidă). `app.db` (SQLite) și folderul `uploads/` se creează
automat la prima pornire. Cerință: doar Java 17 (`java -version`).

Alternativ, ca jar de sine stătător:

```bash
./gradlew build
PORT=8080 java -jar build/libs/backend-0.0.1-SNAPSHOT.jar
```

- Env: `PORT` (implicit 8080), `JWT_SECRET` (implicit `dev-secret-change-me`).
  Portul este legat în `application.properties` (`server.port=${PORT:8080}`)
  și funcționează identic prin `bootRun` sau `java -jar`.
- Upload-urile sunt limitate la 5 MB per fișier (`POST /files` răspunde 400
  `VALIDATION_ERROR` peste limită) — limita e verificată și pe
  `Content-Length` (refuz imediat), și numărând octeții la transfer chunked.
  Setările implicite — CORS deschis, secretul JWT de dev, limita de 5 MB —
  sunt pentru laborator, nu pentru producție.
- Descărcările (`GET /files/{id}`) pleacă cu `X-Content-Type-Options: nosniff`,
  `Content-Disposition: attachment` și
  `Content-Security-Policy: default-src 'none'; sandbox`: oricine poate
  încărca `text/html` sau `image/svg+xml`, iar fără aceste antete un link
  deschis direct în browser ar rula scriptul atacatorului pe originea API-ului
  (stored XSS). `Image.network`/`<img>` ignoră aceste antete, deci afișarea
  imaginilor în laborator nu se schimbă — Content-Type-ul rămâne fidel celui
  încărcat; dar șablonul rămâne o configurație de laborator, nu de producție.

## Verificarea contra contractului

```bash
# cu serverul pornit:
cd ../conformance
dart pub get
dart run bin/conformance.dart --base-url http://localhost:8080
```

## Structura

```
build.gradle               — dependențele (3 la număr) + versiunea Spring Boot
src/main/resources/
  application.properties   — PORT, SQLite, limita de 5 MB, fără Whitelabel
src/main/java/md/utm/pam/backend/
  BackendApplication.java  — pornire: /health, lista rutelor protejate, CORS
  Db.java                  — schema SQLite (aplicată automat la pornire),
                             helperul insert() care întoarce id-ul generat
  Auth.java                — register/login/me, parole BCrypt, JWT (HS256,
                             scris de mână) + interceptorul de autentificare
  Notes.java               — entitatea-exemplu: CRUD + paginare + căutare
  Files.java               — upload multipart, download binar cu antete anti-XSS
  Errors.java              — formatul standard de eroare: @RestControllerAdvice
                             care mapează TOATE excepțiile la plicul contractului
```

Fără JPA/Hibernate: `JdbcTemplate` și SQL parametrizat — fiecare interogare
rămâne vizibilă în cod, iar schema e un simplu `CREATE TABLE IF NOT EXISTS`
în `Db.java`.

Parolele sunt hash-uite cu **BCrypt** prin `spring-security-crypto` — doar
modulul de criptografie, nu tot Spring Security, deci niciun lanț de filtre
nu se așază peste rutele noastre (autentificarea o vezi integral în
`Auth.java`). BCrypt e alegerea idiomatică în ecosistemul Spring; salt-ul și
costul sunt încorporate în hash-ul stocat.

JWT-ul este implementat manual (~40 de linii în `Auth.java`, pe
`javax.crypto.Mac`), ca să vezi exact ce este un token: `base64url(header) .
base64url(payload) . HMAC-SHA256`. Semnătura se compară în timp constant cu
`MessageDigest.isEqual`. Fără `jjwt`/`spring-security-oauth2` — nimic de
configurat, nimic ascuns.

Autentificarea pe rutele protejate e un `HandlerInterceptor` obișnuit
(`Auth.preHandle`), înregistrat în `BackendApplication.addInterceptors()` —
lista rutelor protejate e explicită, tot ce nu e listat e public.

Erorile: handler-ele aruncă `Errors.validation(...)` / `notFound(...)` etc.,
iar `@RestControllerAdvice` din `Errors.java` transformă orice excepție —
inclusiv JSON malformat (400), rută necunoscută (404), id nenumeric în cale
(404) și upload peste 5 MB (400) — în plicul `{"error":{code,message}}`.
Un `ErrorController` propriu acoperă erorile apărute sub Spring MVC, iar
valva de raport a lui Tomcat e înlocuită cu una care scrie același plic
(`Errors.JsonErrorReportValve`) — pentru cererile pe care Tomcat le respinge
înainte de a ajunge la Spring (de exemplu un URI cu `%2F`). Nici pagina
Whitelabel, nici pagina HTML de eroare a lui Tomcat nu apar niciodată.

Notă de bootstrap: Spring Initializr nu mai generează proiecte Boot 3.x
(oferă doar ≥ 4.0), așa că scheletul a fost generat pe 4.x iar versiunea
**3.5.16** (ultima stabilă din linia 3.x, compatibilă Java 17) e fixată de
mână în `build.gradle`. Wrapper-ul livrat folosește Gradle 9.7.1.

## Adaugă-ți propria entitate

`Notes.java` este șablonul — copiază-l:

1. Adaugă un `CREATE TABLE` pentru entitatea ta în `Db.java` (cu o coloană
   `user_id` dacă aparține unui utilizator).
2. Copiază `Notes.java` în, de exemplu, `Recipes.java`; redenumește tabelul,
   ruta (`@RequestMapping("/recipes")`) și câmpurile JSON.
3. Adaugă noile căi în `BackendApplication.addInterceptors()`
   (`"/recipes", "/recipes/*"`), ca să ceară token — tot ce nu e listat
   acolo rămâne public.
4. Repornește, testează cu `curl` sau cu aplicația ta Flutter, apoi rulează
   din nou suita de conformitate ca să confirmi că contractul de bază încă
   trece.
