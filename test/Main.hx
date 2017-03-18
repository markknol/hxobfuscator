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
	
	static function main() 
	{
		new Test1();
		new Test2();
		
		trace(EnumAbstractInt.MyVar);
		trace(EnumAbstractString.MyVar2);
		trace(TestEnum.MY_VAR1);
		trace(TestEnum.MY_VAR2);
	}
	
}