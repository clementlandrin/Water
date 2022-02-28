package prefab.terrain;

import hxsl.Output;

class TerrainBlend extends hxsl.Shader {

	static var SRC = {

		// Terrain
		@param var from : Vec2;
		@param var to : Vec2;
		@param var normalHeightTexture : Sampler2D;
		@param var range : Float;
		@param var rotate : Vec2;
		@param var translate : Vec2;
		@param var invScale : Vec2;
		#if editor
		@const @param var DEBUG : Bool;
		#end

		var shadowPass : Bool;

		var transformedPosition : Vec3;
		var transformedNormal : Vec3;
		var relativePosition : Vec3;
		var pixelColor : Vec4;
		var terrainHeight : Float;
		var terrainNormal : Vec3;

		function __init__fragment() {{
			shadowPass = false;
		}}

		function fragment() {
			var rotatePos = transformedPosition.xy + translate;
			rotatePos = vec2(rotatePos.x * rotate.x - rotatePos.y * rotate.y, rotatePos.x * rotate.y + rotatePos.y * rotate.x);
			rotatePos *= invScale;
			var terrainUV = (rotatePos - from) / (abs(to) + abs(from));
			var terrainHeightNormal = normalHeightTexture.get(terrainUV).rgba;
			terrainHeight = terrainHeightNormal.a;
			terrainNormal = terrainHeightNormal.rgb;
			var blendAmout = 1.0 - pow(1.0 - saturate((transformedPosition.z - terrainHeight) / range), 2.0);
			#if editor
			if (DEBUG)
				pixelColor.rgb = vec3(blendAmout);
			else
			#end
			pixelColor.a *= blendAmout;
			if (shadowPass && pixelColor.a < 1.0)
				discard;
		}
	}
}

class TerrainBlendShadowPass extends hxsl.Shader {
	static var SRC = {
		var shadowPass : Bool;
		function fragment() {
			shadowPass = true;
		}
	}
}

class TerrainColorNormalShader extends hxsl.Shader {

	static var SRC = {

		@param var range : Float;
		@param var from : Vec2;
		@param var to : Vec2;
		@param var albedoTexture : Sampler2D;
		@param var normalHeightTexture : Sampler2D;
		@param var rotate : Vec2;
		@param var translate : Vec2;
		@param var invScale : Vec2;
		#if editor
		@const @param var DEBUG : Bool;
		#end
		var transformedPosition : Vec3;
		var transformedNormal : Vec3;
		var pixelColor : Vec4;
		var relativePosition : Vec3;

		var terrainNormal : Vec3;
		var terrainColor : Vec3;

		function fragment() {
			var rotatePos = transformedPosition.xy + translate;
			rotatePos = vec2(rotatePos.x * rotate.x - rotatePos.y * rotate.y, rotatePos.x * rotate.y + rotatePos.y * rotate.x);
			rotatePos *= invScale;
			var terrainUV = (rotatePos - from) / (abs(to) + abs(from));
			var terrainHeightNormal = normalHeightTexture.get(terrainUV).rgba;
			terrainNormal = unpackNormal(vec4(terrainHeightNormal.rgb, 1.0)).rgb;

			terrainColor = albedoTexture.get(terrainUV).rgb;
			var amount = smoothstep(0, 1, saturate(relativePosition.z / range));
			#if editor
			if (DEBUG) {
				var blendAmout = 1.0 - pow(1.0 - saturate((transformedPosition.z - terrainHeightNormal.a) / range), 2.0);
				pixelColor.rgb = vec3(blendAmout);
			}
			else
			#end
			pixelColor.rgb = mix(terrainColor, pixelColor.rgb, amount);
			transformedNormal = mix(terrainNormal, transformedNormal, amount);
		}
	}
}

private class TerrainBakeShader extends h3d.shader.ScreenShader {

