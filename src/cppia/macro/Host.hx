package cppia.macro;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;

class Host
{
	public static function setup(exportFile:String = 'export_classes.info', ?keep:Array<String>):Void
	{
		if (!Context.defined('cpp')) return;
		if (!Context.defined('scriptable')) Compiler.define('scriptable');
		if (!Context.defined('dll_export')) Compiler.define('dll_export', exportFile);
		if (keep != null)
			for (path in keep)
				Compiler.keep(path);
		Compiler.keep('cppia');
	}
}
#end
