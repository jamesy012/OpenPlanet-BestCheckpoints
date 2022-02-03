/*
 * author: Phlarx + JackNytely
 */

namespace CP {
	/**
	 * If true, then this plugin has detected that we are in game, on a map.
	 * If false, none of the other values are valid.
	 */
	bool inGame = false;
	
	/**
	 * If false, then at least one checkpoint tag is a non-standard value.
	 * Only applies to NEXT and MP4.
	 */
	bool strictMode = false;
	
	/**
	 * The ID of the map whose checkpoints have been counted.
	 */
	string curMapId = "";
	
	/**
	 * The number of checkpoints completed in the current lap.
	 */
	uint curCP = 0;
	
	/**
	 * The number of checkpoints detected for the current map.
	 */
	uint maxCP = 0;
	
	/**
	 * Internal values.
	 */
	uint preCPIdx = 0;

	/**
	* Define whether the User has Restarted or Started a New Run on a Map
	*/
	bool NewStart = true;

	/**
	* Define the Time the User Started their Run at
	*/
	int startTime = 0;

	/**
	* Get the Author Time for the Current map
	*/
	int mapAuthorTime = 0;
	
	/**
	 * Update should be called once per tick, within the plugin's Update(dt) function.
	 */

	void Update() {

		/**
		* Intialize the Playground, MedalAPP and Map Objects
		*/
		auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
		auto medalApp = cast<CTrackMania>(GetApp());
		auto map = medalApp.RootMap;
		
		/**
		* Check if the Player is currently in a Match
		*/
		if(playground is null
			|| playground.Arena is null
			|| playground.Map is null
			|| playground.GameTerminals.Length <= 0
			|| playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing
			|| cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer) is null) {
			inGame = false;
			return;
		}
		
		/**
		* Intialize the Player and Script Player
		*/
		auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
		auto scriptPlayer = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer).ScriptAPI;

		/**
		* Check if the ScriptPlayer Exists
		*/
		if(scriptPlayer is null) {
			inGame = false;
			return;
		}

		/**
		* Check if the Player started a New Run
		*/
		if(NewStart == false && curCP < 1 && player.StartTime != startTime) {
			NewStart = true;

			startTime = player.StartTime;
		}

		/**
		* Get the Current Author time for Specified Map
		*/
		mapAuthorTime = map.TMObjective_AuthorTime;
		
		/**
		* Check if the User wants the Timer Hidden with the Current Interface and Hide the Timer if Interface is Hidden
		*/
		if(hideTimerWithInterface) {
			if(playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
				inGame = false;
				return;
			}
		}
		
		/**
		* Check if the Player is Currently Spectating
		*/
		if(player.CurrentLaunchedRespawnLandmarkIndex == uint(-1)) {
			inGame = false;
			return;
		}
		
		MwFastBuffer<CGameScriptMapLandmark@> landmarks = playground.Arena.MapLandmarks;
		
		if(!inGame && (curMapId != playground.Map.IdName || GetApp().Editor !is null)) {
			// keep the previously-determined CP data, unless in the map editor
			curMapId = playground.Map.IdName;
			preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
			curCP = 0;
			maxCP = 0;
			strictMode = true;
			
			array<int> links = {};
			for(uint i = 0; i < landmarks.Length; i++) {
				if(landmarks[i].Waypoint !is null && !landmarks[i].Waypoint.IsFinish && !landmarks[i].Waypoint.IsMultiLap) {
					// we have a CP, but we don't know if it is Linked or not
					if(landmarks[i].Tag == "Checkpoint") {
						maxCP++;
					} else if(landmarks[i].Tag == "LinkedCheckpoint") {
						if(links.Find(landmarks[i].Order) < 0) {
							maxCP++;
							links.InsertLast(landmarks[i].Order);
						}
					} else {
						// this waypoint looks like a CP, acts like a CP, but is not called a CP.
						maxCP++;
						strictMode = false;
					}
				}
			}
		}
		inGame = true;
		
		/**
		* Check if the Player is at the Start Block to reset the CP Counter
		*/
		if(preCPIdx != player.CurrentLaunchedRespawnLandmarkIndex && landmarks.Length > player.CurrentLaunchedRespawnLandmarkIndex) {
			preCPIdx = player.CurrentLaunchedRespawnLandmarkIndex;
			
			if(landmarks[preCPIdx].Waypoint is null || landmarks[preCPIdx].Waypoint.IsFinish || landmarks[preCPIdx].Waypoint.IsMultiLap) {
				// if null, it's a start block. if the other flags, it's either a multilap or a finish.
				// in all such cases, we reset the completed cp count to zero.
				curCP = 0;
			} else {
				curCP++;
			}
		}
	}
}