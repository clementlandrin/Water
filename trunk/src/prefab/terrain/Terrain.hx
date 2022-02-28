package prefab.terrain;
using Lambda;

@:access(prefab.terrain.TerrainMesh)
class Terrain extends hrt.prefab.terrain.Terrain {

	override function createTerrain( ctx : hrt.prefab.Context ) {
		var t = new prefab.terrain.TerrainMesh(ctx.local3d);
		return t;
	}

	override function loadTiles( ctx : hrt.prefab.Context ) {
		super.loadTiles(ctx);
		var t : prefab.terrain.TerrainMesh = cast terrain;
		t.updateBounds();
	}

	static var _ = hrt.prefab.Library.register("terrain", Terrain);
}