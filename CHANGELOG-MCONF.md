# Change Log
This is a changelog of extensions made for the custom BigBlueButton's API built by Mconf.

## [1.9.0-mconf] - 2023-01-12
### Added
* [LTI-108] Add `get_all_meetings` method. Without additional parameters, returns the same as
  `get_meetings`.
  Its main purpose is to allow custom APIs to implement additional parameters (e.g. to append
  the recordings associated with the meetings in the response) keeping the original
  `get_meetings` call untouched.
  - PRs: [#53], [#54]

<!-- Cards -->
[LTI-108]: https://www.notion.so/mconf/Corrigir-get_all_meetings-no-LTI-b7ae974e2259409b8c67e125a01152e9


<!-- PRs -->
[#53]: https://github.com/mconf/bigbluebutton-api-ruby/pull/53
[#54]: https://github.com/mconf/bigbluebutton-api-ruby/pull/54

<!-- Versions -->
[Unreleased]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.8.0...v1.9.0-mconf-rc1
[1.9.0-mconf]: https://github.com/mconf/bigbluebutton-api-ruby/compare/v1.8.0...v1.9.0-mconf
