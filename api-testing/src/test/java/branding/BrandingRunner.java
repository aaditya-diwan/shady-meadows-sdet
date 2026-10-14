package branding;

import io.karatelabs.junit6.Karate;

// Development runner: run from the IDE to execute only the branding features.
// Not part of `mvn test` (Surefire only includes *Test.java); use: mvn test -Dtest=BrandingRunner
class BrandingRunner {

    @Karate.Test
    Karate testBranding() {
        return Karate.run("branding").relativeTo(getClass()).tags("~@ignore", "~@knownbug");
    }
}
