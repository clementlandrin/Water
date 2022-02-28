package lib;

enum ColorKey {
	// generic
	Default;
	Good;
	Bad;
	Disable;
	Comment;
	Warning;
	// gestion
	Gold;
	Food;
	Setting;
	// dialog
	Place;
	// fight
	Capacity;
	StatusBonus;
	StatusMalus;
	Information;
	SkillValue;
	Attribute;
	Damages;
	Skill;
}

class Tools {

	public static function copyRec<T>( v : T ) : T {
		return haxe.Unserializer.run(haxe.Serializer.run(v));
	}

	public static function countSyllabs( name : String ) {
		var test = ~/[aeyuio]+/gi.replace(name,".");
		test = ~/[a-z]+/gi.replace(test,"!");
		test = test.split("!.").join("S");
		return test.length;
	}

	public static function getItemCost( item : Data.ItemKind, ?qty : Int = 1 ) {
		var has = Game.inst.me.hasItem(item, qty);
		var color = has ? "good" : "bad";
		var label = getItemLabel(item, qty);
		return '<$color>$label</$color>';
	}

	public static function getItemLabel( item : Data.ItemKind, ?qty = 1 ) {
		var inf = Data.item.get(item);
		return '<img src="/item/${item}"/>' + (inf.props.hidden ? ""+qty : st.Item.formatItemName(inf)+(qty == 1 && item != RawMaterials && item != Remedy ? "" : " x"+qty));
	}

	public static function makeElementUniqueId(ctx : hrt.prefab.Context, inf : Data.Element, map : Map<String,String>) : Data.ElementKind {
		var suffix : String = null;
		if( inf.items != null && inf.items.type == Gather ) {
			var pos = ctx.local3d.getAbsPos();
			suffix = "@"+Std.int(pos.tx)+"_"+Std.int(pos.ty);
		}
		return cast makeUniqueId(inf.id.toString(), suffix, map);
	}

	public static function makeUniqueId( initialId: String, ?suffix : String, map : Map<String,String> ) : String {
		var id = initialId;
		if (suffix != null)
			id += suffix;
		var counter = 1;
		while( true ) {
			var cid = counter == 1 ? id : id+"$"+counter;
			if( !map.exists(cid) ) {
				map.set(cid, initialId);
				return cid;
			}
			counter++;
		}
	}

	public static function makeSignature( d : Dynamic, ?ignoreFields : Array<String> ) {
		if( ignoreFields != null ) {
			d = Reflect.copy(d);
			for( i in ignoreFields ) Reflect.deleteField(d, i);
		}
		var bytes = haxe.io.Bytes.ofString(haxe.Json.stringify(d));
		return haxe.crypto.Md5.make(bytes).getInt32(0);
	}

	public static function colorValue( k : ColorKey ) {
		return switch( k ) {
		case Default: 0xffffff;
		case Good: 0x529b52;
		case Bad: 0xb63131;
		case Disable, Comment: 0x808080;
		case Gold: 0xffbb00;
		case Food: 0xb0e0b0;
		case Place: 0xc0ffc0;
		case Warning: 0xb4691e;
		// fight
		case Capacity: 0xfcf691;
		case StatusBonus: 0x73aade;
		case StatusMalus: 0xdba86e;
		case Information: 0xddd8c5;
		case Damages: 0xffffff;
		case SkillValue: 0xffffff;
		case Attribute: 0xffffff;
		case Setting: Const.getColor(SettingColor);
		case Skill: 0x87DD87;
		}
	}

	public static function color( k : ColorKey ) {
		var c = colorValue(k);
		return "#"+StringTools.lpad(StringTools.hex(c),"0",6);
	}

	public static function prepareText( text : String ) {
		text = text.split('…').join("...");
		var nbsp = String.fromCharCode(0xA0);
		text = text.split(" !").join(nbsp+"!");
		text = text.split(" ?").join(nbsp+"?");
		return text;
	}

	public static function prepareListNames( names: Array<String> ) {
		if (names.length == 1)
			return names[0];
		return Texts.list_name({ names: names.slice(0, -1).join("<default>,</default> "), last: names.last() });
	}

	/**
	 *  A way to encode two min/max values into a single float, in the format  Min.Max (eg 1.3 => [1-3])
	 *  Also works for negative values : -4.7 => [-4,-7]
	 */
	public static function randomRange( f : Float ) {
		var min = Std.int(f);
		var max = f == min ? min : (Std.parseInt((""+f).split(".").pop()) * (f < 0 ? -1 : 1));
		if( max < min ) {
			var tmp = max;
			max = min;
			min = tmp;
		}
		var rnd = Math.random() * (max - min) + min;
		return {
			min : min,
			max : max,
			random : rnd,
		};
	}

	public static function formatBigNumber( i : Int ) {
		var str = "" + i;
		var length = str.length;
		for ( i in 0...length ) {
			var j = length - i - 1;
			if ( (length - j) % 3 == 0 )
				str = str.substr(0, j) + " " + str.substr(j);
		}
		return str;
	}

