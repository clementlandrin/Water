package lib;

#if editor

class ScriptConfiguration {

	public function new( checker : hide.comp.ScriptEditor.ScriptChecker ) {
		var chk = checker.checker;
		switch( checker.documentName ) {
		case "cdb.element.script":
			var group = checker.constants.get("cdb.groupID");
			if( group == null ) return;
			addWorldVars(chk);
			var region = group.split("/")[2];
			chk.allowGlobalsDefine = false;
			var file = hide.Ide.inst.getPath("content/script/"+region+".hx");
			if( !sys.FileSystem.exists(file) ) return;
			chk.allowGlobalsDefine = true;
			var ast = makeParser().parseString(sys.io.File.getContent(file));
			chk.check(ast);
			for( name => type in @:privateAccess chk.locals )
				chk.setGlobal(name, type);
			chk.allowGlobalsDefine = false;
		case "hx":
			addWorldVars(chk);
		default:
		}
	}

	function makeParser() {
		var parser = new hscript.Parser();
		parser.allowTypes = true;
		parser.allowMetadata = true;
		return parser;
	}

	function addWorldVars( chk : hscript.Checker ) {
		var parser = makeParser();
		chk.allowGlobalsDefine = true;
		var worldFile = hide.Ide.inst.getPath("content/script/World.hx");
		var worldAst = parser.parseString(sys.io.File.getContent(worldFile));
		chk.check(worldAst);
		for( name => type in @:privateAccess chk.locals ) {
			// skip global events
			if( type.match(TFun(_)) && name.substr(0,2) == "on" && name.charCodeAt(2) >= 'A'.code && name.charCodeAt(2) <= 'Z'.code )
				continue;
			chk.setGlobal(name, type);
		}
	}

	static var _ = hide.comp.ScriptEditor.register(ScriptConfiguration);
}

#end