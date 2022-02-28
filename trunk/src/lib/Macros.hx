package lib;
import lib.CssParser;
import haxe.macro.Context;
import haxe.macro.Expr;

class Macros {

	public macro static function getBuildInfos() {
		var rev = 0;
		try {
			var svn = new sys.io.Process("svn", ["info", "--xml"]);
			var err = svn.exitCode();
			if( err != 0 ) throw "Error "+err;
			var x = new haxe.xml.Access(Xml.parse(svn.stdout.readAll().toString()).firstElement());
			rev = Std.parseInt(x.node.entry.node.commit.att.revision);
		} catch( e : Dynamic ) {
			Context.error("Failed to get revision ("+e+")",Context.currentPos());
		}
		return macro $v{ rev };
	}

	public macro static function getBuildTime() {
		return macro $v{ DateTools.format(Date.now(), "%Y-%m-%d_%H-%M") };
	}

	#if macro
	public static function initComponents() {
		domkit.Macros.registerComponentsPath("$");
		domkit.Macros.registerComponentsPath("battle.ui.comp.$");
		domkit.Macros.registerComponentsPath("ui.comp.$");
		domkit.Macros.registerComponentsPath("ui.$");
		domkit.Macros.processMacro = function( id : String, args : Null<Array<Expr>>, pos : Position ) : domkit.MarkupParser.Markup {
			var e = macro Texts;
			var inf = Context.getPosInfos(pos);
			inline function getPos(len:Int) : Position {
				var p = inf.min;
				inf.min += len;
				return Context.makePosition({ min : p, max : p + len, file : inf.file });
			}
			for( f in id.split(".") ) {
				e = { expr : EField(e,f), pos : getPos(f.length) };
				inf.min++;
			}
			if( args != null )
				e = { expr : ECall(e,args), pos : pos };
			return {
				pmin : 0,
				pmax : 0,
				kind : Node("fmt-text"),
				attributes : [{
					pmin : 0,
					pmax : 0,
					name : "text",
					vmin : 0,
					value : Code(e),
				}]
			};
		}
	}
	#end

}