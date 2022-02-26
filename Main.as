
[Setting category="Display Settings" name="Window visible" description="To adjust the position of the window, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

[Setting category="Display Settings" name="Hide on hidden interface"]
bool hideWithIFace = false;

[Setting category="Display Settings" name="Window position"]
vec2 anchor = vec2(0, 780);

[Setting category="Display Settings" name="Lock window position" description="Prevents the window moving when click and drag or when the game window changes size."]
bool lockPosition = false;

[Setting category="Display Settings" name="Font face" description="To avoid a memory issue with loading a large number of fonts, you must reload the plugin for font changes to be applied."]
string fontFace = "";

[Setting category="Display Settings" name="Font size" min=8 max=48 description="To avoid a memory issue with loading a large number of fonts, you must reload the plugin for font changes to be applied."]
int fontSize = 16;

[Setting category="Options" name="Enable Logging" description="will start logging text to get an idea about what the programs doing"]
bool enableLogging = false;

[Setting category="Options" name="Save on run complete" description="Only stores/updates best times when a run is finished."]
bool saveWhenCompleted = true;

[Setting category="Options" name="Multi lap data override" description="should we let multi laps override our fastest time's (false will only use the first lap's time)"]
bool multiLapOverride = true;

//[Setting category="Options" name="Use new checkpoint time" description="times dont match what trackmania says, this aims to get a more accurate number"]
bool newCheckpointTimes = false;

[Setting category="Window Options" name="Show theoretical best" description="Adds theoretical best time to the window header"]
bool showTheoreticalBest = true;

[Setting category="Window Options" name="Show estimated time (experimental)" description="Adds estimated finish time to the window header"]
bool showEstimated = false;

[Setting category="Window Options" name="Show stored personal best" description="Show the personal best time the plugin has stored (if using the plugin after already playing a map these values wont match up)"]
bool showPersonalBest = false;

[Setting category="Window Options" name="Show checkpoints" description="Adds a number to the left for each checkpoint in the map"]
bool showCheckpoints = true;

[Setting category="Window Options" name="Show current times" description="Adds current times to the window"]
bool showCurrent = false;

[Setting category="Window Options" name="Show last lap Times (multi lap)" description="Adds last lap time to the window (only for multi lap)"]
bool showLastLap = false;

[Setting category="Window Options" name="Show last lap Delta (multi lap)" description="Adds delta to the last lap to the window (only for multi lap)"]
bool showLastLapDelta = false;

[Setting category="Window Options" name="Show best/Theoretical Times" description="Adds best times to the window"]
bool showBest = true;

[Setting category="Window Options" name="Show best/Theoretical Delta" description="Adds best delta to the window"]
bool showBestDelta = true;

[Setting category="Window Options" name="Show personal best Times" description="Adds personal best times to the window"]
bool showPB = true;

[Setting category="Window Options" name="Show personal best Delta" description="Adds personal best delta to the window"]
bool showPBDelta = true;

[Setting category="Window Options" name="Show personal best Color" description="Shows red on the PB times when it's below your pb"]
bool showPBColor = true;

[Setting category="Window Options" name="Show best to personal best Delta" description="Adds best to personal best delta to the window"]
bool showBestPBDelta = false;

[Setting category="Data" name="Save on disk" description="Stops saving data to disk - When this is disabled you will be able to load old data"]
bool saveData = true;

[Setting category="Data" name="Reset Data for Map" description="This will clear the best times for this map (does not delete file)"]
bool resetMapData = false;

//timing
int lastCpTime = 0;
//last waypoint cp id
int lastCP = 0;
int currentLap = 0;
//incrementing cp
int currCP = 0;

int finishRaceTime = 0;

//map data
int numCps = 0;
string currentMap;
int numLaps = 0;

class Record {
    int checkpointId = -1;
    int time;

    Record(int checkpointId, int time) {
        this.checkpointId = checkpointId;
        this.time = time;
    }

    Record@ opAssign(const Record & in record) {
        checkpointId = record.checkpointId;
        time = record.time;
        return this;
    }
}

//storage
//this Race Best times
Record@[] currTimesRec;
//overall best times
Record@[] bestTimesRec;
//personal best times (times for the personal best score)
Record@[] pbTimesRec;
int pbTime;

//storage of which checkpoint we have been through
Record@[] currLapTimesRec;
Record@[] lastLapTimesRec;

//extra
bool waitForCarReset = true;
bool resetData = true;
int playerStartTime = -1;
bool firstLoad = false;
bool isMultiLap = false;
bool isFinished = false;

//font
string loadedFontFace = "";
int loadedFontSize = 0;
Resources::Font@ font = null;

//file io
string jsonFile = '';
Json::Value jsonData = Json::Object();
string jsonVersion = "1.2";

//ui timing
int lastLapTime = 0;
int lastEstimatedTime = 0;

void DebugText(string text) {
    if (enableLogging) {
        print(text);
    }
}

void Main() {
    LoadFont();
    //waitForCarReset = GetCurrentCheckpoint()!= 0;
    playerStartTime = GetPlayerStartTime();
    //currentMap = GetMapId();
}

void OnDestroyed() {
    UpdateSaveBestData();
}

//clears data, waits till a reset to start happens
void ResetCommon() {
    waitForCarReset = true;
    ResetRace();
    bestTimesRec = {};
    pbTimesRec = {};
    pbTime = 0;
    jsonData = Json::Object();
}

void ResetRace() {
    currTimesRec = {};
    currLapTimesRec = {};
    lastLapTimesRec = {};
    isFinished = false;
    lastCP = GetSpawnCheckpoint();
    lastCpTime = 0;
    currentLap = 0;
    currCP = 0;
    finishRaceTime = 0;
    lastLapTime = 0;
}

void Update(float dt) {
    //have we changed map?
    if (currentMap != GetMapId()) {
        DebugText("map mismatch");

        //we have left the map, lets save our data before we lose it
        if (currentMap != "") {
            UpdateSaveBestData();
        }

        //reset file names
        jsonFile = "";
        currentMap = "";

        //reset important variables
        ResetCommon();

        //check for a valid map
        if (currentMap == "" || GetMapId() == "") {
            DebugText("map found - " + GetMapName());
            //waitForCarReset = false;
            playerStartTime = GetPlayerStartTime();

            currentMap = GetMapId();

            LoadFile();

            if (newCheckpointTimes) {
                UpdateCheckpointData();
            }

            UpdateWaypoints();
        }
    }
    //wait for the car to be back at starting checkpoint
    if (waitForCarReset) {
        //when waiting for a reset, Player race time ends up at a - value for the countdown before starting the lap
        waitForCarReset = GetPlayerRaceTime() >= 0;
        return;
    }

    //wait for car to be driveable to do our final reset
    if (resetData) {
        if (IsPlayerReady()) {
            DebugText("Running reset");
            resetData = false;
            UpdateSaveBestData();

            ResetRace();

            playerStartTime = GetActualPlayerStartTime();

            //lastCpTime = GetPlayerRaceTime();

            if (numCps == 0) {
                UpdateWaypoints();
            }

            DebugText("Ready to read checkpoints");
        }
        return;
    } else {
        //if our car no longer became valid? reset?
        if (!IsPlayerReady()) {
            DebugText("Car no longer valid..");
            resetData = true;
            return;
        }
    }


    int cp = GetCurrentCheckpoint();

    //have we changed checkpoint?
    if (cp != lastCP) {
        DebugText("Checkpoint change " + lastCP + "/" + cp);

        lastCP = cp;

        int raceTime = GetPlayerRaceTime();
        print(raceTime);

        if (newCheckpointTimes) {
            GetTimeBasedOnCar(cp);
        }

        int deltaTime = raceTime - lastCpTime;
        lastCpTime = raceTime;

        if (raceTime <= 0 || deltaTime <= 0) {
            DebugText("Checkpoint time negative..");
            waitForCarReset = true;
            return;
        }

        //if (isMultiLap && currentLap != 0) {
        //    int before = currTimesRec[currCP - 1].time;
        //    DebugText("Multi lap Comp: quicker? " + (before>deltaTime) + " " + Time::Format(before) + "/" + Time::Format(deltaTime));
        //}

        //add our time (best current time for run)
        CreateOrUpdateCurrentTime(cp, deltaTime);

        //update our best times, different logic for multilap
        if (int(currLapTimesRec.Length) == numCps) {
            CreateOrUpdateBestTime(cp, currLapTimesRec[currCP].time);
        } else {
            if (int(bestTimesRec.Length) != numCps) {
                CreateOrUpdateBestTime(cp, deltaTime);
            }
        }

        //update time for laps
        CreateOrUpdateCurrentLapTime(cp, deltaTime);

        currCP++;

        //check for finish
        if (IsWaypointFinish(cp)) {
            lastLapTime = Time::get_Now();
            currentLap++;
            if (isMultiLap) {
                DebugText("Lap finish: " + currentLap + "/" + numLaps);
            }

            if (!isMultiLap || currentLap == numLaps || !multiLapOverride) {
                DebugText("Race Finished");

                waitForCarReset = true;
                resetData = true;
                isFinished = true;
                finishRaceTime = GetPlayerRaceTime();
                if (pbTime == 0) {
                    UpdatePersonalBestTimes();
                }
            } else {
                //not finished, reset currCP
                currCP = 0;
            }
        }

    }
}

class CheckpointRecord {
    //CGameScriptMapLandmark data
    int checkpointId = -1;
    vec3 pos;

    //CGameCtnBlock data
    CGameCtnBlock::ECardinalDirections dir;
    vec3 coord;
    CGameCtnBlockInfo::EWayPointType type;
}

CheckpointRecord@[] checkpointData;

void UpdateCheckpointData() {
    DebugText("UpdateCheckpointData");
    checkpointData = {};
    CSmArenaClient@ playground = GetPlayground();
    if (playground is null || playground.Map is null) {
        return;
    }
    vec3 size = vec3(playground.Map.Size.x, playground.Map.Size.y, playground.Map.Size.z);
    const int blockSize = 32;
    DebugText("Size: " + size.ToString());
    for (uint i = 0; i < playground.Map.Blocks.Length; i++) {
        CGameCtnBlock@ block = playground.Map.Blocks[i];
        if (block.WaypointSpecialProperty!is null || block.BlockInfo.WaypointType != CGameCtnBlockInfo::EWayPointType::None) {
            CheckpointRecord rec;
            rec.dir = block.Dir;
            rec.coord = vec3(block.CoordX, block.CoordY, block.CoordZ);
            rec.type = block.BlockInfo.WayPointType;
            rec.pos = block.BlockModel.VariantBaseGround.SpawnTrans / 2;
            checkpointData.InsertLast(rec);

            //for (int q = 0; q < block.BlockUnits.Length; q++) {
            //    CGameCtnBlockUnit@ blockUnit = block.BlockUnits[q];
            //    for (int j = 0; j < blockUnit.BlockUnitModel.Clips_North.Length; j++) {
            //        if(blockUnit.BlockUnitModel.Clips_North[j] is null){
            //            DebugText("Null clip");
            //            continue;
            //        }
            //        CGameCtnBlockInfoClip@ clip = blockUnit.BlockUnitModel.Clips_North[j];
            //        if (clip.HasPassingPoint) {
            //            DebugText("asdasdas");
            //        }
            //    }
            //}
        }
    }
    //if(playground.Arena.MapLandmarks.Length != checkpointData.Length){
    //    DebugText("Checkpoint lenths dont match");
    //    return;
    //}
    //for (int i = 0; i < playground.Arena.MapLandmarks.Length; i++) {
    //    CGameScriptMapLandmark@ checkpoint = playground.Arena.MapLandmarks[i];
    //    CheckpointRecord@ rec = checkpointData[i];
    //    rec.checkpointId = i;
    //    rec.pos = checkpoint.Position;
    //}
    for (uint q = 0; q < checkpointData.Length; q++) {
        DebugText("checkpointData coord " + checkpointData[q].coord.ToString());
    }
    for (uint i = 0; i < playground.Arena.MapLandmarks.Length; i++) {
        CGameScriptMapLandmark@ checkpoint = playground.Arena.MapLandmarks[i];
        DebugText("MapLandmarks pos " + checkpoint.Position.ToString());
        DebugText("\t" + (checkpoint.Position / blockSize).ToString());
    }
    for (uint i = 0; i < playground.Arena.MapLandmarks.Length; i++) {
        DebugText("" + i);
        CGameScriptMapLandmark@ checkpoint = playground.Arena.MapLandmarks[i];
        vec3 coordPos = checkpoint.Position / blockSize;
        //coordPos.x -= 0.0;
        //coordPos.z -= 0.5;
        DebugText("\t" + coordPos.ToString());
        coordPos.y = 0;
        int closest = -1;
        float closestDistance = 9999;
        if (checkpoint.PlayerSpawn!is null) {
            DebugText("\tcp skipped");
            continue;
        }
        for (uint q = 0; q < checkpointData.Length; q++) {
            DebugText("" + q);
            vec3 checkPos = checkpointData[q].coord;
            DebugText("\t" + checkPos.ToString());
            checkPos.y = 0;
            //DebugText(coordPos - checkPos);
            float distance = (coordPos - checkPos).Length();
            DebugText("\t" + distance);
            if (closestDistance > distance) {
                closestDistance = distance;
                closest = q;
            }

        }
        DebugText("found data: " + closestDistance + " - " + closest);
        if (closest != -1) {
            DebugText("\tFound");
            CheckpointRecord@ rec = checkpointData[closest];
            if (rec.checkpointId != -1) {
                DebugText("\t already found?!");
            }
            rec.checkpointId = i;
            rec.pos += checkpoint.Position;
        }
    }
    PrintCheckpointData();
}

void PrintCheckpointData() {
    DebugText("Print Data");
    for (uint i = 0; i < checkpointData.Length; i++) {
        DebugText(checkpointData[i].coord.ToString());
        DebugText(checkpointData[i].pos.ToString());
    }
}

void GetTimeBasedOnCar(int checkpoint) {
    //     CSmPlayer@ carPlayer = GetPlayer();
    // DebugText(carPlayer.Score.BestLapTimes.Length);
    // return;
    CSmScriptPlayer@ player = GetPlayerScript();
    //CTrackManiaScriptPlayer@ tmPlayer = cast < CTrackManiaScriptPlayer > (player);
    //DebugText(tmPlayer.CurRace.NbRespawns);
    //return;
    vec3 carPos = player.Position;
    vec3 carForward = player.AimDirection;
    vec3 carUp = player.UpDirection;
    float carSpeed = player.Speed * 3.6;
    vec3 carVel = player.Velocity;

    DebugText(carPos.ToString());

    vec3 carPoint = carPos + carForward * 3;
    DebugText(carPoint.ToString());
    DebugText("" + carSpeed);
    //DebugText(carVel);

    int checkpointIndex = -1;
    for (int i = 0; i < int(checkpointData.Length); i++) {
        if (checkpointData[i].checkpointId == checkpoint) {
            checkpointIndex = i;
            break;
        }
    }
    if (checkpointIndex == -1) {
        DebugText("Failed to find checkpoint");
        return;
    }
    DebugText(checkpointData[checkpointIndex].pos.ToString());
    DebugText((checkpointData[checkpointIndex].pos - carPoint).ToString());

    //target 1.964
}

void CreateOrUpdateCurrentTime(int checkpoint, int time) {
    int recIndex = -1;
    for (uint i = 0; i < currTimesRec.Length; i++) {
        if (currTimesRec[i].checkpointId == checkpoint) {
            recIndex = int(i);
            break;
        }
    }

    if (recIndex == -1) {
        Record rec(checkpoint, time);
        currTimesRec.InsertLast(rec);
    } else {
        if (currTimesRec[recIndex].time > time) {
            currTimesRec[recIndex].time = time;
        }
    }
}

void CreateOrUpdateBestTime(int checkpoint, int time) {
    int recIndex = -1;
    for (uint i = 0; i < bestTimesRec.Length; i++) {
        if (bestTimesRec[i].checkpointId == checkpoint) {
            recIndex = int(i);
            break;
        }
    }

    if (recIndex == -1) {
        Record rec(checkpoint, time);
        bestTimesRec.InsertLast(rec);
    } else {
        if (bestTimesRec[recIndex].time > time) {
            bestTimesRec[recIndex].time = time;
        }
    }
}

void CreateOrUpdatePBTime(int checkpoint, int time) {
    int recIndex = -1;
    for (uint i = 0; i < pbTimesRec.Length; i++) {
        if (pbTimesRec[i].checkpointId == checkpoint) {
            recIndex = int(i);
            break;
        }
    }

    if (recIndex == -1) {
        Record rec(checkpoint, time);
        pbTimesRec.InsertLast(rec);
    } else {
        //if (pbTimesRec[recIndex].time > time) {
        pbTimesRec[recIndex].time = time;
        //}
    }
}

void CreateOrUpdateCurrentLapTime(int checkpoint, int time) {
    int recIndex = -1;
    for (uint i = 0; i < currLapTimesRec.Length; i++) {
        if (currLapTimesRec[i].checkpointId == checkpoint) {
            recIndex = int(i);
            break;
        }
    }

    if (recIndex == -1) {
        Record rec(checkpoint, time);
        currLapTimesRec.InsertLast(rec);
        lastLapTimesRec.InsertLast(Record(checkpoint, -1));
    } else {
        lastLapTimesRec[recIndex].time = currLapTimesRec[recIndex].time;
        currLapTimesRec[recIndex].time = time;
    }
}

void UpdatePersonalBestTimes() {
    if (isFinished && finishRaceTime != 0 && (finishRaceTime < pbTime || pbTime == 0)) {
        pbTime = finishRaceTime;
        for (uint i = 0; i < currTimesRec.Length; i++) {
            CreateOrUpdatePBTime(currTimesRec[i].checkpointId, currTimesRec[i].time);
        }
        //Final checkpoint is finish, can have multiple finish checkpoints, so this overides that
        pbTimesRec[currTimesRec.Length - 1] = currTimesRec[currTimesRec.Length - 1];
    }
}

void UpdateSaveBestData() {
    bool save = true;

    //if (saveWhenCompleted) {
    //    save = int(currTimesRec.Length) == numCps;
    //    if(save && isMultiLap){
    //        save = currentLap == numLaps;
    //    }
    //    if(save && isMultiLap){
    //        save = currentLap == numLaps;
    //    }
    //}
    if (saveWhenCompleted && !isFinished) {
        save = false;
    }
    DebugText("saving times? " + save);

    if (save) {
        //update our best times
        for (uint i = 0; i < currTimesRec.Length; i++) {
            if (currTimesRec[i].time < bestTimesRec[i].time) {
                bestTimesRec[i] = currTimesRec[i];
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

CSmArenaClient@ GetPlayground() {
    CSmArenaClient@ playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    return playground;
}

CSmArenaRulesMode@ GetPlaygroundScript() {
    CSmArenaRulesMode@ playground = cast < CSmArenaRulesMode > (GetApp().PlaygroundScript);
    return playground;
}

int GetCurrentGameTime() {
    CSmArenaClient@ playground = GetPlayground();
    if (playground is null || playground.Interface is null || playground.Interface.ManialinkScriptHandler is null) {
        return -1;
    }
    //CSmArenaInterfaceManialinkScripHandler@ aimsh = cast<CSmArenaInterfaceManialinkScripHandler>(playground.Interface.ManialinkScriptHandler );
    //return aimsh.ArenaNow; 
    return playground.Interface.ManialinkScriptHandler.GameTime;
}

CSmPlayer@ GetPlayer() {
    CSmArenaClient@ playground = GetPlayground();
    if (playground is null || playground.GameTerminals.Length != 1) {
        return null;
    }
    return cast < CSmPlayer > (playground.GameTerminals[0].GUIPlayer);
}

CSmScriptPlayer@ GetPlayerScript() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return null;
    }
    return smPlayer.ScriptAPI;
}

bool IsPlayerReady() {
    CSmScriptPlayer@ smPlayerScript = GetPlayerScript();
    if (smPlayerScript is null) {
        return false;
    }
    return GetPlayerRaceTime() >= 0 && smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
    //return smPlayerScript.EngineRpm >= 0 && smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
}

int GetPlayerRaceTime() {
    //CSmScriptPlayer@ smPlayerScript = GetPlayerScript();
    //if (smPlayerScript is null) {
    //    return -1;
    //}
    //if(UI::IsGameUIVisible()) {
    //    return smPlayerScript.CurrentRaceTime;
    //} else {
        return GetCurrentGameTime() - GetPlayerStartTime();// - GetPlaygroundScript().SpawnInvulnerabilityDuration;
    //}
}

int GetPlayerStartTime() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.StartTime;
}

int GetActualPlayerStartTime() {
    return GetPlayerStartTime() - GetPlayerRaceTime();
}


int GetCurrentCheckpoint() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
}

int GetCurrentLap() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
}

