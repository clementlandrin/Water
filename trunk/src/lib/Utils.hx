package lib;

#if !macro

@:genericClassPerMethod
class Utils {

	inline public static function mapRange(inVal:Float, inMin:Float, inMax:Float, outMin:Float, outMax:Float) {
		var t = hxd.Math.clamp((inVal - inMin) / (inMax - inMin), 0, 1);
		return hxd.Math.lerp(outMin, outMax, t);
	}

	inline public static function toVector(pt : h2d.col.Point, z:Float) {
		return new h3d.Vector(pt.x, pt.y, z);
	}

	inline public static function to2D(vec : h3d.Vector) {
		return new h2d.col.Point(vec.x, vec.y);
	}

	public static function toDirection(pt : h2d.col.Point) {
		return Math.atan2(pt.y, pt.x);
	}

	inline public static function mapIter<K,V>(map: Map<K,V>, func: K->V->Void) {
		for(k in map.keys()) {
			var v = map[k];
			func(k, v);
		}
	}

	/**
		Iterate over all items starting from a random index. Use findRand to interrupt search
	**/
	inline public static function iterRand<T>(a: Array<T>, func: Int->T->Void) {
		var len = a.length;
		var offset = Std.random(len);
		for(i in 0...len) {
			var idx = (i + offset) % len;
			var item = a[idx];
			func(idx, item);
		}
	}

	/**
		Iterate over all items starting from a random index, until func returns a non-null value
	**/
	inline public static function findRand<T, R>(a: Array<T>, func: Int->T->R, ?rnd: hxd.Rand) : R {
		var len = a.length;
		var offset = (rnd != null) ? rnd.random(len) : Std.random(len);
		var ret : R = null;
		for(i in 0...len) {
			var idx = (i + offset) % len;
			var item = a[idx];
			ret = func(idx, item);
			if(ret != null) {
				break;
			}
		}
		return ret;
	}

	#if release @:generic #end
	static public function flatten<T>(arrs: Array<Array<T>>) {
		var ret = [];
		for(a in arrs)
			ret = ret.concat(a);
		return ret;
	}

	inline static public function last<T>(a: Array<T>) {
		return a[a.length - 1];
	}

	inline static public function clear<T>(a: Array<T>) {
		while(a.length > 0)
			a.pop();
	}

	inline static public function pushUnique<T>(a: Array<T>, item: T) {
		if(a.indexOf(item) < 0)
			a.push(item);
	}

	inline static public function appendUnique<T>(a: Array<T>, items: Array<T>) {
		for(item in items) {
			a.pushUnique(item);
		}
	}

	public static inline function shuffle<T>( a : Array<T>, ?rnd: hxd.Rand) {
		var len = a.length;
		for( i in 0...len ) {
			var y = rnd != null ? rnd.random(len) : Std.random(len);
			var tmp = a[i];
			a[i] = a[y];
			a[y] = tmp;
		}
	}

	public static function pickRandom<T>(a: Array<T>, ?rnd: hxd.Rand) {
		if(a.length == 0) return null;
		return a[rnd != null ? rnd.random(a.length) : Std.random(a.length)];
	}

	#if release @:generic #end
	public static function pickWeight<T>(array: Array<T>, weight: T -> Float, ?rnd: hxd.Rand) {
		if(array.length == 0) return null;
		var total = 0.0;
		for(i in array)
			total += weight(i);
		if(total == 0)
			return pickRandom(array, rnd);
		var rnd = ((rnd != null) ? rnd.rand() : Math.random()) * total;
		for(i in array) {
			rnd -= weight(i);
			if( rnd < 0 )
				return i;
		}
		throw "assert";
	}

	inline static public function removeAll<T>(a: Array<T>, func: T->Bool) {
		var i = a.length;
		while (i-- > 0) {
			if(func(a[i])) {
				a.remove(a[i]);
			}
		}
	}

	inline public static function exists<T>( it : Array<T>, f : T -> Bool ) : Bool {
		var ret = false;
		for( v in it ) {
			if(f(v)) {
				ret = true;
				break;
			}
		}
		return ret;
	}

	// Don't make this Iterable<T> (causes a cast on arrays)
	inline public static function find<T>( it : Array<T>, f : T -> Bool ) : Null<T> {
		var ret = null;
		for( v in it ) {
			if(f(v)) {
				ret = v;
				break;
			}
		}
		return ret;
	}

	inline public static function any<T>( it : Array<T>, f : T -> Bool ) : Bool {
		return find(it, f) != null;
	}

	inline public static function all<T>( it : Array<T>, f : T -> Bool ) : Bool {
		return find(it, e -> !f(e)) == null;
	}

	public static function sum( a : Array<Float> ) : Float {
		var s = 0.0;
		for(v in a)
			s += v;
		return s;
	}

