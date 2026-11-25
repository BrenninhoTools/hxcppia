package;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class Run
{
	static function main():Void
	{
		var args:Array<String> = Sys.args();
		var cwd:String = Sys.getCwd();
		if (Sys.getEnv("HAXELIB_RUN") == "1" && args.length > 0)
		{
			cwd = args.pop();
			Sys.setCwd(cwd);
		}

		var command:String = args.length > 0 ? args.shift() : "help";
		switch (command)
		{
			case "build":
				Sys.exit(build(args));
			case "new":
				Sys.exit(create(args));
			default:
				help();
		}
	}

	static function help():Void
	{
		Sys.println("cppia tools");
		Sys.println("");
		Sys.println("  haxelib run cppia build <Main> [-cp dir] [-o out.cppia] [--host export_classes.info] [haxe args]");
		Sys.println("  haxelib run cppia new <Name> [folder]");
	}

	static function build(args:Array<String>):Int
	{
		if (args.length == 0)
		{
			help();
			return 1;
		}
		var main:String = args.shift();
		var output:String = null;
		var host:String = null;
		var paths:Array<String> = [];
		var extra:Array<String> = [];
		var i:Int = 0;
		while (i < args.length)
		{
			var arg:String = args[i];
			switch (arg)
			{
				case "-o", "--out":
					output = args[++i];
				case "--host":
					host = args[++i];
				case "-cp":
					paths.push(args[++i]);
				default:
					extra.push(arg);
			}
			i++;
		}

		if (paths.length == 0) paths.push(".");
		if (output == null) output = main.split(".").pop() + ".cppia";
		if (host == null && FileSystem.exists("export_classes.info")) host = "export_classes.info";

		var haxeArgs:Array<String> = [];
		for (path in paths)
			haxeArgs = haxeArgs.concat(["-cp", path]);
		haxeArgs = haxeArgs.concat([main, "-cppia", output, "-D", "cppia_script"]);
		if (host != null)
		{
			if (!FileSystem.exists(host))
			{
				Sys.println('Host export file not found: $host');
				return 1;
			}
			haxeArgs = haxeArgs.concat(["-D", 'dll_import=$host']);
		}
		haxeArgs = haxeArgs.concat(extra);

		Sys.println("haxe " + haxeArgs.join(" "));
		var code:Int = Sys.command("haxe", haxeArgs);
		if (code == 0) Sys.println('Built $output');
		return code;
	}

	static function create(args:Array<String>):Int
	{
		if (args.length == 0)
		{
			help();
			return 1;
		}
		var name:String = args[0];
		var folder:String = args.length > 1 ? args[1] : name;
		if (!~/^[A-Z][A-Za-z0-9_]*$/.match(name))
		{
			Sys.println("The script name must be a valid class name, like MyScript");
			return 1;
		}
		FileSystem.createDirectory(folder);
		var source:String = '$folder/$name.hx';
		if (FileSystem.exists(source))
		{
			Sys.println('$source already exists');
			return 1;
		}
		File.saveContent(source, 'package;

class $name extends cppia.CppiaScript
{
	public function new()
	{
		super();
	}

	public function onCreate():Void {}

	public function onUpdate(elapsed:Float):Void {}

	public function onDestroy():Void {}
}
');
		File.saveContent('$folder/build.hxml', '-cp .
-lib cppia
$name
-cppia $name.cppia
-D cppia_script
');
		Sys.println('Created $source and $folder/build.hxml');
		Sys.println("Copy export_classes.info from your game build next to build.hxml and add -D dll_import=export_classes.info to share the game classes.");
		return 0;
	}
}