	static var SRC = {

		// Output
		var albedoOutput : Vec4;
		var normalOutput : Vec4;
		var pbrOutput : Vec4;

		@const var SURFACE_COUNT : Int;

		@param var albedoTextures : Sampler2DArray;
		@param var normalTextures : Sampler2DArray;
		@param var pbrTextures : Sampler2DArray;
		@param var weightTextures : Sampler2DArray;
		@param var surfaceIndexMap : Sampler2D;
		@param var surfaceParams : Array<Vec4, SURFACE_COUNT>;
		@param var secondSurfaceParams : Array<Vec4, SURFACE_COUNT>;
		@param var tilePos : Vec2;
		@param var tileSize : Vec2;
		@param var sourceHeight : Sampler2D;
		@param var sourceNormal : Sampler2D;
		@param var heightBlendStrength : Float;
		@param var blendSharpness : Float;

		@param var source : Sampler2D;
		@param var from : Vec2;
		@param var to : Vec2;

		function vertex() {
			output.position = vec4(uvToScreen(mix(from, to, screenToUv(input.position))), 0, 1);
			output.position.y *= flipY;
		}

		function getsurfaceUV( id : Int, uv : Vec2 ) : Vec3 {
			var uv = tilePos + uv * tileSize;
			var angle = surfaceParams[id].w;
			var offset = vec2(surfaceParams[id].y, surfaceParams[id].z);
			var tilling = surfaceParams[id].x;
			var worldUV = uv * tilling + offset;
			var res = vec2( worldUV.x * cos(angle) - worldUV.y * sin(angle) , worldUV.y * cos(angle) + worldUV.x * sin(angle));
			var surfaceUV = vec3(res % 1, id);
			return surfaceUV;
		}

		function fragment() {
			var i = ivec3(surfaceIndexMap.get(calculatedUV).rgb * 255);
			var w = vec3(	weightTextures.get(vec3(calculatedUV, i.x)).r,
							weightTextures.get(vec3(calculatedUV, i.y)).r,
							weightTextures.get(vec3(calculatedUV, i.z)).r);
			var surfaceUV1 = getsurfaceUV(i.x, calculatedUV);
			var surfaceUV2 = getsurfaceUV(i.y, calculatedUV);
			var surfaceUV3 = getsurfaceUV(i.z, calculatedUV);

			var pbr1 = pbrTextures.get(surfaceUV1).rgba;
			var pbr2 = pbrTextures.get(surfaceUV2).rgba;
			var pbr3 = pbrTextures.get(surfaceUV3).rgba;
			// Height Blend
			var h = vec3( 	secondSurfaceParams[i.x].x + pbr1.a * (secondSurfaceParams[i.x].y - secondSurfaceParams[i.x].x),
							secondSurfaceParams[i.y].x + pbr2.a * (secondSurfaceParams[i.y].y - secondSurfaceParams[i.y].x),
							secondSurfaceParams[i.z].x + pbr3.a * (secondSurfaceParams[i.z].y - secondSurfaceParams[i.z].x));
			var h = mix(vec3(1,1,1), h, heightBlendStrength);
			w *= h;
			// Sharpness
			var ws = mix(w, w, blendSharpness);
			var m = max(w.x, max(w.y, w.z));
			var mw = vec3(0,0,0);
			if( m == w.x ) mw = vec3(1,0,0);
			if( m == w.y ) mw = vec3(0,1,0);
			if( m == w.z ) mw = vec3(0,0,1);
			w = mix(w, mw, blendSharpness);

			var terrainNormal = unpackNormal(texture(sourceNormal, calculatedUV).rgba);
			var bitangent = cross(vec3(1, 0, 0), terrainNormal);
			var tangent = cross(terrainNormal, bitangent);
			var TBN = mat3(	vec3(tangent.x, bitangent.x, terrainNormal.x),
							vec3(tangent.y, bitangent.y, terrainNormal.y),
							vec3(tangent.z, bitangent.z, terrainNormal.z));

			var wSum = w.x + w.y + w.z;
			var albedo = albedoTextures.get(surfaceUV1).rgb * w.x + albedoTextures.get(surfaceUV2).rgb * w.y + albedoTextures.get(surfaceUV3).rgb * w.z;
			albedo /= wSum;
			var normal = unpackNormal(normalTextures.get(surfaceUV1)) * w.x + unpackNormal(normalTextures.get(surfaceUV2)) * w.y +  unpackNormal(normalTextures.get(surfaceUV3)) * w.z;
			normal /= wSum;
			normal = packNormal(normal * TBN).rgb;
			var pbr = pbr1 * w.x + pbr2 * w.y + pbr3 * w.z;
			pbr /= wSum;

			albedoOutput = vec4(albedo,1);
			normalOutput = vec4(normal,1);
			pbrOutput = pbr;
		}
	}
}

