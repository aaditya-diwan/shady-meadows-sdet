package example;

import io.karatelabs.junit6.Karate;

// Development runner: run from the IDE to execute only the example features.
// Not part of `mvn test` (Surefire includes *Test.java only); from the CLI use: mvn test -Dtest=ExampleRunner
class ExampleRunner {

    @Karate.Test
    Karate testExample() {
        return Karate.run("example").relativeTo(getClass()).tags("~@ignore", "~@knownbug");
    }
}
