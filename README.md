# amdjs

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
 
  // Loaded JQuery before:
  var okJQuery = await AMDJS.require('jquery', '/js/jsquey.js' , globalJSVariableName: 'jquery') ;
 
  // Bootstrap recommends to add script tag inside body. The parameter `addScriptTagInsideBody` will be
  // used only when mimicking AMD, and ignored when running in native mode:
  var okBootstrap = await AMDJS.require('bootstrap', '/js/bootstrap.js', addScriptTagInsideBody: true) ;

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
