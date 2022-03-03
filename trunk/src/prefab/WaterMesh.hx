package prefab;

// import hxsl.Output;

// class WaterBakeShader extends h3d.shader.ScreenShader {

// 	static var SRC = {

		/*var heightMap : Vec4;

		@global var global : {
			var time : Float;
		};

		@param var from : Vec2;
		@param var to : Vec2;

		@param @const var WAVE_NUMBER : Int;
		@param @const var WAVE_NUMBER_BIS : Int;
		@param var waveIntensities : Array<Float,WAVE_NUMBER>;
		@param var waveFrequencies : Array<Float,WAVE_NUMBER>;
		@param var waveVectors : Array<Float,WAVE_NUMBER_BIS>;

		var waveOffset : Float;

		function wave(pos : Vec2) : Float {
			waveOffset = 0.0;
			@unroll for (i in 0...WAVE_NUMBER) {
				waveOffset += waveIntensities[i] * sin(dot(pos, vec2(waveVectors[2*i], waveVectors[2*i+1])) + waveFrequencies[i] * global.time);
			}
			return waveIntensities[0] * waveOffset;
		}

		function vertex() {
			output.position = vec4(uvToScreen(mix(from, to, screenToUv(input.position))), 0, 1);
			output.position.y *= flipY;
		}

		function fragment() {
			var height = wave(output.position.xy);
			var tangentUV = output.position.xy + vec2(0.1, 0.0);
			var tangent = normalize(vec3(tangentUV, wave(tangentUV)) - vec3(output.position.xy, height));
			var bitangentUV = output.position.xy + vec2(0.0, 0.1);
			var bitangent = normalize(vec3(bitangentUV, wave(bitangentUV)) - vec3(output.position.xy, height));
			var normal = normalize(cross(tangent, bitangent));
			heightMap = vec4(normal, height);
		}*/
// 	}
// }

// class WaterMesh extends hrt.prefab.terrain.TerrainMesh {

	/*var pixelPerUnit = 4;
	public var heightMap : h3d.mat.Texture;
	public var fromTo = new h3d.Vector();
	var bounds = new h3d.Vector();

	var waterBakeShader = new WaterBakeShader();
	var colorMapWidth = 128;
	var colorMapHeight = 128;

	public function resize() {
		if ( heightMap != null )
			heightMap.dispose();

		updateBounds();

		bounds.x = bounds.y = bounds.z = bounds.w = 0.0;
		for( t in tiles ) {
			bounds.x = hxd.Math.min(bounds.x, t.tileX);
			bounds.y = hxd.Math.max(bounds.y, t.tileX + 1);
			bounds.z = hxd.Math.min(bounds.z, t.tileY);
			bounds.w = hxd.Math.max(bounds.w, t.tileY + 1);
		}

		var width = Std.int(hxd.Math.abs(bounds.x) + hxd.Math.abs(bounds.y));
		var height = Std.int(hxd.Math.abs(bounds.z) + hxd.Math.abs(bounds.w));

		colorMapWidth = Std.int(width * tileSize.x * pixelPerUnit);
		colorMapHeight = Std.int(height * tileSize.y * pixelPerUnit);
		heightMap = new h3d.mat.Texture(colorMapWidth, colorMapHeight, [Target]);
	}

	function updateBounds() {
		var minX = 0.0;
		var maxX = 0.0;
		var minY = 0.0;
		var maxY = 0.0;
		for( t in tiles ) {
			minX = hxd.Math.min(minX, t.tileX);
			maxX = hxd.Math.max(maxX, t.tileX + 1);
			minY = hxd.Math.min(minY, t.tileY);
			maxY = hxd.Math.max(maxY, t.tileY + 1);
		}
		minX *= tileSize.x;
		maxX *= tileSize.y;
		minY *= tileSize.x;
		maxY *= tileSize.y;
		var pos = getAbsPos().getPosition();
		fromTo.set(minX, minY, maxX, maxY);
	}

	override function sync(ctx) {
		super.sync(ctx);

		var engine = h3d.Engine.getCurrent();
		var output = [Value("heightMap")];
		var ss = new h3d.pass.ScreenFx(waterBakeShader, output);
		ss.setGlobals(@:privateAccess ctx.scene.renderer.ctx);
		engine.pushTargets([heightMap]);
		for( t in tiles ) {
			ss.shader.from.set(((t.tileX - bounds.x) * (tileSize.x * pixelPerUnit)) / colorMapWidth, ((t.tileY - bounds.z) * (tileSize.y * pixelPerUnit)) / colorMapHeight);
			ss.shader.to.set(ss.shader.from.x + (tileSize.x * pixelPerUnit) / colorMapWidth, ss.shader.from.y + (tileSize.y * pixelPerUnit) / colorMapHeight);
			ss.render();
		}
		engine.popTarget();
	}*/
// }


