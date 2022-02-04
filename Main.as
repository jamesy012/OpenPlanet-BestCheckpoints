
[Setting category="Display Settings" name="Window visible" description="To adjust the position of the window, click and drag while the Openplanet overlay is visible."]
bool windowVisible = true;

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

[Setting category="Options" name="Reset Data for Map" description="this will clear the best times for this map"]
bool resetMapData = false;

[Setting category="Options" name="Show theoretical best" description="Adds theoretical best time to the end of the window headder"]
bool showTheoreticalBest = true;

//timing
int startTime = 0;
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

void Update(float dt) {

    //have we changed map?
    if (currentMap != GetMapId()) {
        DebugText("map mismatch");

        //we have left the map, lets save our data before we lose it
        if(currentMap != ""){
            UpdateSaveBestData();
        }

        //reset important variables
        waitForCarReset = true;
        bestTimes = {};
        currTimes = {};
        jsonData = Json::Object();

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

    //extra reset
    if(resetMapData){
        resetMapData = false;
        waitForCarReset = true;
        bestTimes = {};
        currTimes = {};
        jsonData = Json::Object();
        SaveFile();
    }

    //wait for the car to be back at starting checkpoint
    if (waitForCarReset) {
        waitForCarReset = !IsWaypointStart(GetCurrentCheckpoint());
        playerStartTime = GetPlayerStartTime();
        return;
    }

    //wait for car to be driveable to do our final reset
    if (resetData && IsCarDriveable()) {
        DebugText("running reset");
        resetData = false;
        isFinished = false;

        //playerStartTime = GetPlayerStartTime();
        startTime = Time::get_Now();

        lastCP = GetStartCheckpoint();
        lastCpTime = 0;

        
        if(numCps == 0){
            UpdateWaypoints();
        }

        UpdateSaveBestData();

        currTimes = {};
    }


    int cp = GetCurrentCheckpoint();

    //have we changed checkpoint?
    if ((Time::get_Now() - startTime) > 0 && cp != lastCP) {
        //check if something went wrong with the player
        if (playerStartTime != GetPlayerStartTime()) {
            DebugTextChecked("failed  playerStartTime- " + playerStartTime + " != " + GetPlayerStartTime());
            waitForCarReset = true;
            resetData = true;
            return;
        }

        //check if this is a checkpoint we care about
        bool validWaypoint = IsWaypointValid(cp);
        if (cp != GetStartCheckpoint()) {
            DebugTextChecked("waypoint not valid - " + validWaypoint + " - " + cp + "/" + lastCP);
        }

        if (validWaypoint) {
            DebugTextChecked("adding time");
            lastCP = cp;

            int raceTime = Time::get_Now() - startTime;

            int deltaTime = raceTime - lastCpTime;
            lastCpTime = raceTime;

            //make sure bestTimes keeps up with the currTimes array
            if (bestTimes.Length <= currTimes.Length) {
                bestTimes.InsertLast(deltaTime);
            }

            //add our time
            currTimes.InsertLast(deltaTime);

            //check for finish
            if(IsWaypointFinish(cp)){
                waitForCarReset = true;
                resetData = true;
                isFinished = true;
            }
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

CSmPlayer @ GetPlayer() {
    auto playground = GetApp().CurrentPlayground;
    if (playground is null || playground.GameTerminals.Length != 1) {
        return null;
    }
    return cast < CSmPlayer > (playground.GameTerminals[0].GUIPlayer);
}

CSmScriptPlayer @ GetPlayerScript() {
    CSmPlayer @ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return null;
    }
    return smPlayer.ScriptAPI;
}

bool IsCarDriveable() {
    CSmScriptPlayer @ smPlayerScript = GetPlayerScript();
    if (smPlayerScript is null) {
        return false;
    }
    return smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver;
}

int GetPlayerStartTime() {
    CSmPlayer @ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.StartTime;
}


int GetCurrentCheckpoint() {
    CSmPlayer @ smPlayer = GetPlayer();
    if (smPlayer is null) {
        return -1;
    }
    return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
}

string GetMapName(){
    CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
    if(playground is null || playground.Map is null){
        return "";
    }
    return playground.Map.MapName;
}

string GetMapId(){
    CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
    if(playground is null || playground.Map is null){
        return "";
    }
    return playground.Map.IdName;
}

bool IsWaypointFinish(int index) {
    if (index == -1) {
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    if (index >= int(landmarks.Length)) {
        return false;
    }
    return landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish : false;
}

bool IsWaypointStart(int index) {
    if(index == -1){
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;

    if(index >= int(landmarks.Length)){
        return false;
    }

    return landmarks[index].Tag == "Spawn";
}


bool IsWaypointValid(int index) {
    if(index == -1){
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    if(index >= int(landmarks.Length)){
        return false;
    }
    bool valid = false;
    //valid |= (landmarks[index].Waypoint != null ? landmarks[index].Waypoint.IsFinish : false);
    //valid |= (landmarks[index].Tag == "Checkpoint");
    if (landmarks[index].Waypoint !is null ? landmarks[index].Waypoint.IsFinish : false)
        valid = true;
    if ((landmarks[index].Tag == "Checkpoint"))
        valid = true;
    return valid;
}


int GetStartCheckpoint() {
    CSmArenaClient@ playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    if(playground is null || playground.Arena is null){
        return -1;
    }
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;

    for (uint i = 0; i < landmarks.Length; i++) {
        if (IsWaypointStart(i)) {
            return i;
        }
    }
    return -1;
}

void UpdateWaypoints() {
    numCps = 0;
    isMultiLap = false;

    array < int > links = {};
    bool strictMode = true;

    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    if(playground is null || playground.Arena is null){
        return;
    }
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    for (uint i = 0; i < landmarks.Length; i++) {
        if (landmarks[i].Waypoint is null) {
            continue;
        }
        if (landmarks[i].Waypoint.IsMultiLap) {
            isMultiLap = true;
            continue;
        }
        if (landmarks[i].Waypoint.IsFinish) {
            numCps++;
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
    if(currentMap == ""){
        bestTimes = {};
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
    if (firstLoad == false) {
        // check validity of existing file
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
        }else{
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

#if TMNEXT || MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif

    bool hideWithIFace = false;
    bool showMapName = true;
    bool showAuthorName = false;
    bool showMedalIcons = true;
    bool showPbestDelta = false;
    bool showHeader = true;
    int timeWidth = 53;
    int deltaWidth = 60;
    bool showComment = true;

    if (hideWithIFace) {
        auto playground = app.CurrentPlayground;
        if (playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
    }

    if (windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null) {
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

        bool hasComment = string(map.MapInfo.Comments).Length > 0;

        UI::BeginGroup();
        if ((showMapName || showAuthorName) && UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
            if (showMapName) {
                UI::TableNextRow();
                UI::TableNextColumn();
                //UI::Text("Best CP " + playerStartTime + " " + IsWaypointStart(GetCurrentCheckpoint()) + " - " + waitForCarReset);
                //UI::Text("Best CP " + GetMapName() + " " + GetMapId() + " " + waitForCarReset + " " + lastCP+"/"+GetCurrentCheckpoint());

                string theoreticalString = "";

                if (showTheoreticalBest && isMultiLap == false && int(bestTimes.Length) == numCps) {
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
                    theoreticalString = "~" + Time::Format(theoreticalBest);
                }

                UI::Text("Best CP " + theoreticalString);
                //#if TURBO
                //				UI::Text((campaignMap ? "#" : "") + StripFormatCodes(map.MapInfo.Name) + (hasComment && !showAuthorName ? " \\$68f" + Icons::InfoCircle : ""));
                //#else
                //				UI::Text(StripFormatCodes(map.MapInfo.Name) + (hasComment && !showAuthorName ? " \\$68f" + Icons::InfoCircle : ""));
                //#endif
            }
            if (showAuthorName) {
                UI::TableNextRow();
                UI::TableNextColumn();
                //UI::Text("\\$888by " + map.MapInfo.AuthorNickName + (hasComment ? " \\$68f" + Icons::InfoCircle : ""));
                UI::Text("\\$888by " + map.MapInfo.AuthorNickName);
            }
            UI::EndTable();
        }

        int numCols = 3; // name and time columns are always shown
        if (showMedalIcons) numCols++;
        if (showPbestDelta) numCols++;

        if (UI::BeginTable("table", numCols, UI::TableFlags::SizingFixedFit)) {
            if (showHeader) {
                UI::TableNextRow();

                //if (showMedalIcons) {
                //	UI::TableNextColumn();
                //	// Medal icon has no header text
                //}

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
                //if(times[i].hidden) {
                //	continue;
                //}
                UI::TableNextRow();

                UI::TableNextColumn();
                UI::Text("" + (i + 1));

                UI::TableNextColumn();
                UI::Text(Time::Format(bestTimes[i]));
                //UI::Text(getTimeString(bestTimes[i]));

                if (currTimes.Length > i) {
                    UI::TableNextColumn();
                    UI::Text(Time::Format(currTimes[i]));
                    //UI::Text(getTimeString(currTimes[i]));  
                    UI::TableNextColumn();
                    int delta = currTimes[i] - bestTimes[i];
                    if (delta > 0) {
                        UI::PushStyleColor(UI::Col::Text, vec4(255,0,0,255));
                        UI::Text("+" + Time::Format(delta));
                    } else {
                        UI::PushStyleColor(UI::Col::Text, vec4(0,255,0,255));
                        UI::Text("-" + Time::Format(-delta));
                    }
                    UI::PopStyleColor();
                }


                //if(showMedalIcons) {
                //	UI::TableNextColumn();
                //	times[i].DrawIcon();
                //}
                //
                //UI::TableNextColumn();
                //times[i].DrawName();
                //
                //UI::TableNextColumn();
                //times[i].DrawTime();

                //if (showPbestDelta) {
                //	UI::TableNextColumn();
                //	times[i].DrawDelta(pbest);
                //}
            }

            UI::EndTable();
        }
        UI::EndGroup();

        if (hasComment && showComment && UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::PushTextWrapPos(200);
            UI::TextWrapped(map.MapInfo.Comments);
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }

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
	if(fontFaceToLoad != loadedFontFace || fontSize != loadedFontSize) {
		@font = Resources::GetFont(fontFaceToLoad, fontSize, -1, -1, true, true, true);
		if(font !is null) {
			loadedFontFace = fontFaceToLoad;
			loadedFontSize = fontSize;
		}
	}
}