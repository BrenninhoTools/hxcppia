package cppia;

typedef CppiaError =
{
	var module:Null<CppiaModule>;
	var path:String;
	var field:String;
	var error:Dynamic;
	var stack:String;
}
