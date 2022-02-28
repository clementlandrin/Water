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
		@param var roughness : Float;
		@param var opacityPower : Float;
		@param var maxDepth: Float;

		var relativePosition : Vec3;
		var projectedPosition : Vec4;
		var tangentViewPos : Vec3;
		var tangentFragPos : Vec3;
		var transformedPosition : Vec3;
		var transformedNormal : Vec3;
		var terrainNormal : Vec3;
		var pixelColor : Vec4;

		function vertex() {
			transformedNormal = vec3(1.0,0.0,0.0);
			transformedPosition.xyz += vec3(0.0, 0.0, 0.2 * sin(transformedPosition.x + global.time));
		}

		function fragment() {
			var screenPos = projectedPosition.xy / projectedPosition.w;
			var depth = depthMap.get(screenToUv(screenPos));
			var ruv = vec4( screenPos, depth, 1 );
			var ppos = ruv * camera.inverseViewProj;
			var wpos = ppos.xyz / ppos.w;
			var waterDepth = distance(wpos.xyz, transformedPosition);

			var p0 = 0.0;
			var p1 = 0.6;
			var p2 = 1.0;
			var t = saturate(1.0 - waterDepth / maxDepth);
			var waterColor = mix(deepWaterColor, mix(middleWaterColor, nearWaterColor, smoothstep(p1, p2, t)), smoothstep(p0, p1, t));

			var opacity = mix(0.2, 1.0, pow(1.0 - t, opacityPower));

			pixelColor.rgba = vec4(waterColor, opacity);
			transformedNormal = vec3(1.0,0.0,0.0);
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

	var waterShader = new WaterShader();

	override function makeInstance( ctx : hrt.prefab.Context ) : hrt.prefab.Context {
		ctx = super.makeInstance(ctx);
		return ctx;
	}

	override function updateInstance( ctx: hrt.prefab.Context, ?propName : String ) {
		super.updateInstance(ctx);
		waterShader.nearWaterColor = h3d.Vector.fromColor(nearWaterColor);
		waterShader.middleWaterColor = h3d.Vector.fromColor(middleWaterColor);
		waterShader.deepWaterColor = h3d.Vector.fromColor(deepWaterColor);
		waterShader.roughness = roughness;
		waterShader.opacityPower = opacityPower;
		waterShader.maxDepth = maxDepth;
	}

	override function loadTiles( ctx : hrt.prefab.Context ) {
		super.loadTiles(ctx);
		for (t in @:privateAccess terrain.tiles) {
			t.material.mainPass.setPassName("decal");
			t.material.mainPass.setBlendMode(Alpha);
			t.material.mainPass.depthWrite = false;
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
					<dt>NormalMap</dt><dd><input type="texturepath" field="normalMap"/></dd>
					<dt>Wave Intensity</dt><dd><input type="range" min="0" max="10" field="waveIntensity"/></dd>
					<dt>Wave Scale</dt><dd><input type="range" min="0" max="4" field="waveScale"/></dd>
					<dt>Wave Speed</dt><dd><input type="range" min="0" max="1" field="waveSpeed"/></dd>
					<dt>2d Wave Scale</dt><dd><input type="range" min="0" max="4" field="secondWaveScale"/></dd>
					<dt>2d Wave Rotate</dt><dd><input type="range" min="-180" max="180" field="secondWaveRotate"/></dd>
					<dt>2d Wave Speed</dt><dd><input type="range" min="0" max="1" field="secondWaveSpeed"/></dd>
				</dl>
			</div>
			<div class="group" name="Reflections">
				<dl>
					<dt>Reflections</dt><dd><input type="checkbox" field="reflections"/></dd>
				</dl>
			</div>
			<div class="group" name="Collisions">
				<dl>
					<dt>Collide WorldMap</dt><dd><input type="checkbox" field="collide"/></dd>
				</dl>
			</div>
			'), this, function(pname) {
				ctx.onChange(this, pname);
		});
	}

	#end

	static var _ = hrt.prefab.Library.register("water", Water);

}