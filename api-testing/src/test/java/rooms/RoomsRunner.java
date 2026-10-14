package rooms;

import io.karatelabs.junit6.Karate;

// Development runner: run from the IDE to execute only the room features.
// Not part of `mvn test` (Surefire includes *Test.java only); from the CLI use: mvn test -Dtest=RoomsRunner
class RoomsRunner {

    @Karate.Test
    Karate testRooms() {
        return Karate.run("rooms").relativeTo(getClass()).tags("~@ignore", "~@knownbug");
    }
}