	public static function max( a : Array<Float> ) : Float {
		if(a.length == 0)
			return 0.0;
		var ret = a[0];
		for(v in a) {
			if(v > ret)
				ret = v;
		}
		return ret;
	}

	// Don't make this Iterable<T> (causes a cast on arrays)
	inline public static function count<T>( it : Array<T>, f : T -> Bool ) : Int {
		var ret = 0;
		for( v in it ) {
			if(f(v)) {
				++ret;
			}
		}
		return ret;
	}

	// Don't make this Iterable<T> (causes a cast on arrays)
	inline public static function has<A>( it : Array<A>, elt : A ) : Bool {
		return it.indexOf(elt) >= 0;
	}

	#if release @:generic #end
	static public function append<T>(a: Array<T>, b: Array<T>) {
		for(e in b) {
			a.push(e);
		}
		return a;
	}

	#if release @:generic #end
	static public function split<T>(a: Array<T>, numGroups: Int): Array<Array<T>> {
		var groups = [for(_ in 0...numGroups) []];
        if(a.length >= 2) {
            for(i in 0...a.length)
                groups[Math.round((numGroups - 1) * i / (a.length - 1))].push(a[i]);
		}
		else if(a.length == 1)
			groups[0].push(a[0]);
		return groups;
	}

	inline static public function findMin<T>(a: Array<T>, f: T->Float, filter: T->Bool) {
		var minVal = 1e10;
		var minItem = null;
		for(item in a) {
			if(filter != null && !filter(item))
				continue;
			var v = f(item);
			if(v < minVal) {
				minVal = v;
				minItem = item;
			}
		}
		return { item: minItem, val: minVal };
	}

	inline static public function findMinItem<T>(a: Array<T>, f: T->Float, filter: T->Bool) : T {
		return findMin(a, f, filter).item;
	}

	inline static public function findMinValue<T>(a: Array<T>, f: T->Float, filter: T->Bool) : Float {
		return findMin(a, f, filter).val;
	}

	inline static public function findMaxItem<T>(a: Array<T>, f: T->Float, filter: T->Bool) : T{
		return findMin(a, i -> -f(i), filter).item;
	}

	inline static public function findMaxValue<T>(a: Array<T>, f: T->Float, filter: T->Bool) : Float {
		return -findMin(a, i -> -f(i), filter).val;
	}

	#if release @:generic #end
	public static function areEqual<A>( a : Iterable<A>, b : Iterable<A> ) : Bool {
		if(a == null && b == null) return true;
		if(a == null || b == null) return false;

		for(av in a) {
			if(!b.iterator().hasNext())
				return false;
			if(av != b.iterator().next())
				return false;
		}
		if(b.iterator().hasNext())
			return false;

		return true;
	}

	#if release @:generic #end
	public static function areSetEqual<A>( a : Array<A>, b : Array<A> ) : Bool {
		if(a.length != b.length)
			return false;
		for(av in a) {
			if(b.indexOf(av) < 0)
				return false;
		}
		return true;
	}

	inline public static function getAngle(pt: h2d.col.Point) {
		return hxd.Math.atan2(pt.y, pt.x);
	}

	inline public static function rounded(pt: h2d.col.Point) {
		return new h2d.col.Point(Math.round(pt.x), Math.round(pt.y));
	}

	inline public static function rotToDir(rot: Float) {
		return new h2d.col.Point(Math.cos(rot), Math.sin(rot));
	}

	/** Return true `freq` times per second, on average  **/
	public static function checkFreq(dt: Float, freq: Float) {
		return Math.random() < dt * freq;
	}

	inline public static function convert(map : Map<String, Dynamic>) : Array<{ key : String, value : Dynamic}> {
		var array = [];
		for (k in map.keys()) {
			array.push({ key : k, value : map.get(k) });
		}
		return array;
	}

	public static function findRandomPoint(point: h2d.col.Point, minDist: Float, maxDist: Float, fct : (h2d.col.Point) -> Bool, ?rand : hxd.Rand) {
		var random : Void -> Float = Math.random;
		if (rand != null)
			random = rand.rand;
		var spawnPt = new h2d.col.Point();
		final rtries = 20;
		final atries = 12;
		var pi2 = Math.PI*2;
		var initAngle = random() * pi2;
		for(i in 0...rtries) {
			var radius = minDist + random() * (maxDist-minDist) * i/rtries;
			for (r in 0...atries) {
				var theta = initAngle + (r+random())*(pi2/atries);
				spawnPt.set(point.x + Math.cos(theta) * radius, point.y + Math.sin(theta) * radius);
				if (fct(spawnPt))
					return spawnPt;
			}
		}
		return null;
	}

