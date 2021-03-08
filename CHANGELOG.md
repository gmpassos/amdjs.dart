## 2.0.0-nullsafety.1

- Dart 2.12.0:
    - Sound null safety compatibility.
    - Update CI dart commands.
    - sdk: '>=2.12.0 <3.0.0'
- dom_tools: ^2.0.0-nullsafety.1
- swiss_knife: ^3.0.1

## 1.0.7

- dom_tools: ^1.3.14
- swiss_knife: ^2.5.16
- pedantic: ^1.9.2

## 1.0.6

- Fix mimic mode: when adding a script tag, add as `async`,
to ensure that script tag execution can happen before full
parse of main HTML document (like RequireJS does).
- dom_tools: ^1.3.7
- swiss_knife: ^2.5.8
- CI: Browser tests.

## 1.0.5

- dom_tools: ^1.3.3

## 1.0.4

- Add support for require using package configuration.
- dartfmt.
- swiss_knife: ^2.5.4

## 1.0.3

- Change SDK minimal requirement to 2.7+

## 1.0.2

- Fix API documentation.

## 1.0.1

- Added API documentation.
- Fix a small bug.

## 1.0.0

- Initial version, created by Stagehand
