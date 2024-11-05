### Unreleased

### Version 1.4.0
Release date: 2024-11-05

* Support Rails 8.0 and 8.1 (#110, #111)

* More descriptive error messages (#108)

### Version 1.3.0
Release date: 2023-08-17

* Fix `undiscard` so it returns false instead of nil when the record isn't
  discarded (#95, #96)

### Version 1.2.1
Release date: 2021-12-16

* Support for ActiveRecord 7

### Version 1.2.0
Release date: 2020-02-17

* Add `discard_all!` and `undiscard_all!`
* Add `undiscarded?` and `kept?` to match the scopes of the same names

### Version 1.1.0
Release date: 2019-05-03

* Support for ActiveRecord 6
* `discard_all` and `undiscard_all` now return affected records
* Add `discard!` and `undiscard!`

### Version 1.0.0
Release date: 2018-03-16

* Add undiscard callbacks and `.undiscard_all`

### Version 0.2.0
Release date: 2017-11-22

* Add `.discard_all`
* Add `undiscarded` scope
* Add callbacks

### Version 0.1.0
Release date: 2017-04-28

* Initial version!
