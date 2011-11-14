Feature: Check meeting configurations and status
  To be able to monitor BigBlueButton
  One needs to check the current meetings
  and the status and configurations of a meeting

  # TODO not working for 0.8 yet
  @version-07 @need-bot
  Scenario: Check that a meeting is running
    Given that a meeting was created
      And the meeting is running
    Then the method isMeetingRunning informs that the meeting is running

  @version-all
  Scenario: Check that a meeting is NOT running
    Given that a meeting was created
    Then the method isMeetingRunning informs that the meeting is NOT running

  @version-all
  Scenario: Check the information of a meeting
    Given that a meeting was created
    When calling the method get_meeting_info
    Then it shows all the information of the meeting that was created

  # to make sure that getMeetingInfo is returning the proper info used in create
  @version-all
  Scenario: Check the information of a meeting created with optional parameters
    Given that a meeting was created with ALL the optional arguments
    When calling the method get_meeting_info
    Then it shows all the information of the meeting that was created

  @version-all
  Scenario: List the meetings in a server
    Given that a meeting was created
    When calling the method get_meetings
    Then the created meeting should be listed in the response with proper information
