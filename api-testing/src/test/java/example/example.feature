Feature: Example - rooms endpoint
  # A minimal, runnable example that shows the Karate basics: baseUrl from karate-config.js,
  # path/method/status, and response matching. Copy this folder as the starting point for a new area.

  Background:
    * url baseUrl

  Scenario: GET /room returns a non-empty list of rooms
    Given path 'room'
    When method get
    Then status 200
    And match response.rooms == '#[_ > 0]'
    And match each response.rooms contains { roomid: '#number' }

  @knownbug
  Scenario: looking up a room that does not exist should 404 (currently 500)
    # Documents an open defect; excluded from the build gate. Run with:
    #   mvn test -Dkarate.options="--tags @knownbug"
    Given path 'room', 999999
    When method get
    Then status 404
