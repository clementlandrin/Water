import h3d.scene.*;

class Game extends hxd.App {

	public static var inst : Game;

	var fui : h2d.Flow;

	public var time : Float = 0.;
	var obj1 : Mesh;
	var obj2 : Mesh;
	var rootCtx : hrt.prefab.Context;

	public function new() {
		inst = this;
		super();
	}

	override function init() {
		// initialize embeded ressources
		hxd.Res.initLocal();

		s3d.renderer = new h3d.scene.pbr.Renderer();

		fui = new h2d.Flow(s2d);
		fui.layout = Vertical;
		fui.verticalSpacing = 5;
		fui.padding = 10;

		var res = hxd.Res.levels.island_prefab;
		rootCtx = makeContext(s3d, res);
		res.load().make(rootCtx);

		s3d.camera.pos.set(0.5 * 50, 0.5 * 50, 50);
	}

	function getFont() {
		return hxd.res.DefaultFont.get();
	}

	function addButton( label : String, onClick : Void -> Void ) {
		var f = new h2d.Flow(fui);
		f.padding = 5;
		f.paddingBottom = 7;
		f.backgroundTile = h2d.Tile.fromColor(0x404040);
		var tf = new h2d.Text(getFont(), f);
		tf.text = label;
		f.enableInteractive = true;
		f.interactive.cursor = Button;
		f.interactive.onClick = function(_) onClick();
		f.interactive.onOver = function(_) f.backgroundTile = h2d.Tile.fromColor(0x606060);
		f.interactive.onOut = function(_) f.backgroundTile = h2d.Tile.fromColor(0x404040);
		return f;
	}

	function addSlider( label : String, get : Void -> Float, set : Float -> Void, min : Float = 0., max : Float = 1. ) {
		var f = new h2d.Flow(fui);

		f.horizontalSpacing = 5;

		var tf = new h2d.Text(getFont(), f);
		tf.text = label;
		tf.maxWidth = 70;
		tf.textAlign = Right;

		var sli = new h2d.Slider(100, 10, f);
		sli.minValue = min;
		sli.maxValue = max;
		sli.value = get();

		var tf = new h2d.TextInput(getFont(), f);
		tf.text = "" + hxd.Math.fmt(sli.value);
		sli.onChange = function() {
			set(sli.value);
			tf.text = "" + hxd.Math.fmt(sli.value);
			f.needReflow = true;
		};
		tf.onChange = function() {
			var v = Std.parseFloat(tf.text);
			if( Math.isNaN(v) ) return;
			sli.value = v;
			set(v);
		};
		return sli;
	}

	function addCheck( label : String, get : Void -> Bool, set : Bool -> Void ) {
		var f = new h2d.Flow(fui);

		f.horizontalSpacing = 5;

		var tf = new h2d.Text(getFont(), f);
		tf.text = label;
		tf.maxWidth = 70;
		tf.textAlign = Right;

		var size = 10;
		var b = new h2d.Graphics(f);
		function redraw() {
			b.clear();
			b.beginFill(0x808080);
			b.drawRect(0, 0, size, size);
			b.beginFill(0);
			b.drawRect(1, 1, size-2, size-2);
			if( get() ) {
				b.beginFill(0xC0C0C0);
				b.drawRect(2, 2, size-4, size-4);
			}
		}
		var i = new h2d.Interactive(size, size, b);
		i.onClick = function(_) {
			set(!get());
			redraw();
		};
		redraw();
		return i;
	}

	function addChoice( text, choices, callb : Int -> Void, value = 0 ) {
		var font = getFont();
		var i = new h2d.Interactive(110, font.lineHeight, fui);
		i.backgroundColor = 0xFF808080;
		fui.getProperties(i).paddingLeft = 20;

		var t = new h2d.Text(font, i);
		t.maxWidth = i.width;
		t.text = text+":"+choices[value];
		t.textAlign = Center;

		i.onClick = function(_) {
			value++;
			value %= choices.length;
			callb(value);
			t.text = text + ":" + choices[value];
		};
		i.onOver = function(_) {
			t.textColor = 0xFFFFFF;
		};
		i.onOut = function(_) {
			t.textColor = 0xEEEEEE;
		};
		i.onOut(null);
		return i;
	}

	function addText(text="") {
		var tf = new h2d.Text(getFont(), fui);
		tf.text = text;
		return tf;
	}

	override function update( dt : Float ) {

		// time is flying...
		time += dt;

		// move the camera position around the two cubes
		//var dist = 50;
		//s3d.camera.pos.set(Math.cos(time) * dist, Math.sin(time) * dist, dist);
	}

	public function makeContext( ?parent : h3d.scene.Object, ?res : hxd.res.Resource ) {
		var ctx = new hrt.prefab.Context();
		ctx.init(res);
		if( parent != null ) ctx.local3d = ctx.shared.root3d = parent;
		return ctx;
	}
}