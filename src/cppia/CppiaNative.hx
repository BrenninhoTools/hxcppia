package cppia;

#if cpp
@:buildXml('<include name="${haxelib:hxcppia}/project/Build.xml"/>')
@:include('hxcppia.h')
extern class CppiaNative
{
	@:native('::hxcppia::checkHeader') static function checkHeader(data:cpp.RawConstPointer<cpp.UInt8>, length:Int):Int;
	@:native('::hxcppia::checkFileHeader') static function checkFileHeader(path:cpp.ConstCharStar):Int;
	@:native('::hxcppia::hashBytes') static function hashBytes(data:cpp.RawConstPointer<cpp.UInt8>, length:Int):cpp.ConstCharStar;
	@:native('::hxcppia::hashFile') static function hashFile(path:cpp.ConstCharStar):cpp.ConstCharStar;
	@:native('::hxcppia::fileModified') static function fileModified(path:cpp.ConstCharStar):Float;
	@:native('::hxcppia::fileSize') static function fileSize(path:cpp.ConstCharStar):Float;
	@:native('::hxcppia::nowNanoseconds') static function nowNanoseconds():Float;
	@:native('::hxcppia::scriptVersion') static function scriptVersion(data:cpp.RawConstPointer<cpp.UInt8>, length:Int):Int;
}
#end
