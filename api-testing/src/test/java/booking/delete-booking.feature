@ignore
Feature: Delete a booking

  Reusable cleanup helper, called from the afterScenario hook in booking.feature.
  Takes bookingId and token. Asserts nothing: the booking may already have been deleted by the test itself.

  Scenario: Delete a booking
    * url baseUrl
    * configure cookies = { token: '#(token)' }
    Given path 'booking', bookingId
    When method delete
