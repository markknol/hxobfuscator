import haxe.PosInfos;
import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr.FieldType;
import haxe.macro.Expr.Metadata;
import haxe.macro.Type;

using haxe.macro.Tools;
#end
using StringTools;

/**
 * Attempt to minify private fields in certain packages.
 * @author Mark Knol
 */
class HxObfuscator {
	static var nameCache:Map<String, String> = new Map();
	static var forbiddenMeta = [":native", ":extern", ":coreApi", ":coreType"];
	static var skipMetaFilter = [
		":keep",
		":keepInit",
		":extern",
		":native",
		":dce",
		":analyzer",
		":coreApi",
		":coreType"
	];
	static var skipClassNames = [
		"StringMap",
		"ObjectMap",
		"IntMap",
		"List",
		"IMap",
		"Map_Impl_",
		"js_Boot",
		"Std",
		"Math"
	];

	static var chars = "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
		.split("");

	static var optimizedFieldCount = 0;
	static var fieldCount = 0;
	static var optimizedTypeCount = 0;
	static var typeCount = 0;

	static var cid = 0;
	static var nameId = 0;

	static var logContent:String = "";

	static inline function log<T>(value:T) {
		#if hxobfuscator_savelog
		logContent += value + "\r\n";
		#end
	}

	static function main() {}

	public static function use() {
		#if (!display && !hxobfuscator_disabled)
		Context.onGenerate(function(types:Array<Type>) {
			var interfaceTypes:Array<ClassType> = [];
			var rootClassTypes:Array<ClassType> = [];
			var extendedClassTypes:Array<ClassType> = [];

			for (type in types) {
				typeCount++;
				switch (type.follow()) {
					case TInst(_.get() => cl, _):
						var cl:ClassType = cl;

						// skip extern classes
						if (cl.isExtern) {
							log("Skipped (extern): " + cl.name);
							continue;
						}
						// skip classes with forbidden meta data
						if (!hasValidMeta(cl.meta, forbiddenMeta)) {
							log("Skipped (meta): " + cl.name);
							continue;
						}
						// skip classes that start with Hx (HxOverrides and friends)
						if (cl.name != null && (cl.name.startsWith("Hx") || cl.name.startsWith("hx_") || cl.name.startsWith("$"))) {
							log("Skipped (hx): " + cl.name);
							continue;
						}

						if (skipClassNames.indexOf(cl.name) > -1) {
							log("Skipped (className): " + cl.name);
							continue;
						}

						if (isIterator(cl)) {
							log("Skipped (iterator): " + cl.name);
							continue;
						}

						if (cl.isInterface) {
							interfaceTypes.push(cl);
						} else if (cl.superClass == null) {
							rootClassTypes.push(cl);
						} else {
							extendedClassTypes.push(cl);
						}

					default:
				}
			}

			processClassType(interfaceTypes);
			processClassType(rootClassTypes);
			processClassType(extendedClassTypes);

			trace("optimized fields: " + optimizedFieldCount + "/" + fieldCount);
			trace("optimized types: " + optimizedTypeCount + "/" + typeCount);

			#if hxobfuscator_savelog
			File.saveContent("obfuscator.log", logContent);
			logContent = logContent.replace(":", "</td><td>");
			logContent = logContent.replace("(", "</td><td>");
			logContent = logContent.replace(")", "</td><td>");
			logContent = logContent.replace("\r\n", "</td></tr>\n<tr><td>");
			logContent = logContent = "<table style='width:100%'><tr><td>" + logContent + "</td></tr></table>";
			File.saveContent("obfuscator.html", logContent);
			#end
		});

		if (!Context.defined("closure") && !Context.defined("uglifyjs")) {
			function getDir(?pos:PosInfos)
				return Path.normalize(Path.directory(pos.fileName) + "\\..\\") + "/";

			// trace("`-lib closure` not found, uses simple minfication");
			Context.onAfterGenerate(function() {
				var nekoClass = "HxObfuscatorTool";
				var cwd = Sys.getCwd();

				Sys.setCwd(getDir());
				Sys.command("haxe", ["-cp", "src", "-neko", '$nekoClass.n', "-main", '$nekoClass']);
				var output = Path.isAbsolute(Compiler.getOutput()) ? Compiler.getOutput() : cwd + Compiler.getOutput();
				Sys.command("neko", ['$nekoClass.n', output, output.replace(".js", ".min.js")]);
				Sys.setCwd(cwd);
			});
		}
		#end
	}

	private static function isIterator(cl:ClassType):Bool {
		var fields = cl.fields.get();
		var hasHasNext = false;
		var hasNext = false;

		for (f in fields) {
			if (f.name == "iterator")
				return true; // iterable
			if (f.name == "hasNext")
				hasHasNext = true; // iterator
			if (f.name == "next")
				hasNext = true; // iterator
			if (hasNext && hasHasNext)
				return true;
		}
		return false;
	}

	static function processClassType(types:Array<ClassType>) {
		for (cl in types) {
			var hasClassMeta = cl.meta.get().length > 0;

			// minify class names
			if (!hasClassMeta || hasValidMeta(cl.meta, skipMetaFilter) || cl.isPrivate) {
				optimizedTypeCount++;
				cl.meta.add(":native", [macro $v{getId(cl.pack.join(".") + cl.name)}], Context.currentPos());
				log("Renamed (type): " + cl.name + " = " + getId(cl.name));
			} else {
				break;
			}
			var fields:Array<ClassField> = cl.fields.get();
			var statics:Array<ClassField> = cl.statics.get();

			// search if pack is whitelisted
			var isWhiteListed = true;
			if (isWhiteListed) {
				function processField(field:ClassField) {
					fieldCount++;
					var fieldType = field.type.toString();
					// search for private vars, (optional skip functions because they seem to fail when overriding, sometimes)

					var isValidAbstract = true;
					if (field.type.match(TAbstract(_.get() => _, _))) {
						if (field.type.toString().indexOf("Map") != -1) {
							isValidAbstract = false;
						}
					}

					if (isValidAbstract && #if SKIP_FUNCTIONS !field.type.match(TFun(_, _)) #else true #end) {
						// trace(field.type.toString());
						// trace(field.type);

						// skip constructor and getter/setter functions
						if (field.name != "new" && !field.name.startsWith("get_") && !field.name.startsWith("set_")) {
							// skip fields with meta data
							if (hasValidMeta(field.meta, skipMetaFilter)) {
								optimizedFieldCount++;

								var newFieldName = getId(field.name);

								field.meta.add(":native", [macro $v{newFieldName}], Context.currentPos());

								var what = field.type.match(TFun(_, _)) ? "function" : "field";
								log("Renamed (" + what + "): " + cl.name + "." + field.name + " = " + newFieldName);
							}
						}
					}
				}

				// process fields
				for (field in fields)
					processField(field);

				// process static fields
				for (field in statics)
					processField(field);
			}
		}
	}

	// generate small fieldname
	static inline function getShortId(n:Int):String {
		var s = "";
		do {
			s = chars[n & (32 - 1)] + s;
			n >>>= 5;
		} while (n > 0);
		return s;
	}

	static function getId(name:String) {
		if (nameCache.exists(name)) {
			return nameCache.get(name);
		} else {
			var id = getShortId(nameId++);
			nameCache.set(name, id);
			return id;
		}
	}

	static function hasValidMeta(metas:MetaAccess, filter:Array<String>):Bool {
		for (name in filter)
			if (metas.has(name))
				return false;
		return true;
	}
}
