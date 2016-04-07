# bigbluebutton-api-ruby [<img src="http://travis-ci.org/mconf/bigbluebutton-api-ruby.png"/>](http://travis-ci.org/mconf/bigbluebutton-api-ruby)

This is a ruby gem that provides access to the API of
[BigBlueButton](http://bigbluebutton.org). See the documentation of the API
[here](http://code.google.com/p/bigbluebutton/wiki/API).

It enables a ruby application to interact with BigBlueButton by calling ruby
methods instead of HTTP requests, making it a lot easier to interact with
BigBlueButton. It also formats the responses to a ruby-friendly format and
includes helper classes to deal with more complicated API calls, such as the
pre-upload of slides.

A few features it has:

* Provides methods to perform all API calls and get the responses;
* Converts the XML responses to ruby hashes, that are easier to work with;
* Converts the string values returned to native ruby types. For instance:
  * Dates are converted DateTime objects (e.g. "Thu Sep 01 17:51:42 UTC 2011");
  * Response codes are converted to boolean (e.g. "SUCCESS" becomes `true`);
* Deals with errors (e.g. timeouts) throwing `BigBlueButtonException` exceptions;
* Support to multiple BigBlueButton API versions (see below).

## Supported versions

This gem is mainly used with [Mconf-Web](https://github.com/mconf/mconf-web) through
[BigbluebuttonRails](https://github.com/mconf/bigbluebutton_rails).
You can always use it as a reference for verions of dependencies and examples of how
to use the gem.

### BigBlueButton

The current version of this gem supports *all* the following versions of
BigBlueButton:

* 1.0
* 0.9 (includes all 0.9.x)
* 0.81
* 0.8

Older versions:

* 0.7 (including 0.7, 0.71 and 0.71a): The last version with support to 0.7*
  is [version
  1.2.0](https://github.com/mconf/bigbluebutton-api-ruby/tree/v1.2.0). It
  supports versions 0.7 and 0.8.
* 0.64: see the branch `api-0.64`. The last version with support to 0.64 is
  [version
  0.0.10](https://github.com/mconf/bigbluebutton-api-ruby/tree/v0.0.10). It
  supports versions 0.64 and 0.7.

### Ruby

Tested in rubies:

* ruby-2.2 **recommended**
* ruby-2.1
* ruby-2.0 (p353)
* ruby-1.9.3 (p484)
* ruby-1.9.2 (p290)

Use these versions to be sure it will work. Other patches and patch versions of these
rubies (e.g. ruby 1.9.3-p194 or 2.1.2) should work as well.

## Releases

For a list of releases and release notes see
[CHANGELOG.md](https://github.com/mconf/bigbluebutton-api-ruby/blob/master/CHANGELOG.md).

## Development

Information for developers of `bigbluebutton-api-ruby` can be found in [our
wiki](https://github.com/mconf/bigbluebutton-api-ruby/wiki).

The development of this gem is guided by the requirements of the project
Mconf. To know more about it visit the [project's
wiki](https://github.com/mconf/wiki/wiki).

## License

Distributed under The MIT License (MIT). See
[LICENSE](https://github.com/mconf/bigbluebutton-api-ruby/blob/master/LICENSE)
for the latest license, valid for all versions after 0.0.4 (including it), and
[LICENSE_003](https://github.com/mconf/bigbluebutton-api-ruby/blob/master/LICENSE_003)
for version 0.0.3 and all the previous versions.

## Contact

This project is developed as part of Mconf (http://mconf.org).

Mailing list:
* mconf-dev@googlegroups.com

Contact:
* Mconf: A scalable opensource multiconference system for web and mobile devices
* PRAV Labs - UFRGS - Porto Alegre - Brazil
* http://www.inf.ufrgs.br/prav/gtmconf