private class CopyHeightNormalShader extends h3d.shader.ScreenShader {
	static var SRC = {

		@param var sourceHeight : Sampler2D;
		@param var sourceHeightSize : Vec2;
		@param var sourceNormal : Sampler2D;
		@param var from : Vec2;
		@param var to : Vec2;

		function vertex() {
			output.position = vec4(uvToScreen(mix(from, to, screenToUv(input.position))), 0, 1);
			output.position.y *= flipY;
		}

		function fragment() {
			pixelColor = vec4(sourceNormal.get(calculatedUV).rgb, sourceHeight.get(calculatedUV).r);
		}
	}
}

class TerrainMesh extends hrt.prefab.terrain.TerrainMesh {

	var pixelPerUnit = 4;
	public var albedoTexture : h3d.mat.Texture;
	public var normalHeightTexture : h3d.mat.Texture;
	public var fromTo = new h3d.Vector();

	public var terrainColorShaders : Array<TerrainColorNormalShader> = [];
	public var terrainBlendShaders : Array<TerrainBlend> = [];
	public var waterShaders : Array<prefab.Water.WaterShader> = [];

	public function new(?parent){
		super(parent);
	}

	override function onRemove() {
		super.onRemove();

		if( normalHeightTexture != null )
			normalHeightTexture.dispose();
		normalHeightTexture = null;

		if( albedoTexture != null )
			albedoTexture.dispose();
		albedoTexture = null;
	}

	function getAlbedoTexture() {
		if( albedoTexture == null )
			bake();
		return albedoTexture;
	}

	function getNormalHeightTexture() {
		if( normalHeightTexture == null )
			bake();
		return normalHeightTexture;
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
		// sending vec4(minX, minY, maxX, maxY)
		fromTo.set(minX, minY, maxX, maxY);
	}

	override function sync(ctx) {
		super.sync(ctx);
		updateBounds();

		var angle = -getRotationQuat().toMatrix().getEulerAngles().z;
		if (parent != null)
			angle -= parent.getRotationQuat().toMatrix().getEulerAngles().z;
		var cos = hxd.Math.cos(angle);
		var sin = hxd.Math.sin(angle);
		for( s in terrainColorShaders ) {
			s.normalHeightTexture = getNormalHeightTexture();
			s.albedoTexture = getAlbedoTexture();
			s.from.set(fromTo.x, fromTo.y);
			s.to.set(fromTo.z, fromTo.w);
			s.rotate.set(cos, sin);
			s.translate.set(-getAbsPos().getPosition().x, -getAbsPos().getPosition().y);
			s.invScale.set(1./scaleX, 1./scaleY);
		}

		for( s in terrainBlendShaders ) {
			s.normalHeightTexture = getNormalHeightTexture();
			s.from.set(fromTo.x, fromTo.y);
			s.to.set(fromTo.z, fromTo.w);
			s.rotate.set(cos, sin);
			s.translate.set(-getAbsPos().getPosition().x, -getAbsPos().getPosition().y);
			s.invScale.set(1./scaleX, 1./scaleY);
		}

		for( s in waterShaders ) {
			s.normalHeightTexture = getNormalHeightTexture();
			s.from.set(fromTo.x, fromTo.y);
			s.to.set(fromTo.z, fromTo.w);
			s.rotate.set(cos, sin);
			s.translate.set(-getAbsPos().getPosition().x, -getAbsPos().getPosition().y);
			s.invScale.set(1./scaleX, 1./scaleY);
		}
	}

	public function syncTerrainColorShader( s : TerrainColorNormalShader ) {
		terrainColorShaders.push(s);
	}

	public function syncTerrainAlphaBlendShader( s : TerrainBlend ) {
		terrainBlendShaders.push(s);
	}

