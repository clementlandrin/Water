package lib;

class CompatibilityPatcher {

	var game : Game;
	var regions : Array<st.Region> = [];

	public function new(game) {
		this.game = game;
		regions = game.state.getStates(st.Region);
	}

	public function patch() {

		// was added to meta because no recipe
		game.me.progress.learntMeta.remove(LayerUncoMovement);

		// was visible before release Corene, we could fight it then Corene script crash (roaming not found)
		if ( getVariableRegion(Gosenberg_1, "g1CoreneFreed") != true ) {
			respawnRoaming("G1ClemensHelpGroup");
			respawnElement(getRegionPlace(Gosenberg_1), "G1ClemensHelpLeader");
		}

		// old happy bonuses
		if( game.me.progress.learntMeta.remove(cast "Fellowship") )
			addItem(Knowledge);
		if( game.me.progress.learntMeta.remove(cast "Fellowshi") )
			addItem(Knowledge);

		@:privateAccess if( game.state.meteoManager.persist == None )
			game.state.meteoManager.persist = World;

	}

	public function patchAfter() {
		@:privateAccess if ( game.state.customMissions != null ) {
			game.state.customMissions.removeAll( mission -> {
				var dlg = mission.source.getDialog(mission.id, true);
				if ( dlg == null ) {
					var npc = game.allNpcs.get(mission.source.id);
					if ( npc != null ) {
						var oldInf = mission.source.inf;
						mission.source.inf = npc.inf;
						if ( mission.source.getDialog(mission.id, true) != null ) {
							return false;
						}
						mission.source.inf = oldInf;
					} else {
						return true;
					}
				}
				return false;
			});
		}
	}

	function addItem( it : Data.ItemKind, count = 1 ) {
		// adding items immediately crash because uninitialized "inf" !
		haxe.Timer.delay(function() {
			game.me.inventory.add(it, count);
		},0);
	}

	function respawnRoaming( id : String ) {
		if ( game != null && game.state != null && @:privateAccess game.state.removedRoamings != null )
			@:privateAccess game.state.removedRoamings.getValue().removeAll(r -> r == id);
	}

	function getRegionPlace( regionId : Data.RegionKind ) {
		for ( r in regions ) {
			if ( r.kind == regionId ) {
				return game.state.getPlace(cast st.Region.getPlacePrefix()+r.kind.toString());
			}
		}
		return null;
	}

	function respawnElement( place : ent.Place, id : String ) {
		if ( place == null || @:privateAccess place.removedIds == null )
			return;
		@:privateAccess place.removedIds.remove(id);
	}

	function getVariableGlobal( script : String, key : String ) {
		if ( game.state.scriptGlobals != null ) {
			var field = Reflect.field(game.state.scriptGlobals, script);
			if ( field != null )
				return Reflect.field(field, key);
		}
		return null;
	}

	function getVariableRegion( regionId : Data.RegionKind, key : String ) : Dynamic {
		for ( r in regions ) {
			if ( r.kind == regionId ) {
				if ( r.scriptGlobals != null ) {
					var field = Reflect.field(r.scriptGlobals, "globals");
					if ( field != null )
						return Reflect.field(field, key);
				}
				break;
			}
		}
		return null;
	}

	function forAllUnits( fct : (st.Unit) -> Void ) {
		forAllPlayerUnits(fct);
		if ( game.state != null ) {
			game.state.getStates(ent.p.Npc, n -> {
				@:privateAccess if ( n.unit != null ) {
					fct(n.unit);
				}
				return false;
			});
		}
	}

	function forAllPlayerUnits(  fct : (st.Unit) -> Void ) {
		if ( game.me != null && game.me.allUnits != null ) {
			for ( u in game.me.allUnits )
				fct(u);
		}
	}

}