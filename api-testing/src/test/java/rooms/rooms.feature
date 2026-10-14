@rooms
Feature: Room inventory

  GET /room returns every room that can be booked.

  Background:
    * url baseUrl
    * def roomSchema = read('room-schema.json')

  @smoke
  Scenario: Room list contains at least one room with a price
    Given path 'room'
    When method get
    Then status 200
    # the rooms must be an array
    And match response == { rooms: '#array' }
    * def pricedRooms = karate.filter(response.rooms, r => r.roomPrice > 0)
    # at least one room must have a roomPrice greater than 0
    And match pricedRooms == '#[_ > 0]'

  Scenario: Every room matches the room schema
    Given path 'room'
    When method get
    Then status 200
    # each room must have exactly the expected fields and types
    And match each response.rooms == roomSchema
