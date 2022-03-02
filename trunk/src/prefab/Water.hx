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
			var inverseViewProj : Mat4;
		};
		@global var depthMap : Channel;


		@param var nearWaterColor : Vec3;
		@param var middleWaterColor : Vec3;
		@param var deepWaterColor: Vec3;
		@param var waterRoughness : Float;
		@param var opacityPower : Float;
		@param var maxDepth : Float;

		@param @const var WAVE_NUMBER : Int;
		@param @const var WAVE_NUMBER_BIS : Int;
		@param var waveIntensities : Array<Float,WAVE_NUMBER>;
		@param var waveDirections : Array<Float,WAVE_NUMBER>;
		@param var waveFrequencies : Array<Float,WAVE_NUMBER>;
		@param var waveVectors : Array<Float,WAVE_NUMBER_BIS>;
		@param var normalStrength : Float;

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

		var waveOffset : Float;

		function wave(pos : Vec3) : Vec3 {
			waveOffset = 0.0;
			@unroll for (i in 0...WAVE_NUMBER) {
				waveOffset += waveIntensities[i] * sin(dot(pos.xy, vec2(waveVectors[2*i], waveVectors[2*i+1])) + waveFrequencies[i] * global.time);
			}
			return pos + saturate(waterDepth / shoreDepth) * vec3(0.0, 0.0, waveOffset);
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
			transformedNormal = normalize(cross(d(vec3(0.1, 0.0, 0.0)), d(vec3(0.0, 0.1, 0.0))));
			transformedNormal = mix(vec3(0.0, 0.0, 1.0), transformedNormal, normalStrength);
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

	@:s public var normalStrength : Float = 1.0;

	@:s public var waves : Array<{intensity : Float, kx : Float, ky : Float, frequency : Float}> = [{intensity : 1.0, kx : 1.0, ky : 0.0, frequency : 1.0}];

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

		waterShader.WAVE_NUMBER = waves.length;
		waterShader.WAVE_NUMBER_BIS = waves.length * 2;
		var waveIntensities = [];
		var waveFrequencies = [];
		var waveVectors = [];
		for (wave in waves) {
			waveIntensities.push(wave.intensity);
			waveFrequencies.push(wave.frequency);
			waveVectors.push(wave.kx);
			waveVectors.push(wave.ky);
		}
		waterShader.waveIntensities = waveIntensities;
		waterShader.waveFrequencies = waveFrequencies;
		waterShader.waveVectors = waveVectors;

		waterShader.normalStrength = normalStrength;

		waterShader.shoreDepth = shoreDepth;
	}

	override function loadTiles( ctx : hrt.prefab.Context ) {
		super.loadTiles(ctx);
		for (t in @:privateAccess terrain.tiles) {
			t.material.mainPass.setPassName("decal");
			t.material.mainPass.setBlendMode(None);
			t.material.mainPass.depthWrite = true;
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

			var ssr = t.material.allocPass("ssr", true);
			ssr.setBlendMode(Alpha);
			ssr.depthWrite = false;
			ssr.depthTest = LessEqual;
		}
	}

	#if editor

	override function getHideProps() : hide.prefab.HideProps {
		return { icon : "square", name : "Water" };
	}

	override function edit( ectx : hide.prefab.EditContext ) {
		super.edit(ectx);
		var ctx = ectx.getContext(this);

		var e1 = new hide.Element('
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
		<div class="group" name="Shore">
			<dl>
				<dt>Shore depth</dt><dd><input type="range" min="0" max="10" field="shoreDepth"/></dd>
			</dl>
		</div>
		<dt>Normal strength</dt><dd><input type="range" min="0" max="1" field="normalStrength"/></dd>
		<div class="group" name="Waves">
			<dl>
			<ul id="wave"></ul>
			</dl>
		</div>
		');
		ectx.properties.add(e1, this, function(pname) {
				ectx.onChange(this, pname);
		});

		var list = e1.find("ul#wave");
		ectx.properties.add(e1,this, (_) -> updateInstance(ctx));
		for( wave in waves ) {
			var e = new hide.Element('
			<div class="group" name="Wave">
				<dl>
					<dt>Intensity</dt><dd><input type="range" min="0" max="3" field="intensity"/></dd>
					<dt>Direction</dt><input field="kx"/><input field="ky"/>
					<dt>Frequency</dt><dd><input type="range" min="0" max="3" field="frequency"/></dd>
				</dl>
			</div>
			');
			e.appendTo(list);
			ectx.properties.build(e, wave, (pname) -> {
				updateInstance(ctx, pname);
			});
		}
		var add = new hide.Element('<li><p><a href="#">[+]</a></p></li>');
		add.appendTo(list);
		add.find("a").click(function(_) {
			waves.push({intensity : 1.0, kx : 1.0, ky : 0.0, frequency : 1.0});
			ectx.rebuildProperties();
		});
		var sub = new hide.Element('<li><p><a href="#">[-]</a></p></li>');
		sub.appendTo(list);
		sub.find("a").click(function(_) {
			if ( waves.length > 1 )
				waves.pop();
			ectx.rebuildProperties();
		});
	}

	#end

	static var _ = hrt.prefab.Library.register("water", Water);

}