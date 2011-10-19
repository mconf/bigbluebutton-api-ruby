Feature: Create rooms
  To be able to use BigBlueButton
  One needs to create a webconference room first

  Scenario: Create a new room
    Given the default API object
    When the method to create a meeting is called with meeting ID "test-create"
    Then the response is successful and well formatted
      And the meeting exists in the server
      And it is configured with the parameters used in the creation
