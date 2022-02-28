package lib;

class StateMacros {

	public macro function makeEvent( ethis : haxe.macro.Expr, ecall : haxe.macro.Expr.Expr ) {
		var method = null, args = macro null;
		var mcall = switch( ecall.expr ) {
		case EConst(CIdent(name)):
			method = name;
			macro @:pos(ecall.pos) $ethis.$name();
		case ECall({ expr : EField({ expr : EConst(CIdent(name)) },"bind") },fargs):
			method = name;
			args = macro $a{fargs};
			macro @:pos(ecall.pos) $ethis.$name($a{fargs});
		default:
			haxe.macro.Context.error("Invalid method", ecall.pos);
		}
		return macro {
			if( false ) $mcall;
			new st.Event.MacroEvent($ethis,$v{method},$args);
		};
	}

}