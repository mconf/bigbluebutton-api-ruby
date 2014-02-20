@version-all
Feature: Record a meeting and manage recordings
  To record a meeting or manage the recorded meeting
  One needs be able to list the recordings, publish and unpublish them

  # We don't check if meetings will really be recorded
  # To record a meeting we need at least audio in the session
  # And also it would probably that a long time to record and process test meetings
  # For now we'll have only basic tests in this feature

  Scenario: Set a meeting to be recorded
    Given the default BigBlueButton server
    When the user creates a meeting with the record flag
    Then the response is successful and well formatted
      And the meeting is set to be recorded

  Scenario: By default a meeting will not be recorded
    Given the default BigBlueButton server
    When the user creates a meeting without the record flag
   Then the response is successful and well formatted
      And the meeting is NOT set to be recorded

  Scenario: List the available recordings in a server with no recordings
    Given the default BigBlueButton server
    When the user calls the get_recordings method
    Then the response is successful and well formatted
      And the response has the messageKey "noRecordings"

  # Possible scenarios to test in the future
  # Scenario: Record a meeting # not only set to be recorded
  # Scenario: List the available recordings
  # Scenario: Publish a recording
  # Scenario: Unpublish a recording
  # Scenario: Remove a recording
