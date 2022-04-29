// openplanet doesnt like comments on same line as #if statement?
// just here for visual studio code intellisense help
#if __INTELLISENSE__
#include "Settings.as"
#include "cppIntellisense.h"
#endif

// timing
int lastCpTime = 0;
// last waypoint cp id
int lastCP = 0;
int currentLap = 0;
// incrementing cp
int currCP = 0;

int finishRaceTime = 0;
int finishRealTime = 0;

// map data
int numCps = 0;
string currentMap;
int numLaps = 0;

class Record {
  int checkpointId = -1;
  int time;
  int speed;

  Record(int checkpointId, int time, int speed) {
    this.checkpointId = checkpointId;
    this.time = time;
    this.speed = speed;
  }

  Record @opAssign(const Record& in record) {
    checkpointId = record.checkpointId;
    time = record.time;
    speed = record.speed;
    return this;
  }
}

// storage
// this Race Best times
Record @[] currTimesRec;
// overall best times
Record @[] bestTimesRec;
// personal best times (times for the personal best score)
Record @[] pbTimesRec;
int pbTime;

// storage of which checkpoint we have been through
Record @[] currLapTimesRec;
Record @[] lastLapTimesRec;

// extra
bool waitForCarReset = true;
bool resetData = true;
int playerStartTime = -1;
bool firstLoad = false;
bool isMultiLap = false;
bool isFinished = false;

// font
string loadedFontFace = "";
int loadedFontSize = 0;
Resources::Font @font = null;

// file io
string jsonFile = '';
Json::Value jsonData = Json::Object();
string jsonVersion = "1.4";

// ui timing
int lastEstimatedTime = 0;
bool isRenderingCurrentCheckpoint = false;

// turbo extra's
bool hasFinishedMap = false;
int turboCheckpointCounter = 0;
uint lastCurrCheckpointRaceTime = uint(-1);

void DebugText(string text) {
  if (enableLogging) {
    print(text);
  }
}

void Main() {
  LoadFont();
  // waitForCarReset = GetCurrentCheckpoint()!= 0;
  playerStartTime = GetPlayerStartTime();
  // currentMap = GetMapId();
}

void OnDestroyed() { UpdateSaveBestData(); }

// clears data, waits till a reset to start happens
void ResetCommon() {
  waitForCarReset = true;
  ResetRace();
  bestTimesRec = {};
  pbTimesRec = {};
  pbTime = 0;
  jsonData = Json::Object();

  hasFinishedMap = false;

#if TURBO || MP4
  // map load will set this or we count as we checkpoint
  numCps = 0;
#endif
}

void ResetRace() {
  currTimesRec = {};
  currLapTimesRec = {};
  lastLapTimesRec = {};
  isFinished = false;
  lastCpTime = 0;
  currentLap = 0;
  currCP = 0;
  finishRaceTime = 0;
  finishRealTime = 0;

#if TMNEXT
  lastCP = GetSpawnCheckpoint();
#elif TURBO || MP4
  turboCheckpointCounter = 0;
  lastCurrCheckpointRaceTime = uint(-1);
#endif
}

