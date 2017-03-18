package tests;

/**
 * ...
 * @author Mark Knol
 */
class PublicThing
{
	@:isVar public var field1(get, set) = "unedited field1";
	@:isVar public var field2(default, set) = "unedited field2";
	public var field3(get, null):String;
	private var _field3 = "unedited field3";
	
	public inline function new() 
	{
		trace(field1);
		trace(field2);
		trace(field3);
	}
	
	private function get_field1()
	{
		return this.field1;
	}
	
	private function set_field1(value) return this.field1 = value;
	
	private function set_field2(value)
	{
		return field2 = value;
	}
	
	private function get_field3()
	{
		return _field3;
	}
	
}