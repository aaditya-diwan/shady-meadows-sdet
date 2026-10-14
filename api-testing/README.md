# api-testing — Karate template

A minimal, runnable [Karate](https://github.com/karatelabs/karate) API-test project for the
Shady Meadows B&B demo API (`https://automationintesting.online/api`).

- **Karate 2.1.3** (latest, `io.karatelabs` groupId, `karate-junit6`)
- **Java 21**, JUnit 6, Maven Surefire

## Layout

```
api-testing/
├── pom.xml
└── src/test/java/
    ├── ApiTest.java          # suite runner — runs ALL features in parallel (this is what `mvn test` runs)
    ├── karate-config.js      # baseUrl + credentials per environment
    ├── logback-test.xml      # logging
    └── example/
        ├── example.feature   # sample scenarios (copy this folder to start a new area)
        └── ExampleRunner.java # IDE runner for just this area (not run by `mvn test`)
```

Karate convention: `.feature` files live next to the Java runner under `src/test/java`.

## Run

```bash
# whole suite (build gate — excludes @ignore and @knownbug)
mvn test

# only the example area, from the CLI
mvn test -Dtest=ExampleRunner

# just the known-bug scenarios (documented defects, not part of the gate)
mvn test -Dkarate.options="--tags @knownbug"

# point at a different environment (see karate-config.js)
mvn test -Dkarate.env=local
```

Reports land in `target/karate-reports/` (open `karate-summary.html`); JUnit XML is written for CI.

## Add a new area

1. Copy `example/` to a new package, e.g. `booking/`.
2. Rename the feature and the `*Runner.java` (`BookingRunner`).
3. Write scenarios against `baseUrl`. `ApiTest.java` picks them up automatically — no edit needed.

## Credentials

`karate-config.js` reads `ADMIN_USER` / `ADMIN_PASSWORD` from environment variables (CI secrets) and
falls back to the public demo values `admin` / `password`.
