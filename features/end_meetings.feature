Feature: End rooms
  To stop a meeting using the API
  One needs to be able to call 'end' to this meeting

  @version-all @need-bot
  Scenario: End a meeting
    Given that a meeting was created
      And the meeting is running
    When the method to end the meeting is called
    Then the response is successful and well formatted
      And the meeting should be ended

  @version-all
  Scenario: Try to end a meeting that is not running
    Given that a meeting was created
    When the method to end the meeting is called
    Then the response is successful
      And the response has the messageKey "sentEndMeetingRequest"
