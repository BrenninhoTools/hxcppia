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
	public static var profiling:Bool = false;
	public static var validateHeaders:Bool = true;

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
		if (validateHeaders && format(bytes) == INVALID)
		{
			report(null, name, 'header', 'Not a cppia script');
			return null;
		}
		try
		{
			var native:cpp.cppia.Module = cpp.cppia.Module.fromData(bytes.getData());
			if (native == null) return null;
			var module:CppiaModule = new CppiaModule(name, native);
			module.hash = hash(bytes);
			module.size = bytes.length;
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

	public static function format(bytes:Bytes):CppiaFormat
	{
		if (bytes == null || bytes.length < 6) return INVALID;
		#if cpp
		return CppiaNative.checkHeader(cpp.Pointer.arrayElem(bytes.getData(), 0).constRaw, bytes.length);
		#else
		var magic:String = bytes.getString(0, 5);
		var end:Int = bytes.get(5);
		if ((magic != "CPPIA" && magic != "CPPIB") || (end != 10 && end != 13)) return INVALID;
		return magic == "CPPIB" ? BINARY : TEXT;
		#end
	}

	public static function fileFormat(path:String):CppiaFormat
	{
		#if cpp
		return path == null ? INVALID : CppiaNative.checkFileHeader(path);
		#elseif sys
		if (path == null || !sys.FileSystem.exists(path)) return INVALID;
		var input:sys.io.FileInput = sys.io.File.read(path, true);
		var head:Bytes = Bytes.alloc(6);
		var read:Int = 0;
		try
		{
			read = input.readBytes(head, 0, 6);
		}
		catch (e:Dynamic) {}
		input.close();
		return read < 6 ? INVALID : format(head);
		#else
		return INVALID;
		#end
	}

	public static function version(bytes:Bytes):Int
	{
		if (bytes == null || bytes.length < 7) return -1;
		#if cpp
		return CppiaNative.scriptVersion(cpp.Pointer.arrayElem(bytes.getData(), 0).constRaw, bytes.length);
		#else
		if (format(bytes) == INVALID) return -1;
		var value:Int = 0;
		var i:Int = 6;
		var digits:Bool = false;
		while (i < bytes.length && bytes.get(i) >= 48 && bytes.get(i) <= 57)
		{
			value = value * 10 + bytes.get(i) - 48;
			digits = true;
			i++;
		}
		return digits ? value : -1;
		#end
	}

	public static function hash(bytes:Bytes):String
	{
		#if cpp
		var text:cpp.ConstCharStar = bytes == null || bytes.length == 0 ? CppiaNative.hashBytes(null, 0) : CppiaNative.hashBytes(cpp.Pointer.arrayElem(bytes.getData(), 0).constRaw, bytes.length);
		return text.toString();
		#else
		var value:haxe.Int64 = haxe.Int64.make(0xcbf29ce4, 0x84222325);
		var prime:haxe.Int64 = haxe.Int64.make(0x100, 0x000001b3);
		if (bytes != null)
			for (i in 0...bytes.length)
			{
				value = haxe.Int64.xor(value, haxe.Int64.ofInt(bytes.get(i)));
				value = haxe.Int64.mul(value, prime);
			}
		var high:Int = value.high;
		var low:Int = value.low;
		return StringTools.hex(high, 8).toLowerCase() + StringTools.hex(low, 8).toLowerCase();
		#end
	}

	public static function hashFile(path:String):String
	{
		#if cpp
		if (path == null) return "";
		var text:cpp.ConstCharStar = CppiaNative.hashFile(path);
		return text.toString();
		#elseif sys
		return path != null && sys.FileSystem.exists(path) ? hash(sys.io.File.getBytes(path)) : "";
		#else
		return "";
		#end
	}

	public static function now():Float
	{
		#if cpp
		return CppiaNative.nowNanoseconds() / 1000000;
		#else
		return haxe.Timer.stamp() * 1000;
		#end
	}

	public static function modified(path:String):Float
	{
		#if cpp
		return path == null ? 0 : CppiaNative.fileModified(path);
		#elseif sys
		try
		{
			return sys.FileSystem.stat(path).mtime.getTime();
		}
		catch (e:Dynamic) {}
		return 0;
		#else
		return 0;
		#end
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
