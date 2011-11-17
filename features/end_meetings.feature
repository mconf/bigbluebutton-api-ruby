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

  # in 0.7 ending a meeting that is not running generates an error
  @version-07
  Scenario: Try to end a meeting that is not running in 0.7
    Given that a meeting was created
    When the method to end the meeting is called
    Then the response is an error with the key "notFound"

  # in 0.8 ending a meeting that is not running is ok
  @version-08
  Scenario: Try to end a meeting that is not running in 0.8
    Given that a meeting was created
    When the method to end the meeting is called
    Then the response is successful
      And the response has the messageKey "sentEndMeetingRequest"
