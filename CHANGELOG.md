# Change Log


------------------------------------

All tickets below use references to IDs in our old issue tracking system.
To find them, search for their description or ID in the new issue tracker.

------------------------------------


## [1.7.0] - 2018-08-17

* [#29] Add support to the API call `updateRecordings` introduced in BigBlueButton 1.1.
* [#31] Fixed issue with length=nil breaking multiple recording formats.
* Call `setConfigXML` via POST and change encoding method. Fixes issues with special
  characters (such as `*`) in the config.xml.
* Add method to return the URL to `/check`.

## [1.6.0] - 2016-06-15

* Rename BigBlueButtonApi#salt to #secret

## [1.5.0] - 2016-04-07

* Add 1.0 as a supported version of BigBlueButton.
* [#1686] Automatically set the version number of a server by fetching it from
its API.
* [#1686] Fix comparison of config.xml strings that would sometimes thing XMLs
were different in cases when they were not.
* [#1695] Add support for servers that use HTTPS.

## [1.4.0] - 2015-07-20

* Updated default ruby version to 2.2.0.
* Add support for BigBlueButton 0.9 (includes all 0.9.x). Consists only in
  accepting the version "0.9", since this new API version doesn't break
  compatibility with the previous version and also doesn't add new API
  calls.

## [1.3.0] - 2014-05-11

* Drop support to BigBlueButton 0.7 and add BigBlueButton to 0.81. Includes
  support to the new API calls `getDefaultConfigXML` and `setConfigXML`.
* Reviewed all methods responses (some changed a bit) and documentation.
* Allow non standard options to be passed to **all** API calls.
* Removed method `join_meeting` that was usually not used. Should always use
  `join_meeting_url`.
* Moved the hash extension method `from_xml` to its own class to prevent
  conflicts with Rails. See
  https://github.com/mconf/bigbluebutton-api-ruby/pull/6.

## [1.2.0] - 2013-03-13

*  Allow non standard options to be passed to some API calls. These API calls are: create_meeting, join_meeting_url, join_meeting, get_recordings.
  Useful for development of for custom versions of BigBlueButton.
* Accept :record as boolean in create_meeting
* Better formatting of data returned by get_recordings

## [1.1.1] - 2013-01-30

* BigBlueButtonApi can now receive http headers to be sent in all get/post
  requests

## [1.1.0] - 2012-05-04

* Updated ruby to 1.9.3-194.
* Support to BigBlueButton 0.4 rc1.

## [1.0.0] - 2012-05-04

* Version 0.1.0 renamed to 1.0.0.

## [0.1.0] - 2011-11-25

* Support to BigBlueButton 0.8:
  * New methods for recordings: get_recordings, publish_recordings,
    delete_recordings
  * Pre-upload of slides in create_meeting
  * New parameters added in the already existent methods
  * For more information see BigBlueButton docs at
    http://code.google.com/p/bigbluebutton/wiki/API#Version_0.8
* Method signature changes: create_meeting, join_meeting_url and
  join_meeting. Optional parameters are now passed using a hash.
* Integration tests for the entire library using cucumber.
* Changed the XML parser to xml-simple (especially to solve issues with
  CDATA values).

## [0.0.11] - 2011-09-01

* The file "bigbluebutton-api" was renamed to "bigbluebutton_api". All
  "require" calls must be updated.
* Splitted the library in more files (more modular) and created rspec tests
  for it.
* Added a BigBlueButtonApi.timeout attribute to timeout get requests and
  avoid blocks when the server is down. Defaults to 2 secs.
* New method last_http_response to access the last HTTP response object.
* Automatically detects the BBB server version if not informed by the user.

## [0.0.10] - 2011-04-28

* Returning hash now will **always** have these 3 values: :returncode
  (boolean), :messageKey (string) and :message (string).
* Some values in the hash are now converted to a fixed variable type to
  avoid inconsistencies:
  * :meetingID (string)
  * :attendeePW (string)
  * :moderatorPW (string)
  * :running (boolean)
  * :hasBeenForciblyEnded (boolean)
  * :endTime and :startTime (DateTime or nil)

## [0.0.9] - 2011-04-08

* Simplied "attendees" part of the hash returned in get_meeting_info. Same
  thing done for get_meetings.

## [0.0.8] - 2011-04-06

* New method get_api_version that returns the version of the server API (>= 0.7).
* New simplified hash syntax for get_meetings. See docs for details.

## [0.0.7] - 2011-04-06

## [0.0.6] - 2011-04-05

* New method test_connection.
* Added comparison method for APIs.
* Methods attendee_url and moderator_url deprecated. Use join_meeting_url.
* Better exception throwing when the user is unreachable or the response is incorrect.
  * BigBlueButtonException has now a "key" attribute to store the
    "messageKey" returned by BBB in failures.

## 0.0.4

* Added support for BigBlueButton 0.7.
* Gem renamed from 'bigbluebutton' to 'bigbluebutton-api-ruby'.
* API functions now return a hash and instead of the XML returned by BBB.
  The XML is converted to a hash that uses symbols as keys and groups keys
  with the same name.

## 0.0.3

* Fixes module issue preventing proper throwing of exceptions.

## 0.0.1

* This is the first version of this gem. It provides an implementation of
  the 0.64 bbb API, with the following exceptions:
  * Does not implement meeting token, and instead relies on meeting id as
    the unique identifier for a meeting.
  * Documentation suggests there is way to call join_meeting as API call
    (instead of browser URL). This call currently does not work as
    documented.

[1.7.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.11...v0.1.0
[0.0.11]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.10...v0.0.11
[0.0.10]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.9...v0.0.10
[0.0.9]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.8...v0.0.9
[0.0.8]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.7...v0.0.8
[0.0.7]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v0.0.6...v0.0.7
[0.0.6]: https://github.com/mconf/bigbluebutton-api-ruby/compare/b586c4726d32e9c30139357bcbe2067f868ff36c...v0.0.6