void Update(float dt) {
  // have we changed map?
  if (currentMap != GetMapId()) {
    DebugText("map mismatch");

    // we have left the map, lets save our data before we lose it
    if (currentMap != "") {
      UpdateSaveBestData();
    }

    // reset file names
    jsonFile = "";
    currentMap = "";

    // reset important variables
    ResetCommon();

    // check for a valid map
    if (currentMap == "" || GetMapId() == "") {
      DebugText("map found - " + GetMapName());
      // waitForCarReset = false;
      playerStartTime = GetPlayerStartTime();

      currentMap = GetMapId();

      LoadFile();

      UpdateWaypoints();
    }
  }
  // wait for the car to be back at starting checkpoint
  if (waitForCarReset) {
#if TMNEXT
    // when waiting for a reset, Player race time ends up at a - value for the
    // countdown before starting the lap
    waitForCarReset = GetCurrentPlayerRaceTime() >= 0;
#elif TURBO || MP4
    waitForCarReset = IsPlayerReady();
#endif
    return;
  }

  // wait for car to be driveable to do our final reset
  if (resetData) {
    if (IsPlayerReady()) {
      DebugText("Running reset");
      resetData = false;
      UpdateSaveBestData();

      ResetRace();

      playerStartTime = GetActualPlayerStartTime();

      if (numCps <= 1) {
        UpdateWaypoints();
      }

      DebugText("Ready to read checkpoints");
    }
    return;
  } else {
    // if our car no longer became valid? reset?
    if (!IsPlayerReady()) {
      DebugText("Car no longer valid..");
      resetData = true;

      // turbo/MP4 needs to go through one more time
#if !TURBO && !MP4
      return;
#endif
    }
  }

#if TURBO || MP4
  // turbo doesnt store current checkpoint?
  UpdateCheckpointCounter();
#endif

  int cp = GetCurrentCheckpoint();
#if TURBO || MP4
  cp -= (currentLap * (numCps));
#endif

  // have we changed checkpoint?
  if (cp != lastCP) {
    DebugText("- Checkpoint change " + lastCP + "/" + cp);

    lastCP = cp;

    int raceTime = GetPlayerCheckpointTime();

    int deltaTime = raceTime - lastCpTime;

    DebugText("Delta time: " + deltaTime);
    DebugText("Race time: " + raceTime);

    lastCpTime = raceTime;

    if (raceTime <= 0 || deltaTime <= 0) {
      DebugText("Checkpoint time negative..");
      // not sure if this is necessary anymore?
#if TMNEXT
      waitForCarReset = true;
#elif TURBO || MP4
      ResetRace();
#endif
      return;
    }

    // add our time (best current time for run)
    CreateOrUpdateCurrentTime(cp, deltaTime, GetPlayerSpeed());

#if TURBO || MP4
    DebugText(cp + " > " + numCps);
    if (hasFinishedMap == false && cp > numCps) {
      numCps++;  // turbo Temp
      DebugText("adding CP");
    }
#endif

    DebugText("NumCps:" + int(currLapTimesRec.Length) + "/" + numCps);
    // update our best times, different logic for multilap
    //   if (int(currLapTimesRec.Length) == numCps)
    //   // turbo/mp4 hack, needs this for multilap to function?
    // if TURBO || MP4
    //       && currentLap == 0)
    // endif
    //   {
    //     print("normal update");
    //         CreateOrUpdateBestTime(cp, currLapTimesRec[currCP].time,
    //                                currLapTimesRec[currCP].speed);
    //       }
    //   else {
    //     print("other update");
    //     print(int(bestTimesRec.Length) +"/"+ numCps);
    if (int(bestTimesRec.Length) < numCps || isMultiLap) {
      CreateOrUpdateBestTime(cp, deltaTime, GetPlayerSpeed());
    }
    //   }

    // update time for laps
    CreateOrUpdateCurrentLapTime(cp, deltaTime, GetPlayerSpeed());

    currCP++;

    // check for finish
#if TMNEXT
    if (IsWaypointFinish(cp)) {
#elif TURBO || MP4
    DebugText("Laps: " + GetPlayerLap() + " - " + currentLap);
    if (IsPlayerFinished() || GetPlayerLap() != currentLap) {
      DebugText("Finish lap");
      // turboCheckpointCounter = 0;
      lastCP = 0;
#endif
      hasFinishedMap = true;
      currentLap++;
      if (isMultiLap) {
        DebugText("Lap finish: " + currentLap + "/" + numLaps);
      }

#if TMNEXT
      if (!isMultiLap || currentLap == numLaps || !multiLapOverride) {
#elif TURBO || MP4
      if (IsPlayerFinished()) {
#endif
        DebugText("Race Finished");

        waitForCarReset = true;
        resetData = true;
        isFinished = true;
        finishRaceTime = raceTime;
        finishRealTime = Time::get_Now();
        if (pbTime == 0) {
          UpdatePersonalBestTimes();
        }
      } else {
        // not finished, reset currCP
        currCP = 0;
      }
    }
  }
}

void CreateOrUpdateCurrentTime(int checkpoint, int time, int speed) {
  int recIndex = -1;
  for (uint i = 0; i < currTimesRec.Length; i++) {
    if (currTimesRec[i].checkpointId == checkpoint) {
      recIndex = int(i);
      break;
    }
  }

  if (recIndex == -1) {
    Record rec(checkpoint, time, speed);
    currTimesRec.InsertLast(rec);
  } else {
    if (currTimesRec[recIndex].time > time) {
      currTimesRec[recIndex].time = time;
    }
    if (currTimesRec[recIndex].speed < speed) {
      currTimesRec[recIndex].speed = speed;
    }
  }
}

void CreateOrUpdateBestTime(int checkpoint, int time, int speed) {
  int recIndex = -1;
  for (uint i = 0; i < bestTimesRec.Length; i++) {
    if (bestTimesRec[i].checkpointId == checkpoint) {
      recIndex = int(i);
      break;
    }
  }

  if (recIndex == -1) {
    Record rec(checkpoint, time, speed);
    bestTimesRec.InsertLast(rec);
  } else {
    if (bestTimesRec[recIndex].time > time) {
      bestTimesRec[recIndex].time = time;
    }
    if (bestTimesRec[recIndex].speed < speed) {
      bestTimesRec[recIndex].speed = speed;
    }
  }
}

// todo replace paramaters with Record reference
void CreateOrUpdatePBTime(int checkpoint, int time, int speed) {
  int recIndex = -1;
  for (uint i = 0; i < pbTimesRec.Length; i++) {
    if (pbTimesRec[i].checkpointId == checkpoint) {
      recIndex = int(i);
      break;
    }
  }

  if (recIndex == -1) {
    Record rec(checkpoint, time, speed);
    pbTimesRec.InsertLast(rec);
  } else {
    // if (pbTimesRec[recIndex].time > time) {
    pbTimesRec[recIndex].time = time;
    pbTimesRec[recIndex].speed = speed;
    //}
  }
}

void CreateOrUpdateCurrentLapTime(int checkpoint, int time, int speed) {
  int recIndex = -1;
  for (uint i = 0; i < currLapTimesRec.Length; i++) {
    if (currLapTimesRec[i].checkpointId == checkpoint) {
      recIndex = int(i);
      break;
    }
  }

  if (recIndex == -1) {
    Record rec(checkpoint, time, speed);
    currLapTimesRec.InsertLast(rec);
    lastLapTimesRec.InsertLast(Record(checkpoint, -1, -1));
  } else {
    lastLapTimesRec[recIndex].time = currLapTimesRec[recIndex].time;
    lastLapTimesRec[recIndex].speed = currLapTimesRec[recIndex].speed;
    currLapTimesRec[recIndex].time = time;
    currLapTimesRec[recIndex].speed = speed;
  }
}

void UpdatePersonalBestTimes() {
  if (isFinished && finishRaceTime != 0 &&
      (finishRaceTime < pbTime || pbTime == 0)) {
    pbTime = finishRaceTime;
    for (uint i = 0; i < currTimesRec.Length; i++) {
      CreateOrUpdatePBTime(currTimesRec[i].checkpointId, currTimesRec[i].time,
                           currTimesRec[i].speed);
    }
    // Final checkpoint is finish, can have multiple finish checkpoints, so this
    // overides that
    pbTimesRec[currTimesRec.Length - 1] = currTimesRec[currTimesRec.Length - 1];
  }
}

void UpdateSaveBestData() {
  bool save = true;

  // if (saveWhenCompleted) {
  //     save = int(currTimesRec.Length) == numCps;
  //     if(save && isMultiLap){
  //         save = currentLap == numLaps;
  //     }
  //     if(save && isMultiLap){
  //         save = currentLap == numLaps;
  //     }
  // }
  if (saveWhenCompleted && !isFinished) {
    save = false;
  }
  DebugText("saving times? " + save);

  if (save) {
    // update our best times
    for (uint i = 0; i < currTimesRec.Length; i++) {
      if (currTimesRec[i].time < bestTimesRec[i].time) {
        bestTimesRec[i].time = currTimesRec[i].time;
      }
      if (currTimesRec[i].speed > bestTimesRec[i].speed) {
        bestTimesRec[i].speed = currTimesRec[i].speed;
      }
    }

    UpdatePersonalBestTimes();

    SaveFile();
  }
}

int GetLowestTime(uint checkpoint) {
  if (bestTimesRec.Length > checkpoint && currTimesRec.Length > checkpoint) {
    if (bestTimesRec[checkpoint].time > currTimesRec[checkpoint].time) {
      return currTimesRec[checkpoint].time;
    } else {
      return bestTimesRec[checkpoint].time;
    }
  } else {
    if (bestTimesRec.Length > checkpoint) {
      return bestTimesRec[checkpoint].time;
    }
    if (currTimesRec.Length > checkpoint) {
      return currTimesRec[checkpoint].time;
    }
  }
  return -1;
}

#if TMNEXT
CSmArenaClient @GetPlayground() {
  CSmArenaClient @playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
  return playground;
}
#elif TURBO || MP4
CTrackManiaRaceNew @GetPlayground() {
  CTrackManiaRaceNew @playground =
      cast<CTrackManiaRaceNew>(GetApp().CurrentPlayground);
  return playground;
}
#endif

CSmArenaRulesMode @GetPlaygroundScript() {
  CSmArenaRulesMode @playground =
      cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
  return playground;
}

int GetCurrentGameTime() {
  auto playground = GetPlayground();
  if (playground is null || playground.Interface is null ||
      playground.Interface.ManialinkScriptHandler is null) {
    return -1;
  }
  // CSmArenaInterfaceManialinkScripHandler@ aimsh =
  // cast<CSmArenaInterfaceManialinkScripHandler>(playground.Interface.ManialinkScriptHandler
  // ); return aimsh.ArenaNow;
  return playground.Interface.ManialinkScriptHandler.GameTime;
}

#if TMNEXT
CSmPlayer @GetPlayer() {
  auto playground = GetPlayground();
  if (playground is null || playground.GameTerminals.Length != 1) {
    return null;
  }

  return cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
}
#elif TURBO || MP4
CTrackManiaPlayer @GetPlayer() {
  auto playground = GetPlayground();
  if (playground is null || playground.GameTerminals.Length != 1) {
    return null;
  }
  return cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);
}
#endif

#if TURBO || MP4
bool IsPlayerReady() {
  CTrackManiaPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return false;
  }
  return smPlayer.RaceState == CTrackManiaPlayer::ERaceState::Running;
}
#else
CSmScriptPlayer @GetPlayerScript() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return null;
  }
  return cast<CSmScriptPlayer>(smPlayer.ScriptAPI);
}

