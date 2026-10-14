@ignore
Feature: Admin login

  Reusable helper: logs in as the admin user from karate-config.js and returns the session token.

  Scenario: Log in as admin
    * url baseUrl
    Given path 'auth', 'login'
    And header Content-Type = 'application/json'
    And request { username: '#(adminUser)', password: '#(adminPassword)' }
    When method post
    Then status 200
    * def token = response.token
