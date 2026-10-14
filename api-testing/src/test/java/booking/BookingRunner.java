package booking;

import io.karatelabs.junit6.Karate;

// Development runner: run from the IDE to execute only the booking features.
// Not part of `mvn test` (Surefire includes *Test.java only); from the CLI use: mvn test -Dtest=BookingRunner
class BookingRunner {

    @Karate.Test
    Karate testBooking() {
        return Karate.run("booking").relativeTo(getClass()).tags("~@ignore", "~@knownbug");
    }
}
