# hxobfuscator

> Shortens names for smaller output in Haxe/JavaScript builds. 
> This library is build as helper for JavaScript minification tools (not included).

### Introduction

Smaller field names means smaller output. 

This tool tries to generate smaller/unreadable field names to help minifiers. Google Closure Compiler / UglifyJS aren't aware of Haxe generated code, they don't take in account what is exposed or not, we can help there. Lot of fields/functions that is _not_ exposed probably can be obfuscated. For example, private fields are probably fine for obfuscation, because in general you never use reflection on private fields, unless you decorate it with `@:keep`. Public fields may also be obfuscated, but is slightly trickier because they can be typed using interfaces/typedefs, and may be part of a class that is exposed using `@:expose` or maybe is extern field. This tool tries to reduce, by decorating `@:native` on fields/functions.

### Installation

The project isn't on [haxelib](https://lib.haxe.org) yet, for now you can use:

`haxelib git hxobfuscator https://github.com/markknol/hxobfuscator.git` 

### Usage

Usage in haxe builds:

```shell
-lib hxobfuscator
# use this library

# When functions are broken runtime, disable renaming of function names
-D SKIP_FUNCTIONS

# when closure isn't used, strips many chars from the output. 
-D STRIP_CHARS


-lib closure
# The closure library plugs in the google closure compiler into your build. Make sure you use it.
# Add this library after `-lib hxobfuscator`
```

### Enabling Google Closure Compiler

Use the [closure haxelib](https://lib.haxe.org/p/closure/), add `-lib closure` to your build.hxml. Also add this lib **after** `-lib hxobfuscator` for correct processing order.

### How does it work?

In Haxe/JavaScript you can rewrites any path of a class or field during generation with the `@:native("new_field_name")` metadata. This libray attempts to add the `@:native` metadata on as much fields as possible. If the field already contains specific metadata, no rewrite is done. 

### Status

This library is very new, the obfuscator can break your build at runtime, always test the project in the browser yourself.
I have still quite some issues with functions that get obfuscated. Use `-D SKIP_FUNCTIONS` when this is the case. The lib doesn't work on all of my projects, but I have good hopes to make it find out what those issue are.

### Results

These are the first results of a relative small Haxe/JavaScript project. This project still needs SKIP_FUNCTIONS because otherwise it didn't run, still the results are promising:

| _ | Normal build | hxobfuscator + SKIP_FUNCTIONS | hxobfuscator + SKIP_FUNCTIONS + STRIP_CHARS | Closure | Closure + hxobfuscator |
| --- | --- | --- | --- | --- | --- |
| **normal** | 53.5 Kb | 45.4 Kb (-15.5%) | 38.1 Kb (-28.7%) | 33.8 Kb (-36.8%) | 30.3 Kb (-43.3%) |
| **gzipped** | 13.2 Kb | 12.1 Kb (-8.3%) | 11.2 Kb (-15.9%) | 10.5 Kb (-20.4%) | 9.93 Kb (-24.7%) |

Note: Closure Compiler is using `SIMPLE_OPTIMIZATIONS`.

### Troubleshooting

- Always test your builds if it works at run-time, there is a chance it doesn't work.
- In case it doesn't work for your build, you're just unlucky, remove the library.
- Please provide your [feedback and ideas](https://github.com/markknol/hxobfuscator/issues).

