package prefab;

class WaterShader extends hxsl.Shader {

	static var SRC = {
		@input var input : {
			var position : Vec3;
		};

		@global var global : {
			var time : Float;
			@perObject var modelView : Mat4;
		};

		var output : {
			var position : Vec4;
		};

		@global var camera : {
			var inverseViewProj : Mat4;			var inverseViewProj : Mat4;

		};
		@global var depthMap : Channel;


		@param var nearWaterColor : Vec3;
		@param var middleWaterColor : Vec3;
		@param var deepWaterColor: Vec3;
		@param var waterRoughness : Float;
		@param var opacityPower : Float;
		@param var maxDepth : Float;

		@param var waveIntensity : Float;

		@param var shoreDepth : Float;

		@param var from : Vec2;
		@param var to : Vec2;
		@param var rotate : Vec2;
		@param var translate : Vec2;
		@param var invScale : Vec2;
		@param var normalHeightTexture : Sampler2D;

		var relativePosition : Vec3;
		var projectedPosition : Vec4;
		var tangentViewPos : Vec3;
		var tangentFragPos : Vec3;
		var transformedPosition : Vec3;
		var transformedNormal : Vec3;
		var terrainNormal : Vec3;

		var pixelColor : Vec4;
		var roughness : Float;

		var waterDepth : Float;

		function wave(pos : Vec3) : Vec3 {
			return pos + saturate(waterDepth / shoreDepth) * waveIntensity * vec3(0.0, 0.0, 0.2 * sin(pos.x + global.time));
		}

		function d(delta : Vec3) : Vec3 {
			return normalize(wave(transformedPosition + delta) - wave(transformedPosition));
		}

		function vertex() {
			var rotatePos = transformedPosition.xy + translate;
			rotatePos = vec2(rotatePos.x * rotate.x - rotatePos.y * rotate.y, rotatePos.x * rotate.y + rotatePos.y * rotate.x);
			rotatePos *= invScale;
			var terrainUV = (rotatePos - from) / (abs(to) + abs(from));
			var terrainHeightNormal = normalHeightTexture.get(terrainUV).rgba;
			var terrainHeight = terrainHeightNormal.a;
			waterDepth = (relativePosition * global.modelView.mat3x4()).z - terrainHeight;

			transformedPosition.xyz = wave(transformedPosition);
		}

		function fragment() {
			var screenPos = projectedPosition.xy / projectedPosition.w;
			var depth = depthMap.get(screenToUv(screenPos));
			var ruv = vec4( screenPos, depth, 1 );
			var ppos = ruv * camera.inverseViewProj;
			var wpos = ppos.xyz / ppos.w;

			var p0 = 0.0;
			var p1 = shoreDepth / maxDepth;
			var p2 = 1.0;
			var t = saturate(1.0 - waterDepth / maxDepth);
			var waterColor = mix(deepWaterColor, mix(middleWaterColor, nearWaterColor, smoothstep(p1, p2, t)), smoothstep(p0, p1, t));

			var opacity = mix(0.2, 1.0, pow(1.0 - t, opacityPower));

			pixelColor.rgba = vec4(waterColor, opacity);
			transformedNormal = cross(d(vec3(0.1, 0.0, 0.0)), d(vec3(0.0, 0.1, 0.0)));
			roughness = waterRoughness;
		}
	};

}


class Water extends hrt.prefab.terrain.Terrain {

	@:s public var nearWaterColor : Int = 0xffffff;
	@:s public var middleWaterColor : Int = 0xffffff;
	@:s public var deepWaterColor : Int = 0xffffff;
	@:s public var roughness : Float = 0.0;
	@:s public var opacityPower : Float = 5.0;
	@:s public var maxDepth : Float = 5.0;

	@:s public var waveIntensity : Float = 1.0;

	@:s public var shoreDepth : Float = 1.0;

	var waterShader = new WaterShader();

