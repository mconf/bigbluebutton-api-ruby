Feature: End rooms
  To stop a meeting using the API
  One needs to be able to call 'end' to this meeting

  # TODO not working in version 0.8 yet
  @version-07 @need-bot
  Scenario: End a new meeting
    Given the default API object
      And that the method to create a meeting was called
      And the meeting is running
    When the method to end the meeting is called
    Then the response to the call "end" is successful and well formatted
      And the meeting should be ended

      # And the flag hasBeenForciblyEnded should be set
