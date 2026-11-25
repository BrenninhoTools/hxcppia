package;

import cppia.Cppia;
import cppia.CppiaGroup;

class Host
{
	public static var counter:Int = 0;

	public static function bump(amount:Int):Int
	{
		counter += amount;
		return counter;
	}

	static function main():Void
	{
		Cppia.onError = function(error) Sys.println(Cppia.describe(error));
		Cppia.profiling = true;
		var bad:Bool = Cppia.fromBytes(haxe.io.Bytes.ofString("not a script"), "bad") == null && Cppia.lastError != null && Cppia.lastError.field == "header";
		var fileHash:String = Cppia.hashFile("tests/bin/TestScript.cppia");
		var group:CppiaGroup = new CppiaGroup();
		var module = group.load("tests/bin/TestScript.cppia");
		if (module == null)
		{
			Sys.println("FAIL: script did not load");
			Sys.exit(1);
		}
		group.call("onCreate");
		var result:Dynamic = group.call("add", [2, 3]);
		group.call("onUpdate", [0.5]);
		var ok:Bool = bad && result == 5 && counter == 11 && module.get("updates") == 1 && module.resolveClass("TestScript") != null;
		ok = ok && module.hash == fileHash && module.stats.get("add").calls == 1 && !module.changed();
		Sys.println(group.profileReport());
		module.destroy();
		Sys.println(ok ? "ok" : 'FAIL: result=$result counter=$counter updates=${module.get("updates")}');
		Sys.exit(ok ? 0 : 1);
	}
}
