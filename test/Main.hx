package;

import js.Lib;
import tests.EnumAbstract;
import tests.Test1;
import tests.Test2;
import tests.TestEnum;

/**
 * ...
 * @author Mark Knol
 */
class Main 
{
	private var test1 = new Test1();
	var test2a = new Test2();
	var test2b = new Test2Abstract();
	
	function new() {
		trace(test1);
		trace(test2a);
		trace(test2b);
	}
	
	static function main() 
	{
		new Main();
		
		trace(EnumAbstractInt.MyVar);
		trace(EnumAbstractString.MyVar2);
		trace(TestEnum.MY_VAR1);
		trace(TestEnum.MY_VAR2);
	}
	
}