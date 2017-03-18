package tests;
import tests.Test1.Test1c;

/**
 * ...
 * @author Mark Knol
 */
class Test2
{
	private var test1 = new Test1c();
	@:keep private var publicThing = new PublicThing();
	
	public function new() 
	{
		test1.publicvar = 23;
		trace(publicThing.field1);
		trace(publicThing.field2);
		trace(publicThing.field3);

		trace(privateStaticFunction());
	}
	
	private static function privateStaticFunction()
	{
		return "privateStaticFunction works: " + Math.random();
	}
	
}