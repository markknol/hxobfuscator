import haxe.macro.Compiler;
import haxe.macro.Context;
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
		
		Context.onGenerate(function(types:Array<Type>)
		{
			var count = 0;
			
			// reset new class id
			var cid = 0;
			for (type in types)
			{
				switch (type.follow())
				{
					case TInst(_.get() => cl, _):
						
						// skip extern classes and interfaces
						if (cl.isExtern || cl.isInterface || cl.meta.has(":coreType")) continue;
						
						// minify private class names
						if(cl.isPrivate) cl.meta.add(":native", [macro $v {getId(cid++)}], Context.currentPos());
						
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
							var hasClassMeta = cl.meta.get().length > 0;
							inline function processField(field:ClassField)
							{
								// search for private vars, (optional skip functions because they seem to fail when overriding, sometimes)
								if ((!hasClassMeta || !field.isPublic) #if SKIP_FUNCTIONS && !field.type.match(TFun(_,_))#end)
								{
									// skip constructor and getter/setter functions
									if (field.name != "new" && !field.name.startsWith("get_") && !field.name.startsWith("set_"))
									{
										var hasFieldMeta = cl.meta.get().length > 0;
										// skip fields with meta data
										if (!hasFieldMeta)
										{
											field.meta.add(":native", [macro $v {getId(fid++)}], Context.currentPos());
											count ++;
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
		});
		
		if (!Context.defined("closure"))
		{
			//trace("`-lib closure` not found, uses simple minfication");
			#if STRIP_CHARS
			Context.onAfterGenerate(function() 
			{
				var nekoClass = "HxObfuscatorTool"; 
				Sys.command("haxe", ["-cp", Sys.getCwd() + "src", "-neko", '$nekoClass.n', "-main", '$nekoClass']);
				Sys.command("neko", [Sys.getCwd() + '$nekoClass.n', Compiler.getOutput(), Compiler.getOutput().replace(".js", ".min.js")]);
			});
			#end
		}
		#end
	}
}