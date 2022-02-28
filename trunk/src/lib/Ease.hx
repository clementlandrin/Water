package lib;

//* ref : https://easings.net/
//! The variable t represents the absolute progress of the animation in the bounds of 0 (beginning of the animation) and 1 (end of animation).

class Ease {

	//*****************
	//* _IN_ functions

	public static function inSine(t : Float) : Float {
		return 1 - Math.cos((t * Math.PI) * 0.5);
	}

	public static function inQuad(t : Float) : Float {
		return t * t;
	}

	public static function inCubic(t : Float) : Float {
		return t * t * t;
	}

	public static function inQuart(t : Float) : Float {
		return t * t * t * t;
	}

	public static function inQuint(t : Float) : Float {
		return t * t * t * t * t;
	}

	public static function inExpo(t : Float) : Float {
		return t == 0 ? 0 : Math.pow(2, 10 * t - 10);
	}

	public static function inCirc(t : Float) : Float {
		return 1 - Math.sqrt(1 - Math.pow(t, 2));
	}

	public static function inBack(t : Float) : Float {
		var v = 1.70158;
		return (v + 1) * t * t * t - v * t * t;
	}

	public static function inElastic(t : Float) : Float {
		if(t == 0) return 0;
		if(t == 1) return 1;
		var v = (2 * Math.PI) / 3;
		return -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * v);
	}

	public static function inBounce(t : Float) : Float {
		return 1 - outBounce(1-t);
	}


	//*****************
	//* _OUT_ functions

	public static function outSine(t : Float) : Float {
		return Math.sin((t * Math.PI) * 0.5);
	}

	public static function outQuad(t : Float) : Float {
		return 1 - (1 - t) * (1 - t);
	}

	public static function outCubic(t : Float) : Float {
		return 1 - Math.pow(1 - t, 3);
	}

	public static function outQuart(t : Float) : Float {
		return 1 - Math.pow(1 - t, 4);
	}

	public static function outQuint(t : Float) : Float {
		return 1 - Math.pow(1 - t, 5);
	}

	public static function outExpo(t : Float) : Float {
		return t == 1 ? 1 : 1 - Math.pow(2, -10 * t);
	}

	public static function outCirc(t : Float) : Float {
		return Math.sqrt(1 - Math.pow(t - 1, 2));
	}

	public static function outBack(t : Float) : Float {
		var v1 = 1.70158;
		var v2 = v1 + 1;
		return 1 + v2 * Math.pow(t - 1, 3) + v1 * Math.pow(t - 1, 2);
	}

	public static function outElastic(t : Float) : Float {
		if(t == 0) return 0;
		if(t == 1) return 1;
		var v = (2 * Math.PI) / 3;
		return Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * v) + 1;
	}

	public static function outBounce(t : Float) : Float {
		var n = 7.5625;
		var d = 2.75;
		if (t < 1 / d) 	 return n * t * t;
		if (t < 2 / d)	 return n * (t -= 1.5 / d) * t + 0.75;
		if (t < 2.5 / d) return n * (t -= 2.25 / d) * t + 0.9375;
		return n * (t -= 2.625 / d) * t + 0.984375;
	}


	//*****************
	//* _IN_OUT_ functions

	public static function inOutSine(t : Float) : Float {
		return -(Math.cos(Math.PI * t) - 1) * 0.5;
	}

	public static function inOutQuad(t : Float) : Float {
		return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) * 0.5;
	}

	public static function inOutCubic(t : Float) : Float {
		return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) * 0.5;
	}

	public static function inOutQuart(t : Float) : Float {
		return t < 0.5 ? 8 * t * t * t * t : 1 - Math.pow(-2 * t + 2, 4) * 0.5;
	}

	public static function inOutQuint(t : Float) : Float {
		return t < 0.5 ? 16 * t * t * t * t *t : 1 - Math.pow(-2 * t + 2, 5) * 0.5;
	}

	public static function inOutExpo(t : Float) : Float {
		if(t == 0) return 0;
		if(t == 1) return 1;
		return t < 0.5 ? Math.pow(2, 20 * t - 10) * 0.5 : (2 - Math.pow(2, -20 * t + 10)) * 0.5;
	}

	public static function inOutCirc(t : Float) : Float {
		return t < 0.5 ? (1 - Math.sqrt(1 - Math.pow(2 * t, 2))) * 0.5 : (Math.sqrt(1 - Math.pow(-2 * t + 2, 2)) + 1) * 0.5;
	}

	public static function inOutBack(t : Float) : Float {
		var v = 1.70158 * 1.525;
		return t < 0.5 ? (Math.pow(2 * t, 2) * ((v + 1) * 2 * t - v)) * 0.5 : (Math.pow(2 * t - 2, 2) * ((v + 1) * (t * 2 - 2) + v) + 2) * 0.5;
	}

	public static function inOutElastic(t : Float) : Float {
		if(t == 0) return 0;
		if(t == 1) return 1;

		var v = (2 * Math.PI) / 4.5;
		return t < 0.5 ? -(Math.pow(2, 20 * t - 10) * Math.sin((20 * t - 11.125) * v)) * 0.5 : (Math.pow(2, -20 * t + 10) * Math.sin((20 * t - 11.125) * v)) * 0.5 + 1;
	}

	public static function inOutBounce(t : Float) : Float {
		return t < 0.5 ? (1 - outBounce(1 - 2 * t)) * 0.5 : (1 + outBounce(2 * t - 1)) * 0.5;
	}

}