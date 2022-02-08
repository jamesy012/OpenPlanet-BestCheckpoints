
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

[Setting category="Options" name="Save on run complete" description="Only stores/updates best times when a run is finished."]
bool saveWhenCompleted = false;

[Setting category="Options" name="Show window title" description="Adds a title to the top of the window"]
bool showTitle = true;

[Setting category="Options" name="Show theoretical best" description="Adds theoretical best time to the end of the window headder"]
bool showTheoreticalBest = true;

[Setting category="Options" name="Save on disk" description="Stops saving data to disk - When this is disabled you will be able to load old data"]
bool saveData = true;

[Setting category="Options" name="Reset Data for Map" description="This will clear the best times for this map (does not delete file)"]
bool resetMapData = false;

//timing
int lastCpTime = 0;
int lastCP = 0;

//map data
int numCps = 0;
string currentMap;

//storage
int[] currTimes;
int[] bestTimes;

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
string jsonVersion = "1.0";


void DebugText(string text) {
    //print(text);
}
void DebugTextChecked(string text) {
    if (GetCurrentCheckpoint() != -1) {
        DebugText(text);
    }
}

void Main() {
    LoadFont();
    //waitForCarReset = GetCurrentCheckpoint()!= 0;
    playerStartTime = GetPlayerStartTime();
    //currentMap = GetMapId();
}

//clears data, waits till a reset to start happens
void ResetCommon() {
    waitForCarReset = true;
    ResetRace();
    bestTimes = {};
    jsonData = Json::Object();
}

void ResetRace() {
    currTimes = {};
    isFinished = false;
    lastCP = GetSpawnCheckpoint();
    lastCpTime = 0;
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

            UpdateWaypoints();
        }
    }

    //fileio reset
    if (resetMapData) {
        resetMapData = false;

        ResetCommon();

        SaveFile();
    }

    //wait for the car to be back at starting checkpoint
    if (waitForCarReset) {
        //when waiting for a reset, this will be the last value used (ie finish time)
        //during a reset it's set to a random negative value
        waitForCarReset = GetPlayerStartTime() >= 0;
        //waitForCarReset = !IsWaypointStart(GetCurrentCheckpoint());
        playerStartTime = GetPlayerStartTime();
        return;
    }

    //wait for car to be driveable to do our final reset
    if (resetData) {
        if (IsPlayerReady()) {
            DebugText("Running reset");
            resetData = false;

            UpdateSaveBestData();

            ResetRace();


            //playerStartTime = GetPlayerStartTime();
            playerStartTime = GetActualPlayerStartTime();

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

        int deltaTime = raceTime - lastCpTime;
        lastCpTime = raceTime;

        //make sure bestTimes keeps up with the currTimes array
        if (bestTimes.Length <= currTimes.Length) {
            bestTimes.InsertLast(deltaTime);
        }

        //add our time
        currTimes.InsertLast(deltaTime);

        //check for finish
        if (IsWaypointFinish(cp)) {
            DebugTextChecked("Race Finished");
            waitForCarReset = true;
            resetData = true;
            isFinished = true;
        }

    }
}

void UpdateSaveBestData() {
    bool save = true;

    if (saveWhenCompleted) {
        save = int(currTimes.Length) == numCps;
    }
    DebugText("saving times " + save + " - " + int(currTimes.Length) + "/" + numCps);

    if (save) {
        //update our best times
        for (uint i = 0; i < currTimes.Length; i++) {
            if (currTimes[i] < bestTimes[i]) {
                bestTimes[i] = currTimes[i];
            }
        }
        SaveFile();
    }
}

int GetLowestTime(uint checkpoint) {
    if (bestTimes.Length > checkpoint && currTimes.Length > checkpoint) {
        if (bestTimes[checkpoint] > currTimes[checkpoint]) {
            return currTimes[checkpoint];
        } else {
            return bestTimes[checkpoint];
        }
    } else {
        if (bestTimes.Length > checkpoint) {
            return bestTimes[checkpoint];
        }
        if (currTimes.Length > checkpoint) {
            return currTimes[checkpoint];
        }
    }
    return -1;
}

CSmPlayer@ GetPlayer() {
    auto playground = GetApp().CurrentPlayground;
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
    return smPlayerScript.CurrentRaceTime >= 0 && smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver && GetSpawnCheckpoint() != -1;
}

int GetPlayerRaceTime() {
    CSmScriptPlayer@ smPlayerScript = GetPlayerScript();
    if (smPlayerScript is null) {
        return -1;
    }
    return smPlayerScript.CurrentRaceTime;
}

int GetPlayerStartTime() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.StartTime;
}

int GetActualPlayerStartTime() {
    CSmScriptPlayer@ smPlayerScript = GetPlayerScript();
    if (smPlayerScript is null) {
        return -1;
    }
    return smPlayerScript.StartTime - smPlayerScript.CurrentRaceTime;
}


