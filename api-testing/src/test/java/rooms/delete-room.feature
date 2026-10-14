@ignore
Feature: Delete a room

  Reusable helper: deletes the room with the given id. Its bookings are NOT deleted with it.

  Scenario: Delete room by id
    * url baseUrl
    * configure cookies = { token: '#(token)' }
    Given path 'room', roomId
    When method delete
    * match [202, 404] contains responseStatus