	public static inline function randomInRange(min: Float, max: Float) {
		return min + hxd.Math.random(max - min);
	}

	public static inline function getBezierPoint(p1 : h3d.Vector, p2 : h3d.Vector, p3 : h3d.Vector, p4 : h3d.Vector, t : Float) {
		var m1 = p1.multiply(Math.pow(1-t, 3));
		var m2 = p2.multiply(Math.pow(1-t, 2) * t * 3.0);
		var m3 = p3.multiply(Math.pow(t, 2) * (1-t) * 3.0);
		var m4 = p4.multiply(Math.pow(t, 3));

		return m1.add(m2.add(m3.add(m4)));
	}

	public static inline function createPolygon2d(polygon : hrt.prefab.l3d.Polygon) : h2d.col.Polygon {
		return switch(polygon.shape) {
			case Disc(segments, angle, inner, rings):
				if(angle >= 360)
					angle = 360;
				++segments;
				var anglerad = hxd.Math.degToRad(angle);
				[for(i in 0...segments) {
					var t = i / (segments - 1);
					var a = hxd.Math.lerp(-anglerad/2, anglerad/2, t);
					var ct = hxd.Math.cos(a);
					var st = hxd.Math.sin(a);
					new h2d.col.Point(ct, st);
				}];
			case Quad(subdivision):
				[
					new h2d.col.Point(-0.5, -0.5),
					new h2d.col.Point(0.5, -0.5),
					new h2d.col.Point(0.5,  0.5),
					new h2d.col.Point(-0.5,  0.5)
				];
			default:
				polygon.points.copy();
		}
	}


	public static function expand(b: h2d.col.IBounds, size : Int) {
		b.xMin -= size;
		b.yMin -= size;
		b.xMax += size;
		b.yMax += size;
	}

	#if !network
	inline static public function getValue<C>( a: Array<C> ) {
		return a;
	}
	#end

}

#if network
@:genericClassPerMethod
class UtilsProxy {

	inline static public function removeAll<C>( a: hxbit.ArrayProxy<C>, func : C -> Bool ) {
		var i = a.length;
		while (i-- > 0) {
			if(func(a[i])) {
				a.remove(a[i]);
			}
		}
	}

	inline static public function getValue<C>( a: hxbit.ArrayProxy<C> ) {
		return a.__value;
	}

	inline static public function pushUnique<C>( a: hxbit.ArrayProxy<C>, v : C ) {
		if( a.indexOf(v) < 0 ) a.push(v);
	}

	inline static public function has<C>( a: hxbit.ArrayProxy<C>, v : C ) : Bool {
		return a.indexOf(v) >= 0;
	}

	inline static public function count<C>( a: hxbit.ArrayProxy<C>, f : C -> Bool ) : Int {
		var ret = 0;
		for( v in a ) {
			if(f(v)) {
				++ret;
			}
		}
		return ret;
	}

	inline static public function find<C>( a: hxbit.ArrayProxy<C>, f : C -> Bool ) : Null<C> {
		var ret = null;
		for( v in a ) {
			if(f(v)) {
				ret = v;
				break;
			}
		}
		return ret;
	}

	inline public static function exists<T>( it : hxbit.ArrayProxy<T>, f : T -> Bool ) : Bool {
		var ret = false;
		for( v in it ) {
			if(f(v)) {
				ret = true;
				break;
			}
		}
		return ret;
	}

}

@:genericClassPerMethod
class UtilsProxy2 {

	inline static public function removeAll<C:hxbit.NetworkSerializable.ProxyChild>( a: hxbit.ArrayProxy.ArrayProxy2<C>, func : C -> Bool ) {
		var i = a.length;
		while (i-- > 0) {
			if(func(a[i])) {
				a.remove(a[i]);
			}
		}
	}
}

#end

@:genericClassPerMethod
class CDBUtils {
	inline static public function find<C>( a: cdb.Types.ArrayRead<C>, f : C -> Bool ) : Null<C> {
		var ret = null;
		for( v in a ) {
			if(f(v)) {
				ret = v;
				break;
			}
		}
		return ret;
	}

	/**
		Iterate over all items starting from a random index, until func returns a non-null value
	**/
	inline public static function findRandCdb<T, R>(a: cdb.Types.ArrayRead<T>, func: Int->T->R) : R {
		var len = a.length;
		var offset = Std.random(len);
		var ret : R = null;
		for(i in 0...len) {
			var idx = (i + offset) % len;
			var item = a[idx];
			ret = func(idx, item);
			if(ret != null) {
				break;
			}
		}
		return ret;
	}
}

#end

class MacroUtils {
	public static macro function or(a: haxe.macro.Expr, d: haxe.macro.Expr) {
		return macro if($a != null) $a else $d;
	}
}
