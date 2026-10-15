# Shady Meadows B&B: SDET Technical Challenge

Automated tests for the [Shady Meadows B&B](https://automationintesting.online/) platform, covering the
**API layer with Karate** and the **web UI with Playwright**, plus a **Postman** collection as a bonus.

Base URL under test: `https://automationintesting.online` (API lives under `/api`).

---

## What's covered


| Brief requirement                                                                   | Where                                       |
| ----------------------------------------------------------------------------------- | ------------------------------------------- |
| **API: Branding** (name is "Shady Meadows B&B", valid contact email)               | `api-testing` → `branding/branding.feature` |
| **API: Room inventory** (array, a room with `roomPrice > 0`)                       | `api-testing` → `rooms/rooms.feature`       |
| **API: Booking creation** (find a valid `roomid` first, correct payload + headers) | `api-testing` → `booking/booking.feature`   |
| **UI: Homepage sanity** (contact form visible, "Book now" per room)                | `ui-testing` → `tests/homepage.spec.ts`     |
| **UI: Admin auth & dashboard** (login, redirect, Logout)                           | `ui-testing` → `tests/admin-login.spec.ts`  |
| **UI Bonus: admin Rooms match homepage**                                          | `ui-testing` → `tests/admin-rooms.spec.ts`  |
| **Reporting, bugs, CI/CD notes**                                                    | this README                                 |


Beyond the required items, the suites add negative cases, boundary checks, and real bugs encoded
as tests (see [Bugs found](#bugs-found)).

---



## Repository layout

```
shady-meadows-sdet/
├── api-testing/      Karate 2.1.3 (Java 21, JUnit 6): the API suite
│   └── src/test/java/
│       ├── ApiTest.java          suite runner (what `mvn test` runs)
│       ├── karate-config.js      baseUrl + credentials per environment
│       ├── auth/ branding/ rooms/ booking/   feature files by service
│       └── */*Runner.java        per-area IDE runners (not run by `mvn test`)
├── ui-testing/       Playwright (TypeScript): the UI suite
│   ├── playwright.config.ts
│   ├── pages/        Page Objects (HomePage, AdminLoginPage, AdminPanelPage)
│   └── tests/        homepage / admin-login / admin-rooms specs
└── postman/          Shady Meadows BB collection (bonus)
```

---



## Approach

**Recon first.** Before writing anything I mapped the system from several angles: clicking through the
public site and admin panel, exploring the endpoints in Postman, reading each service's OpenAPI spec
(`/api/<service>/v3/api-docs`), and watching the real requests in the browser **DevTools → Network** tab.
That last one is how I found two non-obvious contract details: the API actually lives under `/api`, and **auth is cookie-based,** `POST /auth/login` returns the token in the body (no `Set-Cookie`) and the API
only accepts it back as `Cookie: token=<value>`; an `Authorization: Bearer` header is rejected with 401.

**What I optimised for:**

- **Reliability on a shared, resetting site.** The platform resets periodically and is used by others, so
tests are atomic and self-cleaning: the booking suite *finds an existing valid room* rather than creating
one, deletes every booking it makes, and never creates or deletes rooms on the shared site. Where scenarios
share a real room they run serially on randomised future dates so they can't clash (the API returns 409 on
overlapping dates).
- **Coverage depth.** Past the happy paths: negative cases, name-length boundaries, auth-required checks, and
known bugs captured as tests.

**Decisions worth calling out:**

- **Bugs-as-tests (**`@knownbug`**).** Each known defect is a test that asserts the *correct* behaviour, so it
fails until the bug is fixed. These are tagged `@knownbug` and **excluded from the build gate**, then run
separately (nightly / on demand) so they document the bug without breaking the pipeline.
- **API-driven UI checks.** UI tests assert against the live API rather than hard-coded values; the homepage
room list is compared to `GET /api/room`, and the admin Rooms tab is compared field-by-field to the public
homepage. This keeps them correct across data resets.
- **Page Object Model + the cookie-auth note.** UI locators live in page objects (`pages/`) using user-facing
selectors (`getByRole`, `getByTestId`), so specs read clearly and locators change in one place.

**Scope.** Everything the brief asks for is covered; the extra depth (negative/bug tests, the Postman
collection) is included as a bonus and flagged as such.

---



## Running the tests & viewing reports



### API: Karate (`api-testing/`)

Requires **Java 21** and **Maven**.

```bash
cd api-testing
mvn test                                      # build gate, excludes @ignore and @knownbug
mvn test -Dkarate.options="--tags @knownbug"  # run the known-bug scenarios (documented defects)
mvn test -Dtest=BookingRunner                 # one area, from the CLI
```

**Report:** `api-testing/target/karate-reports/karate-summary.html` (open in a browser). JUnit XML for CI is
written under the same `target` tree.

Credentials come from `ADMIN_USER` / `ADMIN_PASSWORD` env vars, falling back to the public demo
`admin` / `password`.

### UI: Playwright (`ui-testing/`)

Requires **Node**.

```bash
cd ui-testing
npm ci
npx playwright install --with-deps chromium
npx playwright test                 # whole suite (@knownbug tests fail-as-expected via test.fail)
npx playwright show-report          # open the HTML report
npx playwright test --grep @knownbug   # just the documented UI bugs
```

**Reports:** HTML in `ui-testing/playwright-report/`, JUnit XML at `ui-testing/test-results/junit.xml`.
Traces are captured on first retry and screenshots on failure.

### Postman (bonus)

Requires the **Postman CLI**. An environment file (`postman/Shady Meadows.postman_environment.json`) is
included, but the CLI doesn't strictly need it; it keeps an in-memory environment for the duration of a
run, so the response → variable → next-request chaining works headless. The file matters in the Postman
desktop app, where `pm.environment.set` writes to the selected environment.

**Pass/fail gate:** run only the deterministic folders (the happy-path booking chain plus cleanup),
which must stay green. The CLI exits non-zero if any assertion fails, so this command's exit code is the
gate:

```bash
postman collection run "postman/Shady Meadows BB.postman_collection.json" -i "Room To Booking(Happy Path)" -i "Cleanup"
```

The two folders run in order, so `Create Booking` sets `bookingId` and `Cleanup` deletes it, so nothing is
left on the shared site.

**Known-bug requests (informational, kept out of the gate).** The `(BUG) …` requests in *Booking
Validation Issue (Negative Path)* assert the *correct* behaviour, so they fail against the current API by
design: the same bugs-as-tests approach used in Karate and Playwright. Running the whole collection
therefore exits non-zero on purpose; run that folder separately to track when a bug gets fixed:

```bash
postman collection run "postman/Shady Meadows BB.postman_collection.json" -i "Booking Validation Issue(Negative Path)"
```

---



## Bugs found

A curated set of the most interesting defects (all verified against the live site). Each is also encoded as
a `@knownbug` test (**five in Karate, three in Playwright**) that asserts the correct behaviour.


| #   | Area | Severity   | Bug                                                                                                                                           | How to reproduce                                                                        |
| --- | ---- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | API  | High       | A booking with **no** `bookingdates` hangs ~31s then returns **500** instead of a fast **400** validation error                               | `POST /api/booking` with a valid body but the `bookingdates` object removed             |
| 2   | API  | High       | A booking for a **room that doesn't exist** is accepted (**201**): no referential check between bookings and rooms                           | `POST /api/booking` with `"roomid": 999999`                                             |
| 3   | API  | Medium     | Looking up a **missing numeric room** returns **500**, not **404** (`/api/room/abc` correctly 404s)                                           | `GET /api/room/999999`                                                                  |
| 4   | API  | Medium     | A booking with **check-in dates in the past** is accepted (**201**) instead of rejected                                                       | `POST /api/booking` with past `checkin`/`checkout`                                      |
| 5   | UI   | Low        | The **Logout button is shown to logged-out visitors**, so its presence isn't proof of being signed in                                        | Open `/admin` while signed out; Logout appears in the navbar                            |
| 6   | UI   | Low (a11y) | Every **room image has** `alt="Single Room"` regardless of type, and the Message field's label targets a non-existent id (no accessible name) | Inspect a Double/Suite room image's `alt`; inspect the contact Message textarea's label |
| 7   | API  | Medium     | `email` and `phone` are **required by the spec and enforced by the booking form, but not by the API**: a direct request that omits them is accepted (**201**). Client-side-only validation: anything bypassing the UI (curl, Postman, an integration) skips it | `POST /api/booking` with a valid body but no `email`/`phone` |


Additional minor inconsistencies are also documented as tests, e.g. unauthenticated reads return **403** on
`/api/booking/{id}` but **401** on `/api/booking?roomid=`.

---



## CI/CD: how I would integrate this

This repo doesn't ship a pipeline; here's how I would add one: a single **GitHub Actions** workflow at
`.github/workflows/tests.yml` with parallel jobs:

- `api-tests`: `actions/setup-java@v4` (Temurin 21, Maven cache) → `mvn test` (the gate; `@knownbug`
excluded) → upload `karate-reports` as an artifact.
- `ui-tests`: `actions/setup-node@v4` → `npm ci` → `npx playwright install --with-deps chromium` →
`npx playwright test` → upload `playwright-report` and the JUnit XML.
- `postman` (optional): install the Postman CLI and run the gate folders
(`-i "Room To Booking(Happy Path)" -i "Cleanup"`); the exit code is the gate.

**Triggers:** on `push` and `pull_request` for fast feedback, plus a **nightly** `schedule` that *also* runs
the `@knownbug` suites (informational, `continue-on-error`) so regressions and fixes to known bugs surface
without ever breaking the PR gate. Admin credentials are provided as repository **secrets**
(`ADMIN_USER` / `ADMIN_PASSWORD`); the JUnit artifacts feed the Actions test summary.

---



## Notes & assumptions

- Tests target the shared public demo, so they're written to be atomic and to leave no data behind.
- `@knownbug` tests document real defects by asserting the *correct* behaviour; they're kept out of the build
gate so the pipeline stays green while the bugs remain visible.
- Credentials default to the public `admin` / `password` and can be overridden via environment variables.

---



## Use of AI

In line with the brief's allowance, I used an AI assistant throughout, deliberately as an accelerator,
not a substitute for understanding.

- **Learning first.** Before writing the suites I worked through Playwright, Karate (v2) and Postman
properly, so the choices here are ones I can explain line by line.
- **Where it helped:** scaffolding boilerplate (page objects, config, the Maven/Playwright setup),
drafting and tightening this README, speeding up syntax lookups, and acting as a reviewer to
pressure-test decisions, e.g. the known-bug gating strategy and the Postman CLI/environment scoping.
- **What stayed mine:** the test strategy and scope; making everything atomic and self-cleaning on a
shared site; the cookie-auth discovery (found in DevTools, not generated); the API-driven UI assertions;
and every bug in the table above, each verified by hand against the live site.
- **Verification:** all three suites were run end-to-end against the live environment before submission,
so nothing here is unexecuted AI output.

Happy to walk through any file and explain the reasoning behind it.