	public static function formatHtml( text : String ) {
		text = ~/\*([^*]+)\*/g.replace(text,"<b>$1</b>");
		return ~/<([a-zA-Z]+)>(.*?)<\/\1>/g.map(text, function(r) {
			var content = formatHtml(r.matched(2));
			var id = r.matched(1);
			switch( id ) {
			case "b":
				return '<font color="${color(Information)}">$content</font>';
			case "gold":
				return '<font color="${color(Gold)}"><img src="icon/Gold"/>$content</font>';
			case "food":
				return '<font color="${color(Food)}"><img src="icon/Food"/>$content</font>';
			case "happy":
				if( content.indexOf('<') >= 0 )
					return '<img src="icon/Happiness"/>$content';
				if( content.charCodeAt(0) == "-".code )
					return '<img src="icon/Unhappiness"/><font color="${color(Bad)}">$content</font>';
				if( content == "0" )
					return '<img src="icon/Happiness"/><font color="${color(Information)}">$content</font>';
				return '<img src="icon/Happiness"/><font color="${color(Good)}">$content</font>';
			case "influence":
				return '<img src="icon/Influence"/>$content';
			case "default":
				return '<font color="${color(Default)}">$content</font>';
			case "good":
				return '<font color="${color(Good)}">$content</font>';
			case "bad":
				return '<font color="${color(Bad)}">$content</font>';
			case "disable":
				return '<font color="${color(Disable)}">$content</font>';
			case "comment":
				return '<font color="${color(Comment)}">$content</font>';
			case "dmg":
				return Texts.fmt_dmg({ value : '<font color="${color(Damages)}">$content</font>' });
			case "cpty":
				return '<font color="${color(Capacity)}"><b>$content</b></font>';
			case "stb":
				return '<font color="${color(StatusBonus)}"><b>$content</b></font>';
			case "stm":
				return '<font color="${color(StatusMalus)}"><b>$content</b></font>';
			case "inf":
				return '<font color="${color(Information)}">$content</font>';
			case "setting":
				return '<font color="${color(Setting)}"><b>$content</b></font>';
			case "small":
				return '<font face="small">$content</font>';
			case "ap":
				return '<img src="icon/ActionPoint"/><b>$content</b>';
			case "apt":
				return '<img src="icon/ActionPointBonus"/><b>$content</b>';
			case "key":
				return '<font face="small">[$content]</font>';
			case "trait":
				var tr = Data.trait.resolve(content, true);
				return '<b>${tr == null ? content : tr.name}</b>';
			case "status":
				var st = Data.status.resolve(content, true);
				var tColor = StatusMalus;
				if ( st.group == Bonus )
					tColor = StatusBonus;
				return '<font color="${color(tColor)}">${st == null ? content : st.name}</font>';
			case "skill":
				var sk = Data.skill.resolve(content, true);
				return '<font color="${color(Skill)}">${sk == null ? content : sk.name}</font>';
			}
			return '<$id>$content</$id>';
		});
	}

	public static function formatText( text : String ) {
		text = StringTools.trim(text);
		text = ~/\[([A-Za-z0-9_]+)\]/g.map(text, function(r) {
			var id = r.matched(1);
			var attr = Data.attribute.resolve(id, true);
			if( attr != null )
				return '<font color="${color(Attribute)}">${attr.name}</font>';
			var place = Game.inst == null ? null : Game.inst.getPlaceInfo(cast id);
			if( place != null )
				return '<font color="${color(Place)}">${place.world.name}</font>';
			var status = Data.status.resolve(id, true);
			if( status != null ) {
				var c = if (status.group == Bonus) StatusBonus;
						else if (status.group == Malus) StatusMalus;
						else Information;
				return '<font color="${color(c)}">${st.Status.formatName(status, false)}</font>';
			}
			var icon = Data.icon.resolve(id, true);
			if( icon != null) {
				if (icon.group == Capacities)
					return '<font color="${color(Capacity)}"><b>${icon.text}</b></font>';
				else
					return '<b>${icon.text}</b>';
			}
			switch( id ) {
			case "LMB", "RMB":
				return '<img src="$id"/>';
			case "SHIFT_KEY":
				return "SHIFT";
			default:
			}
			return id;
		});
		text = formatHtml(text);
		text = ~/[ \t]*\r?\n[ \t]*/g.replace(text,"<br/>");
		return text;
	}

	public static function formatObjective( text : String, objective: battle.State.Objective, target : battle.Unit ) {
		var data = Data.bonus.get(objective.id);

		text = text.split("[PROGRESS]").join("" + objective.progress);
		var max = data.props.fixedValue.or(1);
		text = text.split("[VALUE]").join("" + max);
		if (target != null)
			text = text.split("[TARGET]").join("<b>" + target.data.getName() + "</b>");

		return formatHtml(text);
	}

}