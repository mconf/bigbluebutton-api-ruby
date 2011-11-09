@wip @version-all @need-bot
Feature: End rooms
  To stop a meeting using the API
  One needs to be able to call 'end' to this meeting

  Scenario: End a new meeting
    Given the default API object
      And that the method to create a meeting was called with meeting ID "test-end"
      And the meeting is running
    When the method to end the meeting is called
    Then the response is successful and well formatted
      And the flag hasBeenForciblyEnded should be set
