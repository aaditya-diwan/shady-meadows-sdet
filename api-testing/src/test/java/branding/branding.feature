@branding
Feature: Branding

  GET /branding returns the B&B's name, contact details, address and descriptions.

  Background:
    * url baseUrl
    * def brandingSchema = read('branding-schema.json')

  @smoke
  Scenario: Branding returns the B&B name and a valid contact email
    Given path 'branding'
    When method get
    Then status 200
    And match response.name == 'Shady Meadows B&B'
    # contact email must be a well-formed address([no @ or whitespace])
    And match response.contact.email == '#regex [^@\\s]+@[^@\\s]+\\.[^@\\s]+'
    And match response.contact.name == response.name

  Scenario: Branding response matches the expected schema
    Given path 'branding'
    When method get
    Then status 200
    And match response == brandingSchema
