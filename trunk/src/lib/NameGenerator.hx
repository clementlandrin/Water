package lib;

private typedef Entry = {
	var name : String;
	var total : Float;
	var weight : Float;
	var subs : Array<{ p : Float, r : Rule }>;
	var lines : Array<String>;
}

private enum Rule {
	Concat( a : Rule, b : Rule );
	Word( w : String );
	Entry( e : Entry );
	Previous( e : Entry, not : Bool );
	Choice( cont : Array<String> );
}

private enum Retry {
	RetryExc;
}

class NameGenerator {

	var entries : Map<String, Entry>;
	var rnd : hxd.Rand;

	function new() {
		var r = hxd.Res.content.systemic.names;
		load(r.entry.getText());
		r.watch(function() load(r.entry.getText()));
	}

	function load( text : String ) {
		entries = new Map();
		var lines = [for( l in text.split("\n") ) if( l.charCodeAt(0) != "#".code ) l];
		var r_entry = ~/^([A-Za-z0-9_]+):$/;
		while( lines.length > 0 ) {
			var line = StringTools.trim(lines.shift());
			if( line == "" ) continue;
			if( !r_entry.match(line) )
				throw "Invalid rule start "+line;
			var name = r_entry.matched(1);
			if( entries.exists(name) ) throw "Duplicate rule "+name;
			var e : Entry = {
				name : name,
				total : 0,
				weight : 0,
				subs : [],
				lines : [],
			};
			entries.set(name,e);
			while( lines.length > 0 ) {
				var line = lines.shift();
				if( line == "" || line.charCodeAt(0) != "\t".code ) {
					lines.unshift(line);
					break;
				}
				line = StringTools.trim(line);
				e.lines.push(line);
			}
		}
		var r_proba = ~/\[([0-9\.]+)\]$/;
		var r_prev = ~/^\[\^?([A-Za-z0-9_]+)\]$/;
		for( e in entries ) {
			var lines = e.lines;
			e.lines = null;
			for( l in lines ) {
				var p = 1.;
				if( r_proba.match(l) ) {
					p = Std.parseFloat(r_proba.matched(1));
					l = r_proba.matchedLeft();
				}
				var rule = null;
				for( p in l.split("+") ) {
					if( p == "€" ) p = "";

					var r;
					if( r_prev.match(p) ) {
						var ename = r_prev.matched(1);
						var ent = entries.get(ename);
						if( ent == null )
							r = Choice(ename.split(""));
						else
							r = Previous(ent, p.charCodeAt(1) == "^".code);
					} else {
						var ent = entries.get(p);
						r = ent == null ? Word(p) : Entry(ent);
					}
					if( rule == null )
						rule = r;
					else
						rule = Concat(rule, r);
				}
				e.total += p;
				e.subs.push({ p : p, r : rule });
			}
		}
		for( e in entries )
			calcWeight(e);
	}

	function calcWeight( e : Entry ) {
		if( e.weight != 0 )
			return e.weight;
		var w = 0., tw = 0.;
		for( s in e.subs ) {
			var rw = getRuleWeight(s.r);
			w += rw * Math.min(s.p / e.total, 1 / e.subs.length);
			s.p *= Math.sqrt(rw); // auto-scale rule probability by sqrt(weight)
			tw += s.p;
		}
		e.weight = w * e.subs.length;
		e.total = tw;
		return e.weight;
	}

	function getRuleWeight( r : Rule ) : Float {
		return switch r {
		case Concat(a, b): getRuleWeight(a) * getRuleWeight(b);
		case Word(w): 1.;
		case Entry(e): calcWeight(e);
		case Previous(e, not): 1.;
		case Choice(cont): Math.sqrt(cont.length); // small letters
		}
	}

	function retry() {
		throw RetryExc;
	}

	function gen( name : String, rnd : hxd.Rand ) {
		var e = entries.get(name);
		try{
			if( e == null ) throw "Unknown name entry '"+name+"'";
		}
		catch( ev : Dynamic) {
			e = entries.get("name");
		}
		this.rnd = rnd;
		while( true ) {
			try {
				var c = [];
				genRec(e, c);
				this.rnd = null;
				return c.join("");
			} catch( e : Retry ) {
			}
		}
	}

	function genRec( e : Entry, cur : Array<String> ) {
		var m = Math.random() * e.total;
		for( s in e.subs ) {
			m -= s.p;
			if( m < 0 )
				return genRule(s.r, cur);
		}
		throw "assert";
	}

	function genRule( r : Rule, cur : Array<String> ) {
		switch( r ) {
		case Concat(a, b):
			genRule(a, cur);
			genRule(b, cur);
		case Word(w):
			cur.push(w);
		case Entry(e):
			genRec(e, cur);
		case Choice(c):
			cur.push(c[rnd.random(c.length)]);
		case Previous(e, not):
			var last = cur[cur.length - 1];
			if( last == null )
				retry();
			last = last.toLowerCase();
			var found = false;
			for( s in e.subs ) {
				switch( s.r ) {
				case Word(w) if( StringTools.endsWith(last,w) ):
					if( not ) retry() else { found = true; break; }
				default:
				}
			}
			if( !not && !found ) retry();
		}
	}

	static var curSex = false;
	static var curCount = 0;

	public static function randomSex( ?rnd : hxd.Rand ) {
		if( rnd != null )
			return rnd.random(3) == 0;

		var w = Std.random(3) == 0;
		if( w == curSex ) {
			curCount++;
			if( curCount > 5 ) {
				w = !w;
				curSex = w;
				curCount = 0;
			}
		} else {
			curSex = w;
			curCount = 0;
		}
		return w;
	}

	public static function obtainEntry(npc : ent.p.Npc) {
		var entry = "name";
		if (npc != null) {
			if (@:privateAccess npc.inf.npc.regionId != null) {
				entry += @:privateAccess npc.inf.npc.regionId.toString().split("_")[0];
			}
			else
				entry += npc.getRegion().inf.id.toString().split("_")[0];
			entry += npc.getUnit().woman ? "_f" : "_m";
		}
		return entry;
	}

	static var inst : NameGenerator;
	public static function generate( entry : String, ?rnd : hxd.Rand ) {
		if( rnd == null ) rnd = hxd.Rand.create();
		if( inst == null ) inst = new NameGenerator();
		return inst.gen(entry, rnd);
	}

}