bool IsPlayerReady() {
  CSmScriptPlayer @smPlayerScript = GetPlayerScript();
  if (smPlayerScript is null) {
    return false;
  }
  return GetCurrentPlayerRaceTime() >= 0 &&
         smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver &&
         GetSpawnCheckpoint() != -1;
}
#endif

// current time for race
// not accurate for ui
int GetCurrentPlayerRaceTime() {
  return GetCurrentGameTime() - GetPlayerStartTime();
}

// chooses between GetUICheckpointTime or GetCurrentPlayerRaceTime
// called directly after a checkpoint changed
int GetPlayerCheckpointTime() {
#if TMNEXT
  int raceTime;
  int estRaceTime = GetCurrentPlayerRaceTime();
  int uiRaceTime = GetUICheckpointTime();
  if (uiRaceTime == -1) {
    raceTime = estRaceTime;
  } else {
    raceTime = uiRaceTime;
  }
  // print("ui: " + Time::Format(uiRaceTime) + " - norm: " +
  // Time::Format(raceTime));
  return raceTime;
#elif TURBO || MP4
  CTrackManiaPlayer @smPlayer = GetPlayer();
  return smPlayer.CurCheckpointRaceTime;
#endif
}

int GetPlayerSpeed() {
#if TMNEXT
  CSmScriptPlayer @smPlayerScript = GetPlayerScript();
  return smPlayerScript.DisplaySpeed;
#else
  CTrackManiaPlayer @smPlayer = GetPlayer();
  return smPlayer.DisplaySpeed;
#endif
}

#if TMNEXT
int GetPlayerStartTime() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.StartTime;
}
#elif TURBO || MP4
int GetPlayerStartTime() {
  CTrackManiaPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }

#if MP4
  return smPlayer.ScriptAPI.RaceStartTime;
#else
  return smPlayer.RaceStartTime;
#endif
}
#endif

int GetActualPlayerStartTime() {
  return GetPlayerStartTime() - GetCurrentPlayerRaceTime();
}

#if TMNEXT
int GetUICheckpointTime() {
  CGameCtnNetwork @network = GetApp().Network;
  if (network is null) {
    return -1;
  }
  CGameManiaAppPlayground @appPlayground = network.ClientManiaAppPlayground;
  if (appPlayground is null) {
    return -1;
  }

  // search? instead of hardcode?
  CGameUILayer @raceUILayer = appPlayground.UILayers[8];
  if (raceUILayer is null) {
    return -1;
  }
  CGameManialinkPage @linkPage = raceUILayer.LocalPage;
  if (linkPage is null) {
    return -1;
  }
  CGameManialinkControl @race_Checkpoint = linkPage.GetClassChildren_Result[0];
  if (race_Checkpoint is null ||
      race_Checkpoint.ControlId != "Race_Checkpoint") {  // validation
    return -1;
  }
  CGameManialinkControl @frame_checkpoint =
      cast<CGameManialinkFrame>(race_Checkpoint).Controls[0];
  if (frame_checkpoint is null) {
    return -1;
  }
  CGameManialinkControl @frame_race =
      cast<CGameManialinkFrame>(frame_checkpoint).Controls[0];
  if (frame_race is null) {
    return -1;
  }
  CGameManialinkControl @frame_race_time =
      cast<CGameManialinkFrame>(frame_race).Controls[0];
  if (frame_race_time is null ||
      cast<CGameManialinkFrame>(frame_race_time).Controls.Length != 2) {
    return -1;
  }
  CGameManialinkControl @label_race_time_ctrl =
      cast<CGameManialinkFrame>(frame_race_time).Controls[1];
  if (label_race_time_ctrl is null) {
    return -1;
  }
  CGameManialinkLabel @label_race_time =
      cast<CGameManialinkLabel>(label_race_time_ctrl);
  if (label_race_time is null) {
    return -1;
  }
  // print(label_race_time.Value);

  return ConvertStringToTime(label_race_time.Value);
}
#endif

