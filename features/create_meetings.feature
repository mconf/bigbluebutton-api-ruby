@version-all
Feature: Create rooms
  To be able to use BigBlueButton
  One needs to create a webconference room first

  Scenario: Create a new room
    Given the default API object
    When the create method is called with ALL the optional arguments
    Then the response is successful and well formatted
      And the meeting exists in the server
      And it is configured with the parameters used in the creation

  Scenario: Create a new room with default parameters
    Given the default API object
    When the create method is called with NO optional argument
    Then the response is successful and well formatted
      And the meeting exists in the server
      And it is configured with the parameters used in the creation

  # one test where an error is returned
  @wip
  Scenario: Create a room with a duplicated meeting id
