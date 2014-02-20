@version-all
Feature: Pre-upload slides
  To have presentations ready in the meeting when the users join
  One needs to pre-upload these presentations when the meeting is created

  Scenario: Pre-upload presentations
    Given the default BigBlueButton server
    When the user creates a meeting pre-uploading the following presentations:
      | type | presentation                   |
      | url  | http://www.samplepdf.com/sample.pdf |
      | file | extras/test-presentation.pdf        |
    Then the response is successful and well formatted
    # OPTIMIZE: There's no way to check if the presentation is really in the meeting
    #  And these presentations should be available in the meeting as it begins