int ConvertStringToTime(string input) {
  string[] seconds = SplitString(input, ":");
  if (seconds.Length != 2) {
    return -1;
  }
  string[] microSecond = SplitString(seconds[1], ".");
  if (microSecond.Length != 2) {
    return -1;
  }
  int micro = Text::ParseInt(microSecond[1]);
  int second = Text::ParseInt(microSecond[0]);
  int minute = Text::ParseInt(seconds[0]);
  second *= 1000;
  minute *= 1000 * 60;
  int result = micro + second + minute;
  // print(Time::Format(1000));
  // print(Time::Format(result));
  return result;
}

// splits strings, removes split character
string[] SplitString(string input, string split) {
  // how to just pass a char??
  string current = "";
  string[] output;
  for (int i = 0; i < input.Length; i++) {
    if (input[i] == split[0]) {
      output.InsertLast(current);
      current = "";
    } else {
      // how to do just add a char?
      current += " ";
      current[current.Length - 1] = input[i];
    }
  }
  output.InsertLast(current);
  return output;
}

int GetCurrentCheckpoint() {
#if TMNEXT
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
#else
  return turboCheckpointCounter;
#endif
}

string GetMapName() {
#if TMNEXT || MP4
  if (GetApp().RootMap is null) {
    return "";
  }
  return GetApp().RootMap.MapName;
#elif TURBO
  auto map = GetApp().Challenge;
  if (map is null) {
    return "";
  }
  return map.MapInfo.NameForUi;
#endif
}

string GetMapId() {
#if TMNEXT || MP4
  if (GetApp().RootMap is null) {
    return "";
  }
  return GetApp().RootMap.IdName;
#elif TURBO
  auto map = GetApp().Challenge;
  if (map is null) {
    return "";
  }
  return map.MapInfo.MapUid;
#endif
}

#if TMNEXT
bool IsWaypointFinish(int index) {
  if (index == -1) {
    return false;
  }
  auto playground = GetPlayground();
  if (playground is null) {
    return false;
  }
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  if (index >= int(landmarks.Length)) {
    return false;
  }
  return landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish
                                            : false;
}

bool IsWaypointStart(int index) { return GetSpawnCheckpoint() == index; }

bool IsWaypointValid(int index) {
  if (index == -1) {
    return false;
  }
  auto playground = GetPlayground();
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  if (index >= int(landmarks.Length)) {
    return false;
  }
  bool valid = false;
  // valid |= (landmarks[index].Waypoint != null ?
  // landmarks[index].Waypoint.IsFinish : false); valid |= (landmarks[index].Tag
  // == "Checkpoint");
  if (landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish
                                         : false)
    valid = true;
  if ((landmarks[index].Tag == "Checkpoint")) valid = true;
  return valid;
}

int GetSpawnCheckpoint() {
  CSmPlayer @smPlayer = GetPlayer();
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.SpawnIndex;
}
#endif

void UpdateWaypoints() {
  // turbo gets from save file/during a run
#if TMNEXT
  numCps = 1;  // one for finish
#endif
  numLaps = 1;
  isMultiLap = false;

  array<int> links = {};
  bool strictMode = true;

#if TMNEXT
  auto playground = GetPlayground();
  if (playground is null || playground.Arena is null ||
      playground.Arena.Rules is null) {
    DebugText("map not ready for waypoint read?");
    return;
  }

  auto map = playground.Map;
#elif MP4
  auto map = GetApp().RootMap;
#elif TURBO
  auto map = GetApp().Challenge;
  if (map is null) {
    return;
  }
#endif
  numLaps = map.TMObjective_NbLaps;
  isMultiLap = map.TMObjective_IsLapRace;
  DebugText("Map Laps: " + numLaps + " Is MultiLap: " + isMultiLap);
#if TMNEXT
  MwFastBuffer<CGameScriptMapLandmark @> landmarks =
      playground.Arena.MapLandmarks;
  for (uint i = 0; i < landmarks.Length; i++) {
    if (landmarks[i].Waypoint is null) {
      continue;
    }
    if (landmarks[i].Waypoint.IsMultiLap) {
      // isMultiLap = true;
      continue;
    }
    if (landmarks[i].Waypoint.IsFinish) {
      // numCps++;
      continue;
    }
    // if(landmarks[i].Tag == "Spawn"){
    // }
    //  we have a CP, but we don't know if it is Linked or not
    if (landmarks[i].Tag == "Checkpoint") {
      numCps++;
    } else if (landmarks[i].Tag == "LinkedCheckpoint") {
      if (links.Find(landmarks[i].Order) < 0) {
        numCps++;
        links.InsertLast(landmarks[i].Order);
      }
    } else {
      // this waypoint looks like a CP, acts like a CP, but is not called a CP.
      if (strictMode) {
        warn("The current map, " + string(playground.Map.MapName) + " (" +
             playground.Map.IdName +
             "), is not compliant with checkpoint naming rules.");
      }
      numCps++;
      strictMode = false;
    }
  }

  if (isMultiLap && numLaps == 1) {
    numCps -= 1;
    isMultiLap = false;
  }

  hasFinishedMap = true;
#endif
}

#if TURBO || MP4
void UpdateCheckpointCounter() {
  CTrackManiaPlayer @smPlayer = cast<CTrackManiaPlayer>(GetPlayer());
  if (smPlayer is null) {
    return;
  }
  if (smPlayer.CurCheckpointRaceTime != lastCurrCheckpointRaceTime) {
    turboCheckpointCounter++;
    lastCurrCheckpointRaceTime = smPlayer.CurCheckpointRaceTime;
  }
}

bool IsPlayerFinished() {
  CTrackManiaPlayer @smPlayer = cast<CTrackManiaPlayer>(GetPlayer());
  if (smPlayer is null) {
    return false;
  }
  return smPlayer.RaceState == CTrackManiaPlayer::ERaceState::Finished;
}

int GetPlayerLap() {
  CTrackManiaPlayer @smPlayer = cast<CTrackManiaPlayer>(GetPlayer());
  if (smPlayer is null) {
    return -1;
  }
  return smPlayer.CurrentNbLaps;
}

