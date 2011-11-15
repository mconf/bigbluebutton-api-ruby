@version-08
Feature: Record a meeting and manage recordings
  To record a meeting or manage the recorded meeting
  One needs be able to list the recordings, publish and unpublish them

  # we don't check if it will really be recorded b/c it would that a long time
  # better check that the flag was set and trust the bbb server
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

  # TODO how to be sure that the server has recorded meetings?
  # Scenario: List the available meetings
  #   Given the default BigBlueButton server
  #     And 3 recorded meetings
  #   When the user calls the get_recordings method
  #   Then the response is successful and well formatted
  #     And the recorded meetings are listed in the response

  # TODO how to be sure that the server has NO recorded meetings?
  Scenario: List the available meetings in a server with no recordings
    Given the default BigBlueButton server
    When the user calls the get_recordings method
    Then the response is successful and well formatted
      And the response has the messageKey "noRecordings"

  # TODO how to be sure that the server has recorded meetings?
  # Scenario: Publish a recording
  #   Given the default BigBlueButton server
  #     And a recorded but unpublished meeting
  #   When the user calls the publish_recordings method
  #   Then the target recordings will be published

  # TODO how to be sure that the server has recorded meetings?
  # Scenario: Unpublish a recording
  #   Given the default BigBlueButton server
  #     And a recorded but unpublished meeting
  #   When the user calls the publish_recordings method
  #   Then the target recordings will be published

  # TODO how to be sure that the server has recorded meetings?
  # Scenario: Remove a recording
  #   Given the default BigBlueButton server
  #     And 3 recorded meetings
  #   When the user calls the delete_recordings method
  #   Then the target recordings will be deleted
