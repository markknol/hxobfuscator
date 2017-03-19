import haxe.PosInfos;
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr.Metadata;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;
using haxe.macro.Tools;

using StringTools;

/**
 * Attempt to minify private fields in certain packages. 
 * @author Mark Knol
 */
class HxObfuscator
{
	public static function use()
	{
		#if !display
		
		// generate small 2-char-length fieldname
		var chars = "_aAbBcCdDeEfFgGhHiIjJkKlLmMnNoOpPqQrRsStTuUvVwWxXyYzZ".split("");
		inline function getId(id:Int) {
			return chars[Std.int((id / 10) % chars.length)] + (Std.int(id / 530) * 10 + (id % 10));
		}
		
		var forbiddenMeta = [":native", ":extern",":coreApi", ":coreType"];
		var skipMetaFilter = [":keep", ":keepInit", ":extern", ":native", ":dce", ":analyzer", ":coreApi", ":coreType"];
		function hasValidMeta(metas:MetaAccess, filter:Array<String>) 
		{
			for (name in filter) if (metas.has(name)) return false;
			return true;
		}
		
		Context.onGenerate(function(types:Array<Type>)
		{
			var optimizedFieldCount = 0;
			var fieldCount = 0;
			var optimizedTypeCount = 0;
			var typeCount = 0;
			
			// reset new class id
			var cid = 0;
			for (type in types)
			{
				typeCount ++;
				switch (type.follow())
				{
					case TInst(_.get() => cl, _):
						
						var cl:ClassType = cl;
						
						// skip extern classes and interfaces
						if (cl.isExtern || cl.isInterface || !hasValidMeta(cl.meta, forbiddenMeta) || cl.name.indexOf("Hx") != -1 ) continue;
						
						var startId =  0;
						var superClass = cl.superClass;
						while ( superClass != null)
						{
							startId += superClass.t.get().fields.get().length;
							superClass = superClass.t.get().superClass;
						}
						
						function hasFieldName(name:String)
						{
							var superClass = cl;
							while ( superClass.superClass != null)
							{
								superClass = superClass.superClass.t.get();
								var fields = superClass.fields.get().concat(superClass.statics.get());
								for (f in fields) if (f.name == name) return true;
							}
							 return false;
						}
						
						
						var hasClassMeta = cl.meta.get().length > 0;
						
						// minify class names
						if (!hasClassMeta || hasValidMeta(cl.meta, skipMetaFilter) || cl.isPrivate)
						{
							optimizedTypeCount ++;
							cl.meta.add(":native", [macro $v {getId(cid++)}], Context.currentPos());
						}
						
						// reset new field id
						var fid = 0;

						var fields:Array<ClassField> = cl.fields.get();
						var statics:Array<ClassField> = cl.statics.get();

						// search if pack is whitelisted
						var isWhiteListed = true;
						/*
						// TODO: Find out how to whitelist/blacklist packages
						var classPack = cl.pack.join(".");
						var isWhiteListed = false;
						for (pack in whiteListedPackages)
						{
							if (classPack.indexOf(pack) != -1)
							{
								isWhiteListed = true;
								break;
							}
						}
						*/
						if (isWhiteListed)
						{
							function processField(field:ClassField)
							{
								fieldCount ++;
								var fieldType = field.type.toString();
								// search for private vars, (optional skip functions because they seem to fail when overriding, sometimes)
								
								var isValidAbstract = true;
								if ( field.type.match(TAbstract(_.get() => _, _))) {
									if (field.type.toString().indexOf("Map") != -1 ) 
									{
										isValidAbstract = false;
									}
								} 
								
								if (isValidAbstract && #if SKIP_FUNCTIONS !field.type.match(TFun(_, _)) #else true #end)
								{
									//trace(field.type.toString());
									//trace(field.type);
									// skip constructor and getter/setter functions
									if (field.name != "new" && !field.name.startsWith("get_") && !field.name.startsWith("set_"))
									{
										// skip fields with meta data
										if (hasValidMeta(field.meta, skipMetaFilter))
										{
											optimizedFieldCount ++;
											
											var newFieldName = getId(startId + fid++);
											if (!hasFieldName(newFieldName))
											{
												field.meta.add(":native", [macro $v {newFieldName}], Context.currentPos());
											}
											else 
											{
												trace("found name: " + newFieldName); 
											}
										}
									}
								}
							}
							
							// process fields
							for (field in fields) processField(field);
							
							// process static fields
							for (field in statics) processField(field);
						}
					
					default:
				}
			}
			
			trace("optimized fields: " + optimizedFieldCount + "/" + fieldCount);
			trace("optimized types: " + optimizedTypeCount + "/" + typeCount);
		});
		
		if (!Context.defined("closure"))
		{ 
			function getDir(?pos:PosInfos) return Path.normalize(Path.directory(pos.fileName) + "\\..\\" )  + "/";
			
			//trace("`-lib closure` not found, uses simple minfication");
			Context.onAfterGenerate(function() 
			{
				var nekoClass = "HxObfuscatorTool"; 
				var cwd = Sys.getCwd();
				
				Sys.setCwd(getDir());
				Sys.command("haxe", ["-cp", "src", "-neko", '$nekoClass.n', "-main", '$nekoClass']);
				var output = Path.isAbsolute(Compiler.getOutput()) ? Compiler.getOutput() :  cwd + Compiler.getOutput();
				Sys.command("neko", ['$nekoClass.n', output, output.replace(".js", ".min.js")]);
				Sys.setCwd(cwd);
			});
		}
		#end
	}
}