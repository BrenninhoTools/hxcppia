package cppia;

class CppiaScript
{
	public var module:CppiaModule;

	public function new() {}

	public function call(field:String, ?args:Array<Dynamic>):Dynamic
	{
		var func:Dynamic = Reflect.getProperty(this, field);
		return Reflect.isFunction(func) ? Reflect.callMethod(this, func, args != null ? args : []) : null;
	}
}
