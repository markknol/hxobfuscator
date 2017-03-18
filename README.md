# hxminifier

> Renames private fields to small names for smaller output in Haxe/JavaScript builds. 
> This library is build as helper for JavaScript minification tools (not included).

### Introduction

In JavaScript, there is no such thing as private fields. Since minification tools like Google Closure Compiler aren't aware of Haxe generated code, they don't take in account such fields can be optimized. 
The assumption of this library is that in general you never use reflection on private fields and therefore private fields could be safely renamed to smaller names without issues.
Smaller field names means smaller output. hxminifier uses smart naming which also should lead to better GZIP compression. 

### Installation

The project isn't on HaxeLib yet, so for now you can use:

`haxelib git hxminifier https://github.com/markknol/hxminifier.git` 

### Usage

Usage in haxe builds:

```hxml
-lib hxMinifier
# use this library

# When functions are broken runtime, disable renaming of function names
-D SKIP_FUNCTIONS

# when closure isn't used, strips all /n /r /t from the output. WARN; this can break your strings.
-D STRIP_CHARS


-lib closure
# The closure library plugs in the google closure compiler into your build. Make sure you use it.
```

### Enabling Google Closure Compiler

Use the [closure haxelib](https://lib.haxe.org/p/closure/), add `-lib closure` to your build.hxml. 

### How does it work?

In Haxe/JavaScript you can rename anything with the `@:native("new_field_name")` metadata. This libray adds the `@:native` metadata on as much private fields as possible. If the field already has another meta data, the field is skipped. In my assumption its safer to keep it as is in that case, but this might change later.

### Troubleshooting

- Always test your builds if it works at run-time, there is a chance it doesn't work.
- In case it doesn't work for your build, you're just unlucky, remove the library.
- Please provide your [feedback and ideas](https://github.com/markknol/hxminifier/issues).