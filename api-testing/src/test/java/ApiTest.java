import io.karatelabs.core.Runner;
import io.karatelabs.core.SuiteResult;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;

// Suite runner: runs every .feature on the classpath in parallel. This is what `mvn test` and CI execute.
// Per-area *Runner classes (e.g. BookingRunner) are for running one slice from the IDE and are NOT
// picked up by `mvn test` (Surefire only includes *Test.java).
class ApiTest {

    // @knownbug scenarios document open defects and are excluded from the build gate.
    // Run them explicitly with: mvn test -Dkarate.options="--tags @knownbug"
    @Test
    void run() {
        SuiteResult results = Runner.path("classpath:")
                .tags("~@ignore", "~@knownbug")
                .outputJunitXml(true)
                .outputCucumberJson(true)
                .parallel(4);
        assertFalse(results.isFailed(), String.join("\n", results.getErrors()));
    }
}
