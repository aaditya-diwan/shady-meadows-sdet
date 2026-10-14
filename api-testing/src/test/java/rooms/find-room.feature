@ignore
Feature: Find a bookable room

  Reusable helper: returns the id of the first room with a price

  Scenario: Find a room with a price
    * url baseUrl
    Given path 'room'
    When method get
    Then status 200
    * def pricedRooms = karate.filter(response.rooms, r => r.roomPrice > 0)
    * assert pricedRooms.length > 0
    * def roomId = pricedRooms[0].roomid