string GetMapName() {
    CSmArenaClient@ playground = GetPlayground();
    if (playground is null || playground.Map is null) {
        return "";
    }
    return playground.Map.MapName;
}

string GetMapId() {
    CSmArenaClient@ playground = GetPlayground();
    if (playground is null || playground.Map is null) {
        return "";
    }
    return playground.Map.IdName;
}

bool IsWaypointFinish(int index) {
    if (index == -1) {
        return false;
    }
    auto playground = GetPlayground();
    if (playground is null) {
        return false;
    }
    MwFastBuffer < CGameScriptMapLandmark@ > landmarks = playground.Arena.MapLandmarks;
    if (index >= int(landmarks.Length)) {
        return false;
    }
    return landmarks[index].Waypoint!is null ? landmarks[index].Waypoint.IsFinish : false;
}

bool IsWaypointStart(int index) {
    return GetSpawnCheckpoint() == index;
}


bool IsWaypointValid(int index) {
    if (index == -1) {
        return false;
    }
    auto playground = GetPlayground();
    MwFastBuffer < CGameScriptMapLandmark@ > landmarks = playground.Arena.MapLandmarks;
    if (index >= int(landmarks.Length)) {
        return false;
    }
    bool valid = false;
    //valid |= (landmarks[index].Waypoint != null ? landmarks[index].Waypoint.IsFinish : false);
    //valid |= (landmarks[index].Tag == "Checkpoint");
    if (landmarks[index].Waypoint!is null ? landmarks[index].Waypoint.IsFinish : false)
        valid = true;
    if ((landmarks[index].Tag == "Checkpoint"))
        valid = true;
    return valid;
}

