# AMDJS

[![pub package](https://img.shields.io/pub/v/amdjs.svg?logo=dart&logoColor=00b9fc)](https://pub.dartlang.org/packages/amdjs)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/amdjs.dart/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/amdjs.dart/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/amdjs.dart?logo=git&logoColor=white)](https://github.com/gmpassos/amdjs.dart/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/amdjs.dart/latest?logo=git&logoColor=white)](https://github.com/gmpassos/amdjs.dart/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/amdjs.dart?logo=git&logoColor=white)](https://github.com/gmpassos/amdjs.dart/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/amdjs.dart?logo=github&logoColor=white)](https://github.com/gmpassos/amdjs.dart/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/amdjs.dart?logo=github&logoColor=white)](https://github.com/gmpassos/amdjs.dart)
[![License](https://img.shields.io/github/license/gmpassos/amdjs.dart?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/amdjs.dart/blob/master/LICENSE)
[![Funding](https://img.shields.io/badge/Donate-yellow?labelColor=666666&style=plastic&logo=liberapay)](https://liberapay.com/gmpassos/donate)
[![Funding](https://img.shields.io/liberapay/patrons/gmpassos.svg?logo=liberapay)](https://liberapay.com/gmpassos/donate)


JavaScript AMD (Asynchronous Module Definition) Dart interoperability.  

When using JS libraries that uses AMD (RequireJS), you need to call the JS function require() to correctly load
the library or unpredicted behaviors will happens.

This Dart packages helps to transparently load JS libraries from Dart, using native AMD require(), when present, or just adding
a `<script src="library.js"></script>` into DOM.

## Usage

A simple usage example:

```dart
import 'package:amdjs/amdjs.dart';

// Running on browser:
main() async {
 
  // Check if AMD is already loaded in JS context (usually when RequireJS is already loaded in DOM):
  var inNativeMode = AMDJS.isNativeImplementationPresent() ;
 
  // Load JQuery:
  var okJQuery = await AMDJS.require('jquery', '/js/jsquey.js' , globalJSVariableName: 'jquery') ;
 
  // Bootstrap recommends to add script tag inside body. The parameter `addScriptTagInsideBody` will be
  // used only when mimicking AMD, and ignored when running in native mode:
  var okBootstrap = await AMDJS.require('bootstrap', '/js/bootstrap.js', addScriptTagInsideBody: true) ;
  
  if (okJQuery && okBootstrap) {
    print('Bootstrap correctly loaded (JQuery 1st, Bootstrap 2nd).');
  }


}
```

## Common issues loading JS libraries with Dart

Since Dart, specially in development mode, uses AMD (RequireJS or similar) to load its packages,
any other JS library inserted using `<script src"library-x.js""></script>` won't load correctly. This
package (`amdjs`) helps to identify that and correctly load libraries.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/gmpassos/amdjs.dart/issues

## Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

Dart free & open-source [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).