#endif

int CalulateEstimatedTime() {
  Record @[] estCompTimes;

  if (estimatedTimeUseOptimal) {
    estCompTimes = bestTimesRec;
  } else {
    estCompTimes = pbTimesRec;
  }

  if (int(estCompTimes.Length) != numCps) {
    return 0;
  }
  int currentFinishTime = 0;
  int currentLapTime = 0;
  for (int i = 0; i < int(estCompTimes.Length); i++) {
    if (currCP > i) {
      currentFinishTime += currLapTimesRec[i].time;
      currentLapTime += currLapTimesRec[i].time;
    } else {
      currentFinishTime += estCompTimes[i].time;
    }
  }

  // problem here in multiplayer matched when they end the cars timer keeps
  // going up
  if (updatingEstimatedTime && int(estCompTimes.Length) > currCP &&
      !isFinished && !waitForCarReset && GetCurrentPlayerRaceTime() > 0) {
    currentLapTime += estCompTimes[currCP].time;
    if (currentLapTime < GetCurrentPlayerRaceTime()) {
      int different = GetCurrentPlayerRaceTime() - currentLapTime;
      currentFinishTime += different;
    }
  }

  return currentFinishTime;
}

// file io
void LoadFile() {
  if (currentMap == "") {
    return;
  }

  string baseFolder = IO::FromDataFolder('');
  string folder = baseFolder + 'BestCP';
  if (!IO::FolderExists(folder)) {
    IO::CreateFolder(folder);
    DebugText("Created folder: " + folder);
  }

  jsonFile = folder + '/' + currentMap + ".json";

  firstLoad = !IO::FileExists(jsonFile);

  DebugText("Loading - " + jsonFile + " newFile?" + firstLoad);

  if (firstLoad) {
    // file doesnt exist, dont load
    return;
  }

  IO::File f(jsonFile);
  f.Open(IO::FileMode::Read);
  auto content = f.ReadToEnd();
  f.Close();
  if (content == "" || content == "null") {
    DebugText("Invalid bestCPs file detected");
    jsonData = Json::Object();
  } else {
    jsonData = Json::FromFile(jsonFile);
  }

  if (jsonData.HasKey("version") && jsonData.HasKey("size")) {
    string version = jsonData["version"];
    float versionFloat = Text::ParseFloat(version);
    if (version >= "1.1") {
      numCps = jsonData["size"];
      if (versionFloat >= 1.2) {
        pbTime = jsonData["pb"];
      }
      if (versionFloat >= 1.3) {
        hasFinishedMap = jsonData["finished"];
        DebugText("loaded finished map " + hasFinishedMap);
      } else {
        hasFinishedMap = pbTime > 1;
      }
      for (int i = 0; i < numCps; i++) {
        string key = "" + i;
        if (jsonData.HasKey(key)) {
          if (version == "1.0") {
            // 1.0 stored in seperate data, with no checkpoint index
            CreateOrUpdateBestTime(-1, jsonData[key], -1);
          } else {  // current
            int speed = -1;
            int pbSpeed = -1;
            if (versionFloat >= 1.4) {
              speed = jsonData[key]["speed"];
              pbSpeed = jsonData[key]["pbSpeed"];
            }
            CreateOrUpdateBestTime(jsonData[key]["cp"], jsonData[key]["time"],
                                   speed);
            if (versionFloat >= 1.2) {
              CreateOrUpdatePBTime(jsonData[key]["cp"], jsonData[key]["pbTime"],
                                   pbSpeed);
            }
          }
        } else {
          DebugText("json missing key " + i);
        }
        if (bestTimesRec[i].checkpointId == -1) {
          DebugText("-1 checkpoint id, invalid file");
          ResetCommon();
          return;
        }
      }
    }
  } else {
    DebugText("invalid json file");
  }
}

void SaveFile() {
  firstLoad = false;

  if (jsonFile == "") {
    return;
  }

  if (saveData == false) {
    return;
  }

  // quick validation
  if (currTimesRec.Length == bestTimesRec.Length &&
      bestTimesRec.Length == pbTimesRec.Length) {
    DebugText("Validation before save");
    for (uint i = 0; i < currTimesRec.Length; i++) {
      bestTimesRec[i].checkpointId = currTimesRec[i].checkpointId;
      pbTimesRec[i].checkpointId = currTimesRec[i].checkpointId;
    }
  }

  jsonData = Json::Object();

  jsonData["version"] = jsonVersion;

  jsonData["size"] = bestTimesRec.Length;
  jsonData["pb"] = pbTime;
  jsonData["finished"] = hasFinishedMap;

  for (uint i = 0; i < bestTimesRec.Length; i++) {
    Json::Value arrayData = Json::Object();
    arrayData["time"] = bestTimesRec[i].time;
    arrayData["speed"] = bestTimesRec[i].speed;
    arrayData["pbTime"] = pbTimesRec[i].time;
    arrayData["pbSpeed"] = pbTimesRec[i].speed;
    arrayData["cp"] = bestTimesRec[i].checkpointId;
    jsonData["" + i] = arrayData;
  }

  Json::ToFile(jsonFile, jsonData);
}

bool quickMultiLapEnableCache = false;
void OnSettingsChanged() {
  if (resetMapData) {
    DebugText("saved data reset");
    resetMapData = false;

    ResetCommon();

    SaveFile();
  }

  {
    // has option changed
    if (quickMultiLapEnableCache != quickMultiLapEnable) {
      showCurrentBest = showCurrent = showLastLap = showLastLapDelta =
          quickMultiLapEnable;
    }

    // has any of the options it turns on changed?
    bool quickMultiLap =
        showCurrentBest && showCurrent && showLastLap && showLastLapDelta;
    if (quickMultiLapEnableCache != quickMultiLap) {
      quickMultiLapEnable = quickMultiLap;
    }
  }

  // update quick
  quickMultiLapEnableCache = quickMultiLapEnable;
}

// modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
  auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
  auto map = app.RootMap;
#elif TURBO
  auto map = app.Challenge;
