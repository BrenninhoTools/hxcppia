package cppia;

class CppiaGroup
{
	public var modules(default, null):Array<CppiaModule> = [];
	public var hotReload:Bool = false;
	public var reloadInterval:Float = 1;
	public var onReload:CppiaModule->Void = null;

	var lastCheck:Float = 0;

	public function new() {}

	public function load(path:String, ?args:Array<Dynamic>):Null<CppiaModule>
	{
		for (module in modules)
			if (module.path == path) return module;
		var module:CppiaModule = Cppia.load(path, true, args);
		if (module != null) add(module);
		return module;
	}

	public function loadFolder(folder:String, ?args:Array<Dynamic>):Array<CppiaModule>
	{
		var loaded:Array<CppiaModule> = [];
		#if sys
		if (!sys.FileSystem.exists(folder) || !sys.FileSystem.isDirectory(folder)) return loaded;
		var files:Array<String> = sys.FileSystem.readDirectory(folder);
		files.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
		for (file in files)
		{
			if (!Cppia.isScript(file)) continue;
			var module:CppiaModule = load(haxe.io.Path.join([folder, file]), args);
			if (module != null) loaded.push(module);
		}
		#end
		return loaded;
	}

	public function add(module:CppiaModule):CppiaModule
	{
		if (module == null || modules.indexOf(module) >= 0) return module;
		modules.push(module);
		sort();
		return module;
	}

	public function remove(module:CppiaModule, destroy:Bool = true):Void
	{
		if (modules.remove(module) && destroy) module.destroy();
	}

	public function sort():Void
	{
		modules.sort(function(a, b) return b.priority - a.priority);
	}

	public function call(field:String, ?args:Array<Dynamic>, ?stopValues:Array<Dynamic>):Dynamic
	{
		var result:Dynamic = null;
		for (module in modules.copy())
		{
			if (!module.active) continue;
			var value:Dynamic = module.call(field, args);
			if (value == null) continue;
			result = value;
			if (stopValues != null && stopValues.indexOf(value) >= 0) break;
		}
		return result;
	}

	public function set(field:String, value:Dynamic):Void
	{
		for (module in modules)
			module.set(field, value);
	}

	public function resolveClass(className:String):Null<Class<Dynamic>>
	{
		for (module in modules)
		{
			var cls:Class<Dynamic> = module.resolveClass(className);
			if (cls != null) return cls;
		}
		return null;
	}

	public function update():Void
	{
		if (!hotReload) return;
		var now:Float = haxe.Timer.stamp();
		if (now - lastCheck < reloadInterval) return;
		lastCheck = now;
		reloadChanged();
	}

	public function reloadChanged():Int
	{
		var count:Int = 0;
		for (i in 0...modules.length)
		{
			var module:CppiaModule = modules[i];
			if (!module.changed()) continue;
			var fresh:CppiaModule = module.reload();
			if (fresh == null) continue;
			modules[i] = fresh;
			count++;
			if (onReload != null) onReload(fresh);
		}
		return count;
	}

	public function destroy():Void
	{
		for (module in modules)
			module.destroy();
		modules = [];
	}
}