int GetCurrentCheckpoint() {
    CSmPlayer@ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
}

string GetMapName() {
    CSmArenaClient@ playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    if (playground is null || playground.Map is null) {
        return "";
    }
    return playground.Map.MapName;
}

string GetMapId() {
    CSmArenaClient@ playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    if (playground is null || playground.Map is null) {
        return "";
    }
    return playground.Map.IdName;
}

bool IsWaypointFinish(int index) {
    if (index == -1) {
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
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
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
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
    isMultiLap = false;

    array < int > links = {};
    bool strictMode = true;

    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    if (playground is null || playground.Arena is null) {
        return;
    }
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
        if (jsonData["version"] == jsonVersion) {
            //if (jsonData.HasKey("times")) {
            //    bestTimes = jsonData["times"];
            //}else{
            //    DebugText("invalid json Data");
            //}
            numCps = jsonData["size"];
            for (int i = 0; i < numCps; i++) {
                string key = "" + i;
                if (jsonData.HasKey(key)) {
                    bestTimes.InsertLast(jsonData[key]);
                } else {
                    DebugText("json missing key " + i);
                }
            }
        } else {
            DebugText("invalid json version");
            bestTimes = {};
        }
    } else {
        DebugText("invalid json file");
        bestTimes = {};
    }
}

void SaveFile() {
    firstLoad = false;

    if(jsonFile == "") {
        return;
    }

    if (saveData == false) {
        return;
    }

    jsonData = Json::Object();

    jsonData["version"] = jsonVersion;
    //jsonData["times"] = bestTimes;
    jsonData["size"] = bestTimes.Length;
    for (uint i = 0; i < bestTimes.Length; i++) {
        jsonData["" + i] = bestTimes[i];
    }

    Json::ToFile(jsonFile, jsonData);
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

    if (hideWithIFace) {
        auto playground = app.CurrentPlayground;
        if (playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
    }

    if (windowVisible && map!is null && map.MapInfo.MapUid != "" && app.Editor is null) {
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

        bool shouldShowTheoretical = showTheoreticalBest && isMultiLap == false && int(bestTimes.Length) == numCps;
        if ((showTitle || shouldShowTheoretical) && UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
            string headerText = "";
            if (showTitle) {
                headerText += "Best CP";
            }
            UI::TableNextRow();
            UI::TableNextColumn();
            //UI::Text("Best CP " + playerStartTime + " " + IsWaypointStart(GetCurrentCheckpoint()) + " - " + waitForCarReset);
            //UI::Text("Best CP " + GetMapName() + " " + GetMapId() + " " + waitForCarReset + " " + lastCP+"/"+GetCurrentCheckpoint());


            if (shouldShowTheoretical) {
                int theoreticalBest = 0;
                for (uint i = 0; i < bestTimes.Length; i++) {
                    //if we have finished then grab the best of both times
                    //this is possibly bad, maybe only grab the lowest time anyway>
                    if (isFinished) {
                        theoreticalBest += GetLowestTime(i);
                    } else {
                        theoreticalBest += bestTimes[i];
                    }
                }
                headerText += " ~" + Time::Format(theoreticalBest);
            }


            UI::Text(headerText);

            UI::EndTable();
        }

        int numCols = 4;

        if (UI::BeginTable("table", numCols, UI::TableFlags::SizingFixedFit)) {
            //if (showHeader) {
            {
                UI::TableNextRow();

                UI::TableNextColumn();
                SetMinWidth(0);
                UI::Text("Cp");

                UI::TableNextColumn();
                SetMinWidth(timeWidth);
                UI::Text("Best");

                UI::TableNextColumn();
                SetMinWidth(timeWidth);
                UI::Text("Current");

                UI::TableNextColumn();
                SetMinWidth(timeWidth);
                UI::Text("Delta");
            }

            for (uint i = 0; i < bestTimes.Length; i++) {

                UI::TableNextRow();

                //CP
                UI::TableNextColumn();
                UI::Text("" + (i + 1));

                //Best
                UI::TableNextColumn();
                UI::Text(Time::Format(bestTimes[i]));


                //Current/Delta
                if (currTimes.Length > i) {
                    //Current
                    UI::TableNextColumn();
                    UI::Text(Time::Format(currTimes[i]));

                    //Delta
                    UI::TableNextColumn();
                    int delta = currTimes[i] - bestTimes[i];
                    if (delta > 0) {
                        UI::PushStyleColor(UI::Col::Text, vec4(255, 0, 0, 255));
                        UI::Text("+" + Time::Format(delta));
                    } else {
                        UI::PushStyleColor(UI::Col::Text, vec4(0, 255, 0, 255));
                        UI::Text("-" + Time::Format(-delta));
                    }
                    UI::PopStyleColor();
                }

            }

            UI::EndTable();
        }
        UI::EndGroup();

        UI::End();

        UI::PopFont();
    }
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