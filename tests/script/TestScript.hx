package;

class TestScript extends cppia.CppiaScript
{
	public var updates:Int = 0;

	public function new()
	{
		super();
	}

	public function onCreate():Void
	{
		Host.bump(10);
	}

	public function add(a:Int, b:Int):Int
	{
		return a + b;
	}

	public function onUpdate(elapsed:Float):Void
	{
		updates++;
		if (elapsed > 0) Host.bump(1);
	}
}
