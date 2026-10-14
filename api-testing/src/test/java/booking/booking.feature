@booking
Feature: Booking
  Background:
    * url baseUrl
    * def bookingSchema = read('booking-schema.json')
    * def auth = callonce read('classpath:auth/login.feature')
    * def room = callonce read('classpath:rooms/find-room.feature')
    * def roomId = room.roomId
    // Auth is cookie-based: /auth/login returns the token in the body, and the API only
    // honours it as "Cookie: token=<value>". Authorization: Bearer is rejected (401).
    * configure cookies = { token: '#(auth.token)' } 
    * def createdBookingIds = []
    * def bookingDates = 
      """
      function(slot) {
        // Each scenario books inside its own 30-day slot so scenarios running in parallel never overlap.
        // The random start inside the slot avoids clashing with bookings left by other users of the shared site.
        var dayMs = 24 * 60 * 60 * 1000;
        var offsetDays = 60 + slot * 30 + Math.floor(Math.random() * 25);
        var checkin = new Date(Date.now() + offsetDays * dayMs);
        var checkout = new Date(checkin.getTime() + 2 * dayMs);
        var iso = function(d) { return d.toISOString().slice(0, 10) };
        return { checkin: iso(checkin), checkout: iso(checkout) };
      }
      """
      * configure afterScenario =
      """
      function() {
        var ids = karate.get('createdBookingIds');
        for (var i = 0; i < ids.length; i++) {
          try {
            karate.call('classpath:booking/delete-booking.feature', { bookingId: ids[i], token: auth.token });
          } catch (e) {
            karate.log('cleanup of booking', ids[i], 'failed:', e);
          }
        }
      }
      """

  @smoke
  Scenario: A booking is created for a valid room and can be read back
    * def dates = bookingDates(0)
    * def booking = read('booking-request.json')
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request booking
    When method post
    Then status 201
    * createdBookingIds.push(response.bookingid)
    # created booking must match the booking schema
    And match response == bookingSchema
    # created booking must echo what was sent
    And match response contains booking

    * def bookingId = response.bookingid
    Given path 'booking', bookingId
    When method get
    Then status 200
    # stored booking must match what was sent
    And match response contains booking
    And match response.bookingid == bookingId

  Scenario: A deleted booking can no longer be read
    * def dates = bookingDates(1)
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request read('booking-request.json')
    When method post
    Then status 201
    * def bookingId = response.bookingid
    * createdBookingIds.push(bookingId)

    Given path 'booking', bookingId
    When method delete
    Then status 202

    Given path 'booking', bookingId
    When method get
    Then status 404

  Scenario: A room cannot be double-booked for the same dates
    * def dates = bookingDates(2)
    * def booking = read('booking-request.json')
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request booking
    When method post
    Then status 201
    * createdBookingIds.push(response.bookingid)

    Given path 'booking'
    And header Content-Type = 'application/json'
    And request booking
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 409
  Scenario: Bookings cannot be read without the admin token
    * configure cookies = null
    Given path 'booking'
    And param roomid = roomId
    When method get
    # reading bookings without a token must be refused
    * match [401, 403] contains responseStatus

  Scenario Outline: A booking with first name '<firstname>' and last name '<lastname>' returns <expectedStatus>
    * def dates = bookingDates(slot)
    * def booking = read('booking-request.json')
    * set booking.firstname = firstname
    * set booking.lastname = lastname
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request booking
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then match responseStatus == expectedStatus

    # names must be 3-18 characters (first) and 3-30 characters (last)
    Examples:
      | firstname           | lastname                        | expectedStatus! | slot! |
      | Ab                  | Tester                          | 400             | 3     |
      | Abc                 | Tester                          | 201             | 4     |
      | Abcdefghijklmnopqr  | Tester                          | 201             | 5     |
      | Abcdefghijklmnopqrs | Tester                          | 400             | 6     |
      | Karate              | Ab                              | 400             | 7     |
      | Karate              | Abc                             | 201             | 8     |
      | Karate              | Abcdefghijklmnopqrstuvwxyzabcd  | 201             | 9     |
      | Karate              | Abcdefghijklmnopqrstuvwxyzabcde | 400             | 10    |

  # ---------------------------------------------------------------------------------------------
  # Known bugs: each scenario asserts the correct behaviour and fails until the API is fixed.
  # Excluded from the build gate; run with: mvn test -Dkarate.options="--tags @knownbug"
  # ---------------------------------------------------------------------------------------------

  @knownbug
  Scenario: A booking without dates is rejected quickly with 400 (actual: 500 after ~31s)
    * def booking = read('booking-request.json')
    * remove booking.bookingdates
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request booking
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    * configure continueOnStepFailure = true
    # missing dates must be a validation error
    * match responseStatus == 400
    # validation must fail fast, not after a timeout
    * match responseTime == '#? _ < 2000'

  @knownbug
  Scenario: A check-in date in the past is rejected (actual: 201 Created)
    * def dates = { checkin: '2020-01-10', checkout: '2020-01-12' }
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 400

  @knownbug
  Scenario: A booking for a room that does not exist is rejected (actual: 201 Created)
    * def roomId = 999999
    * def dates = bookingDates(11)
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    # an unknown room must be a client error, never a created booking
    * match [400, 404] contains responseStatus

  @knownbug
  Scenario: Check-out before check-in is a validation error (actual: 409 Conflict)
    * def dates = bookingDates(12)
    * def dates = { checkin: '#(dates.checkout)', checkout: '#(dates.checkin)' }
    Given path 'booking'
    And header Content-Type = 'application/json'
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 400
