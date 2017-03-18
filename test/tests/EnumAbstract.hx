package tests;

/**
 * Abstract wrapper type around Int
 * @author Mark Knol
 */
@:enum abstract EnumAbstractInt(Int) 
{
	var MyVar = 1;
	public var MyVar2 = 2;
}
@:enum abstract EnumAbstractString(String) 
{
	var MyVar = "EnumAbstract MyVar1";
	public var MyVar2 = "EnumAbstract MyVar2";
}