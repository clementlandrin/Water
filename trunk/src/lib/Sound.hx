package lib;

enum SoundParamKind {
	None;
	Switch( grp : wwise.Api.SwitchGroup );
	RTPC( rtpc : wwise.Api.Param );
}

private typedef SoundParams = Map<String, SoundParamKind>;

class SoundObject {

	static var PARAMS : Map<Data.SoundKind, SoundParams> = new Map();

	var ent : ent.Entity;
	var kind : Data.SoundKind;
	var go : wwise.Api.GameObject;
	var params : SoundParams;
	var x : Float = 1e9;
	var y : Float = 1e9;
	var z : Float = 1e9;
	var currentValues : Map<String,Dynamic> = new Map();
	var skipFrames = 0;

	public function new(kind,?ent) {
		this.kind = kind;
		this.ent = ent;
		@:privateAccess lib.Sound.allObjects.push(this);
		go = new wwise.Api.GameObject(kind.toString());
		params = getParams(kind);
	}

	static function getParams( kind : Data.SoundKind ) {
		var params = PARAMS.get(kind);
		if( params != null )
			return params;
		var inf = Data.sound.resolve(kind.toString());
		if( inf.gameObjectId != null )
			params = getParams(inf.gameObjectId).copy();
		else
			params = new Map();
		if( inf.params != null )
			for( p in inf.params ) {
				var kind = if( p.wiseSwitchGroup != null && p.wiseSwitchGroup != "" )
					Switch( new wwise.Api.SwitchGroup(p.wiseSwitchGroup) );
				else if( p.wiseRTPC != null && p.wiseRTPC != "" )
					RTPC( new wwise.Api.Param(p.wiseRTPC) )
				else
					None;
				params.set(p.name, kind);
			}
		PARAMS.set(kind, params);
		return params;
	}

	public function set( params : {} ) {
		var out = setParams(params);
		if( Game.PREFS.soundLog && out != null )
			Sys.println("Set "+this+" "+out);
	}

	public function play( event : Data.SoundKind, ?params : {} ) {
		if( params != null ) setParams(params);
		var e = Data.sound.get(event);
		if( e != null && e.wiseEvents != null )
			go.postEvent(new wwise.Api.Event(e.wiseEvents));
		if( Game.PREFS.soundLog ) Sys.println("Play "+this+"."+event+(params==null?"" : " "+params));
	}

	public function playRaw( id : String ) {
		go.postEvent(new wwise.Api.Event(id));
	}

	function setParams( params : {} ) {
		var out = null;
		for( f in Reflect.fields(params) ) {
			var p = this.params.get(f);
			if( p == null ) {
				#if !release
				this.params.set(f, None);
				throw "Parameter '"+f+"' not defined for GameObject "+kind;
				#end
				continue;
			}
			var v : Dynamic = Reflect.field(params,f);
			if( currentValues.exists(f) && currentValues.get(f) == v )
				continue;
			if( Game.PREFS.soundLog ) {
				if( out == null ) out = {};
				Reflect.setField(out, f, v);
			}
			currentValues.set(f, v);
			switch( p ) {
			case None:
			case Switch(grp):
				go.setSwitch(grp,new wwise.Api.Switch(Std.string(v)));
			case RTPC(r):
				var v = Std.isOfType(v,Bool) ? (v?1:0) : (Std.isOfType(v,Float) ? (v:Float) : throw "Invalid RTPC value "+v);
				if( kind == Global ) wwise.Api.setParam(r, v) else go.setParam(r, v);
			}
		}
		return out;
	}

	function update() {
		if( ent != null ) {
			var obj = @:privateAccess ent.obj;
			var scene = obj == null ? null : obj.getScene();
			if( ent.isRemoved() || scene == null || @:privateAccess !scene.allocated ) {
				if( skipFrames > 5 )
					return false;
				skipFrames++;
			}
			if( obj != null ) {
				var pos = obj.getAbsPos();
				var dist = hxd.Math.distanceSq(pos.tx - x, pos.ty - y, pos.tz - z);
				if( dist > 0.2 ) {
					x = pos.tx;
					y = pos.ty;
					z = pos.tz;
					go.setPosition(x,y,z);
					@:privateAccess Sound.UPDATE_COUNT++;
				}
			}
		}
		return true;
	}

	public function remove() {
		@:privateAccess lib.Sound.allObjects.remove(this);
		ent = null;
		if( go != null ) {
			play(DestroyObject);
			haxe.Timer.delay(go.remove,1000);
			go = null;
		}
	}

	public function stopAll() {
		if( go != null ) go.stopAll();
	}

	public function toString() {
		return ent == null ? kind.toString() : ent.toString();
	}

}

class Sound {

	static var allObjects : Array<SoundObject> = [];
	static var UPDATE_COUNT = 0;
	public static var global : SoundObject;
	public static var ui : SoundObject;
	public static var item : SoundObject;
	public static var tmpElement : SoundObject;

	public static function init() {
		#if !disable_sound
		if(!Game.PREFS.noSound) {
			if( !wwise.Api.init("res/audio", Game.PREFS.debugWwise) )
				throw "FAILED TO INIT WWISE";
			for( f in sys.FileSystem.readDirectory("res/audio") )
				if( StringTools.endsWith(f,".bnk") )
					wwise.Api.loadBank(f);
		}
		#end
		global = new SoundObject(Global);
		ui = new SoundObject(UI);
		item = new SoundObject(Item);
		tmpElement = new SoundObject(Element);
	}

	public static inline function noLog( f ) {
		var prev = Game.PREFS.soundLog;
		Game.PREFS.soundLog = false;
		f();
		Game.PREFS.soundLog = prev;
	}

	public static function stopAll() {
		global.stopAll();
		ui.stopAll();
		item.stopAll();
		tmpElement.stopAll();
	}

	static var wiseLagsTime = 0.;
	static var wiseLagsCount = 0;

	public static function update() {
		var t0 = haxe.Timer.stamp();
		var i = 0;
		UPDATE_COUNT = 0;
		while( i < allObjects.length ) {
			var o = allObjects[i++];
			if( @:privateAccess !o.update() ) {
				o.remove();
				i--;
			}
		}
		wwise.Api.update();
		var et = haxe.Timer.stamp() - t0;
		if( et > 0.1 ) {
			wiseLagsTime += et;
			wiseLagsCount++;
			if( wiseLagsTime > 1 ) {
				Main.logMessage('WWise Lock $wiseLagsCount',{ time : et });
				wiseLagsTime -= 0.5;
			}
		} else if( wiseLagsTime > 0 )
			wiseLagsTime -= 0.001;
	}

}