@version-all
Feature: Create rooms
  To be able to use BigBlueButton
  One needs to create a webconference room first

  Scenario: Create a new room
    Given the default API object
    When the create method is called with ALL the optional arguments
    Then the response to the call "create" is successful and well formatted
      And the meeting exists in the server
      And it is configured with the parameters used in the creation

  Scenario: Create a new room with default parameters
    Given the default API object
    When the create method is called with NO optional argument
    Then the response to the call "create" is successful and well formatted
      And the meeting exists in the server
      And it is configured with the parameters used in the creation

  Scenario: Try to create a room with a duplicated meeting id
    Given the default API object
    When the create method is called with a duplicated meeting id
    Then the response is an error with the key "idNotUnique"

  @wip @need-bot
  Scenario: Try to create a previously ended meeting
    Given the default API object
    When the create method is called
      # meeting needs to be running to be ended in 0.7
      And the meeting is running
      And the meeting is forcibly ended
      And the create method is called again with the same meeting id
    Then the response is an error with the key "idNotUnique"
