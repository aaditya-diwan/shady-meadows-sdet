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
