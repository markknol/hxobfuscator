package tests;

/**
 * ...
 * @author Mark Knol
 */
class Test1
{
	public static var LOL = 123456789;
	private var longname1 = Math.random();
	private var longname2 = Math.random();
	private var wiuerhwqr = {x:123, y:456};
	
	var map1 = [ 1 => "hey"];
	var map2 = [ "hey" => 1];
	private var publicThing = new PublicThing();
	
	
	private function privateFunction1() {
		publicThing.field1 = "public field1 edited";
		return "private still works ["  + Math.random() + "]";
	}
	
	private inline function privateFunction2() {
		return "private function 2 works because " + privateFunction1();
	}
	
	
	public var publicvar = Math.random();
	
	public function new() 
	{
		trace(longname1 +"-"+ longname2);
		
		trace(map1);
		trace(map2);
		trace(privateFunction1());
		trace(privateFunction2());
		
		publicThing.field1 = "public field2 edited";
		
	}
	
}

private class Test1b extends Test1
{
	private var staticRef = Test1.LOL;
		
	public function new() 
	{
		super();
		
		longname1 = 12345678901234567890;
		staticRef += 12345;
		
		trace(staticRef);
	}
	
	
}
 class Test1c extends Test1b
{
	public function new() 
	{
		super();
		trace("Test1c works");
	}
}