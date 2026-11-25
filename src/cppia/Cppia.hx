package cppia;

import haxe.io.Bytes;

#if (cpp && scriptable)
@:cppInclude('hx/Scriptable.h')
#end
class Cppia
{
	public static inline final EXTENSION:String = '.cppia';

	public static var available(get, never):Bool;
	public static var onError:CppiaError->Void = null;
	public static var lastError(default, null):Null<CppiaError>;
	public static var entryClasses:Array<String> = ['Main', 'Script'];
	public static var callNames:Map<String, String> = new Map();

	static var current:Array<CppiaModule> = [];

	public static inline function isScript(path:String):Bool
	{
		return path != null && StringTools.endsWith(path.toLowerCase(), EXTENSION);
	}

	public static function load(path:String, autoStart:Bool = true, ?args:Array<Dynamic>):Null<CppiaModule>
	{
		#if (cpp && scriptable && sys)
		if (path == null || !sys.FileSystem.exists(path)) return null;
		var module:CppiaModule = null;
		try
		{
			module = fromBytes(sys.io.File.getBytes(path), path, false);
		}
		catch (e:Dynamic)
		{
			report(null, path, 'load', e);
			return null;
		}
		if (module == null) return null;
		module.modifiedTime = modified(path);
		if (autoStart) module.start(args);
		return module;
		#else
		return null;
		#end
	}

	public static function fromBytes(bytes:Bytes, name:String = 'script', autoStart:Bool = true, ?args:Array<Dynamic>):Null<CppiaModule>
	{
		#if (cpp && scriptable)
		if (bytes == null || bytes.length == 0) return null;
		try
		{
			var native:cpp.cppia.Module = cpp.cppia.Module.fromData(bytes.getData());
			if (native == null) return null;
			var module:CppiaModule = new CppiaModule(name, native);
			module.boot();
			if (autoStart) module.start(args);
			return module;
		}
		catch (e:Dynamic)
		{
			report(null, name, 'load', e);
			return null;
		}
		#else
		return null;
		#end
	}

	public static function fromString(source:String, name:String = 'script', autoStart:Bool = true, ?args:Array<Dynamic>):Null<CppiaModule>
	{
		return source == null ? null : fromBytes(Bytes.ofString(source), name, autoStart, args);
	}

	public static function enableJit(enable:Bool = true):Void
	{
		#if (cpp && scriptable)
		untyped __cpp__('::hx::EnableJit({0})', enable);
		#end
	}

	public static function register(instance:Dynamic):Dynamic
	{
		if (instance != null && current.length > 0) current[current.length - 1].addInstance(instance);
		return instance;
	}

	@:allow(cppia.CppiaModule)
	static function pushCurrent(module:CppiaModule):Void
	{
		current.push(module);
	}

	@:allow(cppia.CppiaModule)
	static function popCurrent():Void
	{
		current.pop();
	}

	public static function modified(path:String):Float
	{
		#if sys
		try
		{
			return sys.FileSystem.stat(path).mtime.getTime();
		}
		catch (e:Dynamic) {}
		#end
		return 0;
	}

	public static function report(module:Null<CppiaModule>, path:String, field:String, error:Dynamic):Void
	{
		var stack:String = '';
		try
		{
			stack = haxe.CallStack.toString(haxe.CallStack.exceptionStack());
		}
		catch (e:Dynamic) {}
		lastError = {module: module, path: path, field: field, error: error, stack: stack};
		if (onError != null) onError(lastError);
	}

	public static function describe(error:CppiaError):String
	{
		if (error == null) return '';
		var where:String = error.field != null && error.field.length > 0 ? '${error.path} (${error.field})' : error.path;
		return 'Cppia error in $where: ${Std.string(error.error)}';
	}

	static inline function get_available():Bool
	{
		return #if (cpp && scriptable) true #else false #end;
	}
}
