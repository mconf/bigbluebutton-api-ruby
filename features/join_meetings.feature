Feature: Join meeting
  To participate in a meeting
  The user needs to be able to join a created meeting

  @version-all
  Scenario: Join a meeting as moderator
    Given that a meeting was created
    When the user tries to access the link to join the meeting as moderator
    Then he is redirected to the BigBlueButton client
    # can't really check if the user is in the session because in bbb he will
    # only be listed as an attendee after stabilishing a rtmp connection

  @version-all
  Scenario: Join a meeting as attendee
    Given that a meeting was created
    When the user tries to access the link to join the meeting as attendee
    Then he is redirected to the BigBlueButton client

  @version-all
  Scenario: Join a non created meeting
    Given the default BigBlueButton server
    When the user tries to access the link to join a meeting that was not created
    Then the response is an xml with the error "invalidMeetingIdentifier"

  @version-all
  Scenario: Try to join with the wrong password
    Given that a meeting was created
    When the user tries to access the link to join the meeting using a wrong password
    Then the response is an xml with the error "invalidPassword"