int GetSpawnCheckpoint() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.SpawnIndex;
}

void UpdateWaypoints() {
    numCps = 1; //one for finish
    numLaps = 1;
    isMultiLap = false;

    array < int > links = {};
    bool strictMode = true;

    auto playground = GetPlayground();
    if (playground is null || playground.Arena is null || playground.Arena.Rules is null) {
        return;
    }

    CGameCtnChallenge@ map = playground.Map;
    numLaps = map.TMObjective_NbLaps;
    isMultiLap = map.TMObjective_IsLapRace;
    DebugText("Map Laps: " + numLaps + " Is MultiLap: " + isMultiLap);

    MwFastBuffer < CGameScriptMapLandmark@ > landmarks = playground.Arena.MapLandmarks;
    for (uint i = 0; i < landmarks.Length; i++) {
        if (landmarks[i].Waypoint is null) {
            continue;
        }
        if (landmarks[i].Waypoint.IsMultiLap) {
            //isMultiLap = true;
            continue;
        }
        if (landmarks[i].Waypoint.IsFinish) {
            //numCps++;
            continue;
        }
        //if(landmarks[i].Tag == "Spawn"){
        //}
        // we have a CP, but we don't know if it is Linked or not
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
                warn("The current map, " + string(playground.Map.MapName) + " (" + playground.Map.IdName + "), is not compliant with checkpoint naming rules.");
            }
            numCps++;
            strictMode = false;
        }
    }

}