#endif

  int timeWidth = 53;
  int deltaWidth = 60;

  // show theoretical after finishing all checkpoints
  bool shouldShowTheoretical =
      showTheoreticalBest && int(bestTimesRec.Length) == numCps;
  bool shouldShowEstimated = showEstimated &&
                             int(bestTimesRec.Length) == numCps && numCps > 0 &&
                             !isMultiLap;
  bool shouldShowPersonalBest = showPersonalBest && pbTime != 0;
  bool shouldShowLastLapDelta = isMultiLap && numLaps != 1;
  // number of cols we show checkpoint data for
  int dataCols = 0;
  dataCols += BoolToInt(showCheckpoints);
  dataCols += BoolToInt(showCurrentBest);
  dataCols += BoolToInt(showCurrent);
  dataCols += BoolToInt(shouldShowLastLapDelta && showLastLap);
  dataCols += BoolToInt(shouldShowLastLapDelta && showLastLapDelta);
  dataCols += BoolToInt(showBest);
  dataCols += BoolToInt(showBestDelta);
  dataCols += BoolToInt(showPB);
  dataCols += BoolToInt(showPBDelta);
  dataCols += BoolToInt(showBestPBDelta);
  // speed
  dataCols += BoolToInt(showCurrentSpeed);
  dataCols += BoolToInt(showBestSpeed);
  dataCols += BoolToInt(showBestSpeedDelta);
  dataCols += BoolToInt(showPBSpeed);
  dataCols += BoolToInt(showPBSpeedDelta);

  bool isDisplayingSomething = shouldShowEstimated || shouldShowTheoretical ||
                               shouldShowPersonalBest || showTopBestDelta ||
                               showTopPBDelta || dataCols != 0;

  if (hideWithIFace) {
    auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null ||
        !UI::IsGameUIVisible()) {
      return;
    }
  }

  bool invalidRun = !isFinished && waitForCarReset;

  if (invalidRun) {
    UI::PushStyleColor(UI::Col::Text, vec4(1.0, 0.0, 0.0, 1.0));
  }

  // if (isDisplayingSomething && windowVisible && map!is null &&
  // map.MapInfo.MapUid != "" && app.Editor is null) {
  if (isDisplayingSomething && windowVisible && map !is null &&
      map.MapInfo.MapUid != "") {
    if (lockPosition) {
      UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
    } else {
      UI::SetNextWindowPos(int(anchor.x), int(anchor.y),
                           UI::Cond::FirstUseEver);
    }

    int windowFlags =
        UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
        UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) {
      windowFlags |= UI::WindowFlags::NoInputs;
    }

    UI::PushFont(font);

    UI::Begin("Best Cp", windowFlags);

    if (!lockPosition) {
      anchor = UI::GetWindowPos();
    }

    UI::BeginGroup();

    // int wantedTopBar = 0;
    // wantedTopBar += BoolToInt(shouldShowTheoretical);
    // wantedTopBar += BoolToInt(shouldShowEstimated);
    // wantedTopBar += BoolToInt(shouldShowPersonalBest);
    // wantedTopBar += BoolToInt(true);  // PB Delta
    // wantedTopBar += BoolToInt(true);  // Best Delta
    // wantedTopBar*=2;
    int avaliableTopBar = dataCols;
    if (avaliableTopBar % 2 == 1) {
      avaliableTopBar--;
    }
    if (avaliableTopBar < 2) {
      avaliableTopBar = 2;
    }

    if (hasFinishedMap && UI::BeginTable("info", avaliableTopBar / 2,
                                         UI::TableFlags::SizingFixedFit)) {
      if (shouldShowTheoretical) {
        UI::TableNextColumn();
        string text = "Optimal: ";
        // show lowest if we have finished or on a seperate lap
        bool shouldShowLowest = isFinished || (currentLap != 0);

        int theoreticalBest = 0;
        for (uint i = 0; i < bestTimesRec.Length; i++) {
          // if we have finished then grab the best of both times
          // this is possibly bad, maybe only grab the lowest time anyway>
          if (shouldShowLowest) {
            theoreticalBest += GetLowestTime(i);
          } else {
            theoreticalBest += bestTimesRec[i].time;
          }
        }
        text += "~" + Time::Format(theoreticalBest);

        UI::Text(text);
      }

      if (shouldShowEstimated) {
        int time = 0;
        if (currCP != 0 || !isMultiLap ||
            int(currLapTimesRec.Length) != numCps) {
          lastEstimatedTime = CalulateEstimatedTime();
        } else {
          // last checkpoint delta off
          if (estimatedTimeUseOptimal) {
            time = currLapTimesRec[numCps - 1].time -
                   bestTimesRec[numCps - 1].time;
          } else {
            time =
                currLapTimesRec[numCps - 1].time - pbTimesRec[numCps - 1].time;
          }
        }
        time += lastEstimatedTime;

        if (time != 0) {
          UI::TableNextColumn();
          string text = "Estimated: ";
          text += "~" + Time::Format(time);
          UI::Text(text);
        }
      }

      if (shouldShowPersonalBest) {
        UI::TableNextColumn();
        string text = "PB: ";
        text += Time::Format(pbTime);
        UI::Text(text);
      }

      if (showTopPBDelta) {
        UI::TableNextColumn();
        string text = "PB Delta:";
        int delta = 0;
        for (uint i = 0; i < currTimesRec.Length; i++) {
          if (pbTimesRec.Length > i) {
            delta += getCurrentCPTime(i) - pbTimesRec[i].time;
          }
        }
        UI::Text(text);
        UI::SameLine();
        DrawDeltaText(delta);
      }

      if (showTopBestDelta) {
        UI::TableNextColumn();
        string text = "Best Delta:";
        int delta = 0;
        for (uint i = 0; i < currTimesRec.Length; i++) {
          if (bestTimesRec.Length > i) {
            delta += getCurrentCPTime(i) - bestTimesRec[i].time;
          }
        }
        UI::Text(text);
        UI::SameLine();
        DrawDeltaText(delta);
      }

      UI::EndTable();
    }

    if (dataCols != 0 &&
        UI::BeginTable("table", dataCols, UI::TableFlags::SizingFixedFit)) {
      // if (showHeader) {
      {
        if (showCheckpoints) {
          UI::TableNextColumn();
          SetMinWidth(0);
          UI::Text("Cp");
        }

        if (showCurrentBest) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("Current B.");
        }

        if (showCurrent) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("Current");
        }

        if (shouldShowLastLapDelta && showLastLap) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("Last Lap");
        }

        if (shouldShowLastLapDelta && showLastLapDelta) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("Lap Delta");
        }

        if (showBest) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("Best");
        }
        if (showBestDelta) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("B. Delta");
        }
        if (showPB) {
          UI::TableNextColumn();
          SetMinWidth(timeWidth);
          UI::Text("PB");
        }
        if (showPBDelta) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("PB. Delta");
        }
        if (showBestPBDelta) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("B-PB. Delta");
        }
        if (showCurrentSpeed) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("Speed");
        }
        if (showBestSpeed) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("B. speed");
        }
        if (showBestSpeedDelta) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("B. S. Delta");
        }
        if (showPBSpeed) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("PB. speed");
        }
        if (showPBSpeedDelta) {
          UI::TableNextColumn();
          SetMinWidth(deltaWidth);
          UI::Text("PB. S. Delta");
        }
      }

      bool isPBFaster = pbTime >= finishRaceTime;

      uint minNum =
          Math::Min(bestTimesRec.Length, Math::Abs(numCheckpointsOnScreen));
      uint offset = 0;

      if (minNum < bestTimesRec.Length) {
        if (currCP > int(minNum) / 2) {
          offset = currCP - minNum / 2;
        }

        if (currCP + minNum > int(bestTimesRec.Length) + 1 &&
            (!isMultiLap || isFinished)) {
          offset = int(bestTimesRec.Length) - minNum;
        }

        if (isFinished) {
          int postOffset =
              int((Time::get_Now() - finishRealTime) /
                  (Math::Max(0.001f, finishedCheckpointCycleSpeed) * 1000.0f));
          offset += Math::Max(0, postOffset);
        }
      }

      for (uint q = 0; q < minNum; q++) {
        uint i = offset + q;

        if (isMultiLap || isFinished) {
          i = i % bestTimesRec.Length;
        }
        UI::TableNextRow();

        isRenderingCurrentCheckpoint =
            (int(i) == currCP && !invalidRun && darkenCurrentLap);
        isRenderingCurrentCheckpoint =
            isRenderingCurrentCheckpoint ||
            (i == 0 && minNum < bestTimesRec.Length && isFinished);

        if (isRenderingCurrentCheckpoint) {
          UI::PushStyleColor(UI::Col::Text, vec4(0.7, 0.7, 0.7, 1.0));
        }

        // CP
        if (showCheckpoints) {
          UI::TableNextColumn();
          UI::Text("" + (i + 1));
        }

        if (showCurrentBest) {
          UI::TableNextColumn();
          if (currTimesRec.Length > i) {
            UI::Text(Time::Format(currTimesRec[i].time));
          }
        }

        if (showCurrent) {
          UI::TableNextColumn();
          if (currLapTimesRec.Length > i) {
            UI::Text(Time::Format(currLapTimesRec[i].time));
          }
        }

        if (shouldShowLastLapDelta) {
          if (showLastLap) {
            UI::TableNextColumn();
            if (currentLap != 0 && lastLapTimesRec.Length > i &&
                lastLapTimesRec[i].time != -1) {
              UI::Text(Time::Format(lastLapTimesRec[i].time));
            }
          }
          if (showLastLapDelta) {
            UI::TableNextColumn();
            if (currentLap != 0 && isCurrentCPValid(i) &&
                currLapTimesRec.Length > i && currLapTimesRec[i].time != -1 &&
                lastLapTimesRec.Length > i && lastLapTimesRec[i].time != -1) {
              int delta = currLapTimesRec[i].time - lastLapTimesRec[i].time;
              DrawDeltaText(delta);
            }
          }
        }

        // Best
        if (showBest) {
          UI::TableNextColumn();
          if (bestTimesRec.Length > i) {
            UI::Text(Time::Format(bestTimesRec[i].time));
          }
        }
        if (showBestDelta) {
          UI::TableNextColumn();
          if (bestTimesRec.Length > i && isCurrentCPValid(i)) {
            int delta = getCurrentCPTime(i) - bestTimesRec[i].time;
            DrawDeltaText(delta);
          }
        }

        if (pbTimesRec.Length > i) {
          // Personal Best
          if (showPB) {
            UI::TableNextColumn();
            // colors here are useless?
            if (showPBColor && isFinished) {
              if (isPBFaster) {
                UI::PushStyleColor(UI::Col::Text, vec4(1.0, 1.0, 1.0, 1.0));
              } else {
                UI::PushStyleColor(UI::Col::Text, vec4(1.0, 0.0, 0.0, 1.0));
              }
            }
            UI::Text(Time::Format(pbTimesRec[i].time));
            if (showPBColor && isFinished) {
              UI::PopStyleColor();
            }
          }
          if (showPBDelta) {
            UI::TableNextColumn();
            if (isCurrentCPValid(i)) {
              int delta = getCurrentCPTime(i) - pbTimesRec[i].time;
              DrawDeltaText(delta);
            }
          }
          if (showBestPBDelta) {
            UI::TableNextColumn();
            int compTime = pbTimesRec[i].time;
            // if (currTimesRec.Length > i) {
            //     if (compTime > currTimesRec[i].time) {
            //         compTime = currTimesRec[i].time;
            //     }
            // }
            int delta = compTime - bestTimesRec[i].time;
            DrawDeltaText(delta);
          }
        } else {
          UI::TableNextColumn();
          UI::TableNextColumn();
        }

        // speed
        if (showCurrentSpeed) {
          UI::TableNextColumn();
          if (currTimesRec.Length > i) {
            UI::Text("" + currTimesRec[i].speed);
          }
        }
        if (showBestSpeed) {
          UI::TableNextColumn();
          if (bestTimesRec.Length > i) {
            UI::Text("" + bestTimesRec[i].speed);
          }
        }
        if (showBestSpeedDelta) {
          UI::TableNextColumn();
          if (bestTimesRec.Length > i && currTimesRec.Length > i) {
            DrawSpeedDeltaText(bestTimesRec[i].speed - currTimesRec[i].speed);
          }
        }
        if (showPBSpeed) {
          UI::TableNextColumn();
          if (pbTimesRec.Length > i) {
            UI::Text("" + pbTimesRec[i].speed);
          }
        }
        if (showPBSpeedDelta) {
          UI::TableNextColumn();
          if (pbTimesRec.Length > i && currTimesRec.Length > i) {
            DrawSpeedDeltaText(pbTimesRec[i].speed - currTimesRec[i].speed);
          }
        }

        if (isRenderingCurrentCheckpoint) {
          UI::PopStyleColor();
        }
      }

      UI::EndTable();
    }

    UI::EndGroup();

    UI::End();

    UI::PopFont();
  }

  if (invalidRun) {
    UI::PopStyleColor();
  }
}

