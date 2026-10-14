@ignore
Feature: Create a throwaway room

  Reusable helper: creates a uniquely named room and returns its id.
  Callers pass the admin token and delete the room afterwards (see delete-room.feature).

  Scenario: Create a room
    * url baseUrl
    * configure cookies = { token: '#(token)' }
    * def roomName = 'karate-' + java.util.UUID.randomUUID().toString().substring(0, 8)
    Given path 'room'
    And request
      """
      {
        "roomName": "#(roomName)",
        "type": "Single",
        "accessible": false,
        "description": "Created by the Karate API tests",
        "image": "/images/room1.jpg",
        "roomPrice": 100,
        "features": ["WiFi"]
      }
      """
    When method post
    Then status 200

    # POST /room only returns { success: true }, so look the new room up by its unique name
    Given path 'room'
    When method get
    Then status 200
    * def created = karate.filter(response.rooms, r => r.roomName == roomName)
    * match created == '#[1]'
    * def roomId = created[0].roomid
