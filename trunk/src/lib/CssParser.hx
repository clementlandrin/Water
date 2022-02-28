package lib;
import domkit.CssValue;

class CssParser extends h2d.domkit.BaseComponents.CustomParser {

	public function parseIcon( v : CssValue ) {
		return switch( v ) {
		case VIdent(i):
			#if macro
			return null;
			#else
			var ico = Data.icon.resolve(i, true);
			if( ico == null ) invalidProp("Invalid icon "+i);
			return ico.id;
			#end
		default: invalidProp();
		}
	}

}