vec4 lerpMap(float t, float min, float max, vec4 minCol, vec4 maxCol) {
  float value = (t - min) / (max - min);
  return Math::Lerp(minCol, maxCol, value);
}

void DrawDeltaText(int delta) {
  int scale = 1;
  if (!shouldDeltaLerpColor) {
    scale *= 0;
  }
  vec4 colorScale;
  if (isRenderingCurrentCheckpoint) {
    colorScale = vec4(0.8, 0.8, 0.8, 1.0);
  } else {
    colorScale = vec4(1.0, 1.0, 1.0, 1.0);
  }
  vec4 negDelta;
  vec4 negDeltaLight;
  vec4 posDelta = vec4(1.0, 0.0, 0.0, 1.0);
  vec4 posDeltaLight = vec4(1.0, 0.4, 0.4, 1.0);
  if (shouldDeltaBeBlue) {  // why does blue look so shit?
    negDelta = vec4(0.4, 0.4, 1.0, 1.0);
    negDeltaLight = vec4(0.5, 0.5, 1.0, 1.0);
    // negDelta = negDeltaLight;
  } else {
    negDelta = vec4(0.0, 1.0, 0.0, 1.0);
    negDeltaLight = vec4(0.5, 1.0, 0.5, 1.0);
  }
  if (delta > 0) {
    UI::PushStyleColor(UI::Col::Text, lerpMap(delta, 0, 100 * scale + 1,
                                              posDeltaLight * colorScale,
                                              posDelta * colorScale));
    UI::Text("+" + Time::Format(delta));
  } else if (delta == 0) {
    UI::PushStyleColor(UI::Col::Text, negDelta * colorScale);
    UI::Text("-" + Time::Format(-delta));
  } else {
    UI::PushStyleColor(UI::Col::Text, lerpMap(delta, -100 * scale - 1, 0,
                                              negDelta * colorScale,
                                              negDeltaLight * colorScale));
    UI::Text("-" + Time::Format(-delta));
  }
  UI::PopStyleColor();
}