	public function syncWaterShader( s : prefab.Water.WaterShader ) {
		waterShaders.push(s);
	}

	function bake() {

		if( albedoTexture != null )
			albedoTexture.dispose();

		if( normalHeightTexture != null )
			albedoTexture.dispose();

		var terrainBounds = new h3d.Vector();
		for( t in tiles ) {
			terrainBounds.x = hxd.Math.min(terrainBounds.x, t.tileX);
			terrainBounds.y = hxd.Math.max(terrainBounds.y, t.tileX + 1);
			terrainBounds.z = hxd.Math.min(terrainBounds.z, t.tileY);
			terrainBounds.w = hxd.Math.max(terrainBounds.w, t.tileY + 1);
		}

		var terrainWidth = Std.int(hxd.Math.abs(terrainBounds.x) + hxd.Math.abs(terrainBounds.y));
		var terrainHeight = Std.int(hxd.Math.abs(terrainBounds.z) + hxd.Math.abs(terrainBounds.w));

		var colorMapWidth = Std.int(terrainWidth * tileSize.x * pixelPerUnit);
		var colorMapHeight = Std.int(terrainHeight * tileSize.y * pixelPerUnit);
		albedoTexture = new h3d.mat.Texture(colorMapWidth, colorMapHeight, [Target]);

		var engine = h3d.Engine.getCurrent();
		var output = [Value("albedoOutput")];
		var ss = new h3d.pass.ScreenFx(new TerrainBakeShader(), output);
		ss.shader.SURFACE_COUNT = surfaceArray.surfaceCount;
		ss.shader.surfaceParams = surfaceArray.params;
		ss.shader.secondSurfaceParams = surfaceArray.secondParams;
		ss.shader.albedoTextures = surfaceArray.albedo;
		ss.shader.normalTextures = surfaceArray.normal;
		ss.shader.pbrTextures = surfaceArray.pbr;
		ss.shader.tileSize.set(tileSize.x, tileSize.y);
		ss.shader.heightBlendStrength = heightBlendStrength;
		ss.shader.blendSharpness = blendSharpness;
		engine.pushTargets([albedoTexture]);
		for( t in tiles ) {
			ss.shader.surfaceIndexMap = t.surfaceIndexMap;
			ss.shader.weightTextures = t.surfaceWeightArray;
			ss.shader.sourceHeight = t.heightMap;
			ss.shader.sourceNormal = t.normalMap;
			ss.shader.from.set(((t.tileX - terrainBounds.x) * (tileSize.x * pixelPerUnit)) / colorMapWidth, ((t.tileY - terrainBounds.z) * (tileSize.y * pixelPerUnit)) / colorMapHeight);
			ss.shader.to.set(ss.shader.from.x + (tileSize.x * pixelPerUnit) / colorMapWidth, ss.shader.from.y + (tileSize.y * pixelPerUnit) / colorMapHeight);
			ss.render();
		}
		engine.popTarget();

		var ratio = 1.0;
		var heightMapWidth = Std.int(terrainWidth * heightMapResolution.x * ratio);
		var heightMapHeight = Std.int(terrainHeight * heightMapResolution.y * ratio);
		var heightTileSize = new h2d.col.Point(heightMapResolution.x * ratio, heightMapResolution.y * ratio);
		normalHeightTexture = new h3d.mat.Texture(heightMapWidth, heightMapHeight, [Target], RGBA32F);
		var ss = new h3d.pass.ScreenFx(new CopyHeightNormalShader());
		engine.pushTarget(normalHeightTexture);
		for( t in tiles ) {
			ss.shader.sourceHeight = t.heightMap;
			ss.shader.sourceHeightSize.set(t.heightMap.width, t.heightMap.height);
			ss.shader.sourceNormal = t.normalMap;
			ss.shader.from.set(((t.tileX - terrainBounds.x) * heightTileSize.x) / heightMapWidth, ((t.tileY - terrainBounds.z) * heightTileSize.y) / heightMapHeight);
			ss.shader.to.set(ss.shader.from.x + heightTileSize.x / heightMapWidth, ss.shader.from.y + heightTileSize.y / heightMapHeight);
			ss.render();
		}
		engine.popTarget();
	}
}