int CalulateEstimatedTime() {
    if (int(bestTimesRec.Length) != numCps) {
        return 0;
    }
    int theoreticalBest = 0;
    for (int i = 0; i < int(bestTimesRec.Length); i++) {
        if (currCP > i) {
            theoreticalBest += currLapTimesRec[i].time;
        } else {
            theoreticalBest += bestTimesRec[i].time;

        }
    }

    return theoreticalBest;
}

//file io
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
        //file doesnt exist, dont load
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
        if (version == jsonVersion || version == "1.1") {

            numCps = jsonData["size"];
            if (version == "1.2") {
                pbTime = jsonData["pb"];
            }
            for (int i = 0; i < numCps; i++) {
                string key = "" + i;
                if (jsonData.HasKey(key)) {
                    if (version == "1.0") {
                        //1.0 stored in seperate data, with no checkpoint index
                        CreateOrUpdateBestTime(-1, jsonData[key]);
                    } else { //current
                        CreateOrUpdateBestTime(jsonData[key]["cp"], jsonData[key]["time"]);
                        if (version == "1.2") {
                            CreateOrUpdatePBTime(jsonData[key]["cp"], jsonData[key]["pbTime"]);
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

    //quick validation
    if (currTimesRec.Length == bestTimesRec.Length && bestTimesRec.Length == pbTimesRec.Length) {
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


    for (uint i = 0; i < bestTimesRec.Length; i++) {
        Json::Value arrayData = Json::Object();
        arrayData["time"] = bestTimesRec[i].time;
        arrayData["pbTime"] = pbTimesRec[i].time;
        arrayData["cp"] = bestTimesRec[i].checkpointId;
        jsonData["" + i] = arrayData;
    }

    Json::ToFile(jsonFile, jsonData);
}

void OnSettingsChanged() {
    if (resetMapData) {
        DebugText("saved data reset");
        resetMapData = false;

        ResetCommon();

        SaveFile();
    }
}

//modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
    auto app = cast < CTrackMania > (GetApp());

    //#if TMNEXT || MP4
    auto map = app.RootMap;
    //#elif TURBO
    //    auto map = app.Challenge;
    //#endif


    int timeWidth = 53;
    int deltaWidth = 60;

    //show theoretical after finishing all checkpoints
    bool shouldShowTheoretical = showTheoreticalBest && int(bestTimesRec.Length) == numCps;
    bool shouldShowEstimated = showEstimated && int(bestTimesRec.Length) == numCps && numCps > 0;
    bool shouldShowPersonalBest = showPersonalBest && pbTime != 0;
    bool shouldShowLastLapDelta = isMultiLap && numLaps != 1;
    //number of cols we show checkpoint data for
    int dataCols = 0;
    if (showCheckpoints) {
        dataCols++;
    }
    if (showCurrent) {
        dataCols++;
    }
    if (shouldShowLastLapDelta && showLastLap) {
        dataCols++;
    }
    if (shouldShowLastLapDelta && showLastLapDelta) {
        dataCols++;
    }
    if (showBest) {
        dataCols++;
    }
    if (showBestDelta) {
        dataCols++;
    }
    if (showPB) {
        dataCols++;
    }
    if (showPBDelta) {
        dataCols++;
    } 
    if (showBestPBDelta) {
        dataCols++;
    }

    bool isDisplayingSomething = shouldShowEstimated || shouldShowTheoretical || shouldShowPersonalBest || dataCols != 0;

    if (hideWithIFace) {
        auto playground = app.CurrentPlayground;
        if (playground is null || playground.Interface is null || !UI::IsGameUIVisible()) {
            return;
        }
    }

    //if (isDisplayingSomething && windowVisible && map!is null && map.MapInfo.MapUid != "" && app.Editor is null) {
    if (isDisplayingSomething && windowVisible && map!is null && map.MapInfo.MapUid != "") {
        if (lockPosition) {
            UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::Always);
        } else {
            UI::SetNextWindowPos(int(anchor.x), int(anchor.y), UI::Cond::FirstUseEver);
        }

        int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
        if (!UI::IsOverlayShown()) {
            windowFlags |= UI::WindowFlags::NoInputs;
        }

        UI::PushFont(font);

        UI::Begin("Best Cp", windowFlags);

        if (!lockPosition) {
            anchor = UI::GetWindowPos();
        }

        UI::BeginGroup();

        //if (UI::BeginTable("Header", 2, UI::TableFlags::SizingFixedFit)) {
        //        UI::TableNextColumn();
        //    UI::Text("Sector Times");
        //    UI::EndTable();
        //}

        if (UI::BeginTable("info", 2, UI::TableFlags::SizingFixedFit)) {

            if (shouldShowTheoretical) {
                UI::TableNextColumn();
                string text = "Theoretical: ";
                //show lowest if we have finished or on a seperate lap
                bool shouldShowLowest = isFinished || (currentLap != 0);

                int theoreticalBest = 0;
                for (uint i = 0; i < bestTimesRec.Length; i++) {
                    //if we have finished then grab the best of both times
                    //this is possibly bad, maybe only grab the lowest time anyway>
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
                if (currCP != 0 || !isMultiLap || int(currLapTimesRec.Length) != numCps) {
                    //UI::PushStyleColor(UI::Col::Text, vec4(255, 255, 255, 255));
                    lastEstimatedTime = CalulateEstimatedTime();
                } else {
                    //UI::PushStyleColor(UI::Col::Text, vec4(128, 128, 255, 255));
                    //last checkpoint delta off
                    time = currLapTimesRec[numCps - 1].time - bestTimesRec[numCps - 1].time;
                }
                time += lastEstimatedTime;

                if (time != 0) {
                    UI::TableNextColumn();
                    string text = "Estimated: ";
                    text += "~" + Time::Format(time);
                    UI::Text(text);
                }
                //UI::PopStyleColor();
            }

            if (shouldShowPersonalBest) {
                UI::TableNextColumn();
                string text = "PB: ";
                text += Time::Format(pbTime);
                UI::Text(text);
            }

            UI::EndTable();

        }

        bool invalidRun = !isFinished && waitForCarReset;

        if (invalidRun) {
            UI::PushStyleColor(UI::Col::Text, vec4(255, 0, 0, 255));
        }


        if (dataCols != 0 && UI::BeginTable("table", dataCols, UI::TableFlags::SizingFixedFit)) {
            //if (showHeader) {
            {
                if (showCheckpoints) {
                    UI::TableNextColumn();
                    SetMinWidth(0);
                    UI::Text("Cp");
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
            }

            bool isPBFaster = pbTime >= finishRaceTime;

            for (uint i = 0; i < bestTimesRec.Length; i++) {

                UI::TableNextRow();

                //CP
                if (showCheckpoints) {
                    UI::TableNextColumn();
                    UI::Text("" + (i + 1));
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
                        if (currentLap != 0 && lastLapTimesRec.Length > i && lastLapTimesRec[i].time != -1) {
                            UI::Text(Time::Format(lastLapTimesRec[i].time));
                        }
                    }
                    if (showLastLapDelta) {
                        UI::TableNextColumn();
                        if (currentLap != 0 && currLapTimesRec.Length > i && lastLapTimesRec.Length > i && lastLapTimesRec[i].time != -1) {
                            int delta = currLapTimesRec[i].time - lastLapTimesRec[i].time;
                            DrawDeltaText(delta);
                        }
                    }
                }

                //Best
                if (showBest) {
                    UI::TableNextColumn();
                    if (bestTimesRec.Length > i) {
                        UI::Text(Time::Format(bestTimesRec[i].time));
                    }
                }
                if (showBestDelta) {
                    UI::TableNextColumn();
                    if (bestTimesRec.Length > i && currLapTimesRec.Length > i) {
                        int delta = currLapTimesRec[i].time - bestTimesRec[i].time;
                        DrawDeltaText(delta);
                    }
                }

                if (pbTimesRec.Length > i) {

                    //Personal Best
                    if (showPB) {
                        UI::TableNextColumn();
                        //colors here are useless?
                        if (showPBColor && isFinished) {
                            if (isPBFaster) {
                                UI::PushStyleColor(UI::Col::Text, vec4(255, 255, 255, 255));
                            } else {
                                UI::PushStyleColor(UI::Col::Text, vec4(255, 0, 0, 255));
                            }
                        }
                        UI::Text(Time::Format(pbTimesRec[i].time));
                        if (showPBColor && isFinished) {
                            UI::PopStyleColor();
                        }
                    }
                    if (showPBDelta) {
                        UI::TableNextColumn();
                        if (currTimesRec.Length > i) {
                            int delta = currLapTimesRec[i].time - pbTimesRec[i].time;
                            DrawDeltaText(delta);
                        }
                    }
                    if (showBestPBDelta) {
                        UI::TableNextColumn();
                        int compTime = pbTimesRec[i].time;
                        //if (currTimesRec.Length > i) {
                        //    if (compTime > currTimesRec[i].time) {
                        //        compTime = currTimesRec[i].time;
                        //    }
                        //}
                        int delta = compTime - bestTimesRec[i].time;
                        DrawDeltaText(delta);
                    }
                } else {
                    UI::TableNextColumn();
                    UI::TableNextColumn();
                }

            }

            UI::EndTable();
        }

        if (invalidRun) {
            UI::PopStyleColor();
        }

        UI::EndGroup();

        UI::End();

        UI::PopFont();
    }
}

void DrawDeltaText(int delta) {
    if (delta > 0) {
        UI::PushStyleColor(UI::Col::Text, vec4(255, 0, 0, 255));
        UI::Text("+" + Time::Format(delta));
    } else {
        UI::PushStyleColor(UI::Col::Text, vec4(0, 255, 0, 255));
        UI::Text("-" + Time::Format(-delta));
    }
    UI::PopStyleColor();
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
        if (font!is null) {
            loadedFontFace = fontFaceToLoad;
            loadedFontSize = fontSize;
        }
    }
}