void DrawSpeedDeltaText(int delta) {
  int scale = 1;
  if (!shouldDeltaLerpColor) {
    scale *= 0;
  }
  vec4 colorScale;
  if (isRenderingCurrentCheckpoint) {
    colorScale = vec4(0.8, 0.8, 0.8, 1.0);
  } else {
    colorScale = vec4(1.0, 1.0, 1.0, 1.0);
  }
  vec4 negDelta;
  vec4 negDeltaLight;
  vec4 posDelta = vec4(1.0, 0.0, 0.0, 1.0);
  vec4 posDeltaLight = vec4(1.0, 0.4, 0.4, 1.0);
  if (shouldDeltaBeBlue) {  // why does blue look so shit?
    negDelta = vec4(0.4, 0.4, 1.0, 1.0);
    negDeltaLight = vec4(0.5, 0.5, 1.0, 1.0);
    // negDelta = negDeltaLight;
  } else {
    negDelta = vec4(0.0, 1.0, 0.0, 1.0);
    negDeltaLight = vec4(0.5, 1.0, 0.5, 1.0);
  }
  if (delta > 0) {
    UI::PushStyleColor(UI::Col::Text, lerpMap(delta, 0, 50 * scale + 1,
                                              posDeltaLight * colorScale,
                                              posDelta * colorScale));
    UI::Text("-" + delta);
  } else if (delta == 0) {
    UI::PushStyleColor(UI::Col::Text, negDelta * colorScale);
    UI::Text("+" + -delta);
  } else {
    UI::PushStyleColor(UI::Col::Text,
                       lerpMap(delta, -50 * scale - 1, 0, negDelta * colorScale,
                               negDeltaLight * colorScale));
    UI::Text("+" + -delta);
  }
  UI::PopStyleColor();
}

bool isCurrentCPValid(uint index) {
  if (shouldCompareToCurrentLap) {
    return currLapTimesRec.Length > index;
  } else {
    return currTimesRec.Length > index;
  }
}

int getCurrentCPTime(int index) {
  if (isCurrentCPValid(index)) {  // useless check?
    if (shouldCompareToCurrentLap) {
      return currLapTimesRec[index].time;
    } else {
      return currTimesRec[index].time;
    }
  }
  return -1;
}

void SetMinWidth(int width) {
  UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
  UI::Dummy(vec2(width, 0));
  UI::PopStyleVar();
}

void LoadFont() {
  string fontFaceToLoad = fontFace.Length == 0 ? "DroidSans.ttf" : fontFace;
  if (fontFaceToLoad != loadedFontFace || fontSize != loadedFontSize) {
    @font = Resources::GetFont(fontFaceToLoad, fontSize);
    if (font !is null) {
      loadedFontFace = fontFaceToLoad;
      loadedFontSize = fontSize;
    }
  }
}

// HELPERS

int BoolToInt(bool value) {
  if (value) {
    return 1;
  }
  return 0;
}

// UIModule_Race_TimeGap
// Network
// ClientManiaAppPlayground
// UILayers
// 10
// LocalPage
// GetClassChidren_Result
// Frame 0
// Controls 0
// Frame 0
// Control
// childs 0
// childs 0
// childs 1
// childs 3 (bottom right time diff window 4th player down)

// UIModule_Race_Checkpoint
// Network
// ClientManiaAppPlayground
// UILayers
// 8
// LocalPage
// GetClassChidren_Result
// Frame 0
// Controls 0
// Frame 0
// Controls 0
// Frame 0
// Controls 0
// Frame 0
// Controls 0
// Frame 0
// Controls 0
// controls 1 (label)