	override function makeInstance( ctx : hrt.prefab.Context ) : hrt.prefab.Context {
		ctx = super.makeInstance(ctx);
		var t = cast ctx.local3d.getScene().find( o -> Std.isOfType(o, prefab.terrain.TerrainMesh) ? o : null);
		if( t != null ) {
			var terrain  : prefab.terrain.TerrainMesh = cast t;
			terrain.syncWaterShader(waterShader);
		}
		return ctx;
	}

	override function updateInstance( ctx: hrt.prefab.Context, ?propName : String ) {
		super.updateInstance(ctx);
		waterShader.nearWaterColor = h3d.Vector.fromColor(nearWaterColor);
		waterShader.middleWaterColor = h3d.Vector.fromColor(middleWaterColor);
		waterShader.deepWaterColor = h3d.Vector.fromColor(deepWaterColor);
		waterShader.waterRoughness = roughness;
		waterShader.opacityPower = opacityPower;
		waterShader.maxDepth = maxDepth;

		waterShader.waveIntensity = waveIntensity;

		waterShader.shoreDepth = shoreDepth;
	}

	override function loadTiles( ctx : hrt.prefab.Context ) {
		super.loadTiles(ctx);
		for (t in @:privateAccess terrain.tiles) {
			t.material.mainPass.setPassName("decal");
			t.material.mainPass.setBlendMode(Alpha);
			t.material.mainPass.depthWrite = false;
			t.material.mainPass.culling = None;
			var terrainShader = t.material.mainPass.getShader(hrt.shader.Terrain);
			if ( terrainShader != null )
				t.material.mainPass.removeShader(terrainShader);
			var shader : hxsl.Shader = t.material.mainPass.getShader(WaterShader);
			if ( shader == null )
				t.material.mainPass.addShader(waterShader);
			shader = t.material.mainPass.getShader(h3d.shader.pbr.StrengthValues);
			if ( shader == null )
				t.material.mainPass.addShader(new h3d.shader.pbr.StrengthValues());
		}
	}

	#if editor

	override function getHideProps() : hide.prefab.HideProps {
		return { icon : "square", name : "Water" };
	}

	override function edit( ctx : hide.prefab.EditContext ) {
		super.edit(ctx);
		ctx.properties.add(new hide.Element('
			<div class="group" name="Surface">
				<dl>
					<dt>Cells</dt><dd><input type="range" min="1" max="100" step="1" field="cellCount"/></dd>
				</dl>
			</div>
			<div class="group" name="Color">
				<dl>
					<dt>Near Water Color </dt><dd><input type="color" field="nearWaterColor"/></dd>
					<dt>Middle Water Color</dt><dd><input type="color" field="middleWaterColor"/></dd>
					<dt>Deep Water Color</dt><dd><input type="color" field="deepWaterColor"/></dd>
					<dt>Roughness</dt><dd><input type="range" min="0" max="1" field="roughness"/></dd>
					<dt>Opacity Power</dt><dd><input type="range" min="0" max="5" field="opacityPower"/></dd>
					<dt>Lake max depth</dt><dd><input type="range" min="0" max="4" field="maxDepth"/></dd>
				</dl>
			</div>
			<div class="group" name="Color Noise">
				<dl>
					<dt>Texture</dt><dd><input type="texturepath" field="colorNoiseTexture"/></dd>
					<dt>Scale</dt><dd><input type="range" min="0" max ="1" step="0.01" field="colorNoiseScale"/></dd>
					<dt>Strength</dt><dd><input type="range" min="0" max ="1" step="0.01" field="colorNoiseStrength"/></dd>
				</dl>
			</div>
			<div class="group" name="Wave">
				<dl>
					<dt>Wave Intensity</dt><dd><input type="range" min="0" max="10" field="waveIntensity"/></dd>
					<dt>Wave Speed</dt><dd><input type="range" min="0" max="1" field="waveSpeed"/></dd>
				</dl>
			</div>
			<div class="group" name="Shore">
				<dl>
					<dt>Shore depth</dt><dd><input type="range" min="0" max="10" field="shoreDepth"/></dd>
				</dl>
			</div>
			'), this, function(pname) {
				ctx.onChange(this, pname);
		});
	}

	#end

	static var _ = hrt.prefab.Library.register("water", Water);

}