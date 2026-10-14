@booking
@parallel=false
Feature: Booking
  # Scenarios book an existing room from the live inventory (nothing is created on the shared
  # demo site). They run serially and on random future dates so they never clash with each
  # other on the same room + dates (which the API rejects with 409).

  Background:
    * url baseUrl
    * def bookingSchema = read('booking-schema.json')
    * def auth = callonce read('classpath:auth/login.feature')
    # Auth is cookie-based: /auth/login returns the token in the body, and the API only
    # honours it as "Cookie: token=<value>". Authorization: Bearer is rejected (401).
    * configure cookies = { token: '#(auth.token)' }
    # Find a valid roomid first (as the brief asks): pick a priced room from the live list.
    Given path 'room'
    When method get
    Then status 200
    * def roomId = karate.filter(response.rooms, function(r){ return r.roomPrice > 0 })[0].roomid
    * def createdBookingIds = []
    * def futureDate =
      """
      function(daysFromNow) {
        var d = new Date(Date.now() + daysFromNow * 24 * 60 * 60 * 1000);
        return d.toISOString().slice(0, 10);
      }
      """
    # random far-future window so repeated runs and other demo users rarely overlap
    * def startOffset = 30 + Math.floor(Math.random() * 300)
    * def dates = { checkin: '#(futureDate(startOffset))', checkout: '#(futureDate(startOffset + 2))' }
    * configure afterScenario =
      """
      function() {
        var token = karate.get('auth').token;
        var ids = karate.get('createdBookingIds');
        for (var i = 0; i < ids.length; i++) {
          try {
            karate.call('classpath:booking/delete-booking.feature', { bookingId: ids[i], token: token });
          } catch (e) {
            karate.log('cleanup of booking', ids[i], 'failed:', e);
          }
        }
      }
      """

  @smoke
  Scenario: A booking is created for a valid room and can be read back
    * def booking = read('booking-request.json')
    Given path 'booking'
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
    Given path 'booking'
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
    * def booking = read('booking-request.json')
    Given path 'booking'
    And request booking
    When method post
    Then status 201
    * createdBookingIds.push(response.bookingid)

    Given path 'booking'
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

  Scenario: A booking cannot be updated or deleted without the admin token
    Given path 'booking'
    And request read('booking-request.json')
    When method post
    Then status 201
    * def original = response
    * createdBookingIds.push(original.bookingid)

    * configure cookies = null
    * def update = read('booking-request.json')
    * set update.firstname = 'Intruder'
    Given path 'booking', original.bookingid
    And request update
    When method put
    # updating without a token must be refused
    * match [401, 403] contains responseStatus

    Given path 'booking', original.bookingid
    When method delete
    # deleting without a token must be refused
    * match [401, 403] contains responseStatus

    * configure cookies = { token: '#(auth.token)' }
    Given path 'booking', original.bookingid
    When method get
    Then status 200
    # the booking must be untouched
    And match response == original

  Scenario Outline: A booking with first name '<firstname>' and last name '<lastname>' is accepted
    * def booking = read('booking-request.json')
    * set booking.firstname = firstname
    * set booking.lastname = lastname
    Given path 'booking'
    And request booking
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 201

    # names must be 3-18 characters (first) and 3-30 characters (last): these sit on the boundaries
    Examples:
      | firstname          | lastname                       |
      | Abc                | Tester                         |
      | Abcdefghijklmnopqr | Tester                         |
      | Karate             | Abc                            |
      | Karate             | Abcdefghijklmnopqrstuvwxyzabcd |

  Scenario Outline: A booking with first name '<firstname>' and last name '<lastname>' is rejected with '<error>'
    * def booking = read('booking-request.json')
    * set booking.firstname = firstname
    * set booking.lastname = lastname
    Given path 'booking'
    And request booking
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 400
    # the error must name the broken rule, so a 400 for some other reason does not pass
    And match response == { errors: ['#(error)'] }

    # names must be 3-18 characters (first) and 3-30 characters (last): these sit just outside
    Examples:
      | firstname           | lastname                        | error                         |
      | Ab                  | Tester                          | size must be between 3 and 18 |
      | Abcdefghijklmnopqrs | Tester                          | size must be between 3 and 18 |
      | Karate              | Ab                              | size must be between 3 and 30 |
      | Karate              | Abcdefghijklmnopqrstuvwxyzabcde | size must be between 3 and 30 |

  # ---------------------------------------------------------------------------------------------
  # Known bugs: each scenario asserts the correct behaviour and fails until the API is fixed.
  # Excluded from the build gate; run with: mvn test -Dkarate.options="--tags @knownbug"
  # ---------------------------------------------------------------------------------------------

  @knownbug
  Scenario: A booking without dates is rejected quickly with 400 (actual: 500 after ~31s)
    * def booking = read('booking-request.json')
    * remove booking.bookingdates
    Given path 'booking'
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
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 400

  @knownbug
  Scenario: A booking for a room that does not exist is rejected (actual: 201 Created)
    * def roomId = 999999
    Given path 'booking'
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    # an unknown room must be a client error, never a created booking
    * match [400, 404] contains responseStatus

  @knownbug
  Scenario: Check-out before check-in is a validation error (actual: 409 Conflict)
    * def dates = { checkin: '#(futureDate(32))', checkout: '#(futureDate(30))' }
    Given path 'booking'
    And request read('booking-request.json')
    When method post
    * if (responseStatus == 201) createdBookingIds.push(response.bookingid)
    Then status 400
