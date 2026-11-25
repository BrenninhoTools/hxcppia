package cppia;

class CppiaStat
{
	public var field(default, null):String;
	public var calls:Int = 0;
	public var errors:Int = 0;
	public var totalMs:Float = 0;
	public var maxMs:Float = 0;
	public var averageMs(get, never):Float;

	public function new(field:String)
	{
		this.field = field;
	}

	public function add(milliseconds:Float):Void
	{
		calls++;
		totalMs += milliseconds;
		if (milliseconds > maxMs) maxMs = milliseconds;
	}

	public function reset():Void
	{
		calls = 0;
		errors = 0;
		totalMs = 0;
		maxMs = 0;
	}

	inline function get_averageMs():Float
	{
		return calls > 0 ? totalMs / calls : 0;
	}
}
