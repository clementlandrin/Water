package prefab;

import hxsl.Output;

class TerrainAlphaBlend extends hrt.prefab.Shader {

	@:s public var range : Float = 0.25;
	@:s public var discardThreshold : Float = 0.25;
	#if editor
	public var DEBUG : Bool = false;
	#end

	static var terrainBlendShadowPass = new prefab.terrain.TerrainMesh.TerrainBlendShadowPass();

	override function makeInstance( ctx : hrt.prefab.Context ) : hrt.prefab.Context {
		var ctx = super.makeInstance(ctx);

		for( m in ctx.local3d.getMaterials() ) {
			m.mainPass.setBlendMode(Alpha);
		}

		return ctx;
	}

	override function makeShader( ?ctx : hrt.prefab.Context ) : hxsl.Shader {
		var t = cast ctx.local3d.getScene().find( o -> Std.isOfType(o, prefab.terrain.TerrainMesh) ? o : null);
		if( t != null ) {
			var terrain  : prefab.terrain.TerrainMesh = cast t;
			var s = new prefab.terrain.TerrainMesh.TerrainBlend();
			terrain.syncTerrainAlphaBlendShader(s);
			return s;
		}
		return  new prefab.terrain.TerrainMesh.TerrainBlend();
	}

	override function applyShader( obj : h3d.scene.Object, material : h3d.mat.Material, shader : hxsl.Shader ) {
		super.applyShader(obj, material, shader);
		var sh = material.getPass("shadow");
		if( sh != null ) sh.addShader(terrainBlendShadowPass);
	}

	override function syncShaderVars( shader : hxsl.Shader, shaderDef : hxsl.SharedShader ) {
		super.syncShaderVars(shader, shaderDef);
		var s : prefab.terrain.TerrainMesh.TerrainBlend = cast shader;
		s.range = range;
		#if editor
		s.DEBUG = DEBUG;
		#end
	}

	#if editor

	override function getHideProps() : hide.prefab.HideProps {
		return { icon : "cog", name : "TerrainAlphaBlend", allowParent : function(p) return p.to(hrt.prefab.Object2D) != null || p.to(hrt.prefab.Object3D) != null || p.to(hrt.prefab.Material) != null  };
	}

	override function edit( ctx : hide.prefab.EditContext ) {
		//super.edit(ctx);

		var group = new hide.Element('
			<div class="group" name="Terrain Alpha Blend">
				<dl>
					<dt>Range</dt><dd><input type="range" min="0" max="1" field="range"/></dd>
				</dl>
			</div>
			<div class="group" name="Debug">
				<dl>
					<dt>Debug</dt><dd><input type="checkbox" field="DEBUG"/></dd>
				</dl>
			</div>
		');

		var props = ctx.properties.add(group, this, function(pname) {
			ctx.onChange(this, pname);
		});
	}

	#end

	static var _ = hrt.prefab.Library.register("terrainAlphaBlend", TerrainAlphaBlend);

}