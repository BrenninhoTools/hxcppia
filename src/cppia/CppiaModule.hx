package cppia;

#if (cpp && scriptable)
@:headerInclude('hx/Scriptable.h')
@:cppInclude('hx/Scriptable.h')
#end
class CppiaModule
{
	public var path(default, null):String;
	public var name(default, null):String;
	public var instances(default, null):Array<Dynamic> = [];
	public var active:Bool = true;
	public var booted(default, null):Bool = false;
	public var started(default, null):Bool = false;
	public var entry(default, null):Null<Class<Dynamic>>;
	public var priority:Int = 0;
	public var modifiedTime:Float = 0;
	public var hash:String = "";
	public var size:Int = 0;
	public var stats(default, null):Map<String, CppiaStat> = new Map();
	public var data:Map<String, Dynamic> = new Map();

	#if (cpp && scriptable)
	public var native(default, null):cpp.cppia.Module;
	#end

	var startArgs:Array<Dynamic>;

	public function new(path:String, native:Dynamic)
	{
		this.path = path;
		this.name = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(path));
		#if (cpp && scriptable)
		this.native = native;
		#end
	}

	public function boot():Void
	{
		if (booted) return;
		#if (cpp && scriptable)
		native.boot();
		#end
		booted = true;
	}

	public function run():Void
	{
		boot();
		#if (cpp && scriptable)
		native.run();
		#end
	}

	public function start(?args:Array<Dynamic>):Bool
	{
		if (started) return true;
		boot();
		startArgs = args;
		Cppia.pushCurrent(this);
		var ok:Bool = true;
		try
		{
			var candidates:Array<String> = [name].concat(Cppia.entryClasses);
			for (candidate in candidates)
			{
				var cls:Class<Dynamic> = resolveClass(candidate);
				if (cls == null) continue;
				entry = cls;
				createInstance(candidate, args);
				break;
			}
			if (entry == null) run();
		}
		catch (e:Dynamic)
		{
			Cppia.report(this, path, 'new', e);
			ok = false;
		}
		Cppia.popCurrent();
		started = true;
		return ok;
	}

	public function resolveClass(className:String):Null<Class<Dynamic>>
	{
		if (className == null || className.length == 0) return null;
		#if (cpp && scriptable)
		try
		{
			return native.resolveClass(className);
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

	public function createInstance(className:String, ?args:Array<Dynamic>):Dynamic
	{
		var cls:Class<Dynamic> = resolveClass(className);
		if (cls == null) return null;
		var instance:Dynamic = Type.createInstance(cls, args != null ? args : []);
		addInstance(instance);
		var setter:Dynamic = Reflect.field(instance, 'set_module');
		if (Reflect.hasField(instance, 'module') || setter != null)
		{
			try
			{
				Reflect.setProperty(instance, 'module', this);
			}
			catch (e:Dynamic) {}
		}
		return instance;
	}

	public function addInstance(instance:Dynamic):Void
	{
		if (instance != null && instances.indexOf(instance) < 0) instances.push(instance);
	}

	public function exists(field:String):Bool
	{
		for (instance in instances)
			if (Reflect.isFunction(Reflect.getProperty(instance, field))) return true;
		return false;
	}

	public function call(field:String, ?args:Array<Dynamic>):Dynamic
	{
		if (!active) return null;
		var mapped:String = Cppia.callNames.exists(field) ? Cppia.callNames.get(field) : field;
		var result:Dynamic = null;
		var profiling:Bool = Cppia.profiling;
		for (instance in instances.copy())
		{
			var func:Dynamic = Reflect.getProperty(instance, mapped);
			if (!Reflect.isFunction(func)) continue;
			var started:Float = profiling ? Cppia.now() : 0;
			var failed:Bool = false;
			try
			{
				var value:Dynamic = Reflect.callMethod(instance, func, args != null ? args : []);
				if (value != null) result = value;
			}
			catch (e:Dynamic)
			{
				failed = true;
				Cppia.report(this, path, field, e);
			}
			if (profiling)
			{
				var stat:CppiaStat = stats.get(field);
				if (stat == null) stats.set(field, stat = new CppiaStat(field));
				stat.add(Cppia.now() - started);
				if (failed) stat.errors++;
			}
		}
		return result;
	}

	public function callStatic(className:String, field:String, ?args:Array<Dynamic>):Dynamic
	{
		var cls:Class<Dynamic> = resolveClass(className);
		if (cls == null) return null;
		var func:Dynamic = Reflect.field(cls, field);
		if (!Reflect.isFunction(func)) return null;
		try
		{
			return Reflect.callMethod(cls, func, args != null ? args : []);
		}
		catch (e:Dynamic)
		{
			Cppia.report(this, path, '$className.$field', e);
			return null;
		}
	}

	public function get(field:String):Dynamic
	{
		for (instance in instances)
		{
			try
			{
				if (Reflect.hasField(instance, field) || Reflect.getProperty(instance, field) != null) return Reflect.getProperty(instance, field);
			}
			catch (e:Dynamic) {}
		}
		return null;
	}

	public function set(field:String, value:Dynamic):Void
	{
		for (instance in instances)
		{
			try
			{
				Reflect.setProperty(instance, field, value);
			}
			catch (e:Dynamic) {}
		}
	}

	public function changed():Bool
	{
		if (modifiedTime <= 0) return false;
		var stamp:Float = Cppia.modified(path);
		if (stamp <= modifiedTime) return false;
		if (hash.length > 0 && Cppia.hashFile(path) == hash)
		{
			modifiedTime = stamp;
			return false;
		}
		return Cppia.fileFormat(path) != INVALID;
	}

	public function profileReport():String
	{
		var list:Array<CppiaStat> = [for (stat in stats) stat];
		list.sort(function(a, b) return a.totalMs < b.totalMs ? 1 : (a.totalMs > b.totalMs ? -1 : 0));
		var lines:Array<String> = ['$name:'];
		for (stat in list)
			lines.push('  ${stat.field}: ${stat.calls} calls, ${round(stat.totalMs)} ms total, ${round(stat.averageMs)} ms average, ${round(stat.maxMs)} ms max' + (stat.errors > 0 ? ', ${stat.errors} errors' : ''));
		return lines.join('\n');
	}

	public function resetStats():Void
	{
		stats.clear();
	}

	static inline function round(value:Float):Float
	{
		return Math.round(value * 1000) / 1000;
	}

	public function reload():Null<CppiaModule>
	{
		var fresh:CppiaModule = Cppia.load(path, false);
		if (fresh == null) return null;
		fresh.priority = priority;
		fresh.data = data;
		call('onReload', [fresh]);
		destroy();
		fresh.start(startArgs);
		fresh.call('onReloaded');
		return fresh;
	}

	public function destroy():Void
	{
		if (!active) return;
		call('onDestroy');
		active = false;
		instances = [];
	}
}
