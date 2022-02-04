//[Setting name = "Show Timer"]
bool showTimer = true;

//[Setting name = "Hide Timer when interface is hidden"]
bool hideTimerWithInterface = false;

//[Setting name = "X position" min = 0 max = 1]
float XPos = .6;

//[Setting name = "Y position" min = 0 max = 1]
float YPos = .91;

//[Setting category="Display Settings" name="Window position"]
vec2 anchor = vec2(0, 170);

//[Setting name = "Show background"]
bool showBackground = false;

//[Setting name = "Font size" min = 8 max = 72]
int fontSize = 24;

//[Setting color name = "Font color"]
vec4 fontColor = vec4(1, 1, 1, 1);

//[Setting category="Medals" name="Show Super Trackmaster" description="Super medals will automatically be hidden on non-campaign tracks."]
[Setting name="Save on run complete" description="Only sets best times when a run is finished."]
bool saveWhenCompleted = false;

int startTime = 0;
int lastCpTime = 0;

int lastCP = 0;
int predictedTime = 0;
string predictedTimeString = "00:00:00:000";

string curFontFace = "";
Resources::Font @ font;

int numCps = 0;
int[] currTimes;
int[] bestTimes;

bool waitForCarReset = true;
bool resetData = true;
int playerStartTime = -1;

void Main() {
    print("Hello from the new plugin system!");
    //waitForCarReset = getCurrentCheckpoint()!= 0;
    playerStartTime = GetPlayerStartTime();
}

void Update(float dt) {

    if(waitForCarReset){
        waitForCarReset = !isWaypointStart(getCurrentCheckpoint());
        playerStartTime = GetPlayerStartTime();
        return;
    }

    if (resetData && isCarDriveable()) {
        resetData= false;
        //playerStartTime = GetPlayerStartTime();
        startTime = Time::get_Now();
        predictedTimeString = "00:00:00:000";

        lastCP = -1;
        lastCpTime = 0;

        UpdateWaypoints();
        warn("reset array");

        bool save = true;

        if (saveWhenCompleted) {
            save = currTimes.Length == numCps;
        }
        warn("saving times " + save);

        if (save) {
            for (uint i = 0; i < currTimes.Length; i++) {
                if (currTimes[i] < bestTimes[i]) {
                    bestTimes[i] = currTimes[i];
                }
            }
        }
        currTimes = {};
    }


    int cp = getCurrentCheckpoint();

    //if ((Time::get_Now() - startTime) > 0 && (CP::curCP > lastCP || CP::currCP == 0 &&CP::currCP!= lastCP )) {
    if ((Time::get_Now() - startTime) > 0 && cp != lastCP) {

        if (playerStartTime != GetPlayerStartTime()) {
            waitForCarReset = true;
            resetData = true;
            return;
        }

        bool validWaypoint = isWaypointValid(cp);

        if (validWaypoint) {
            lastCP = cp;

            int raceTime = Time::get_Now() - startTime;

            int deltaTime = raceTime - lastCpTime;
            lastCpTime = raceTime;

            //make sure bestTimes keeps up with the currTimes array
            if (bestTimes.Length <= currTimes.Length) {
                bestTimes.InsertLast(deltaTime);
            }

            currTimes.InsertLast(deltaTime);

            if(isWaypointFinish(cp)){
                waitForCarReset = true;
                resetData = true;
            }
        }

    }
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
    if (smPlayer == null) {
        return null;
    }
    return smPlayer.ScriptAPI;
}

bool isCarDriveable() {
    CSmScriptPlayer @ smPlayerScript = GetPlayerScript();
    if (smPlayerScript == null) {
        return false;
    }
    return smPlayerScript.Post == CSmScriptPlayer::EPost::CarDriver;
}

int GetPlayerStartTime() {
    CSmPlayer @ smPlayer = GetPlayer();
    if (smPlayer == null) {
        return -1;
    }
    return smPlayer.StartTime;
}


int getCurrentCheckpoint() {
    CSmPlayer @ smPlayer = GetPlayer();
    if (smPlayer == null) {
        return -1;
    }
    return smPlayer.CurrentLaunchedRespawnLandmarkIndex;
}

bool isWaypointFinish(int index) {
    if (index == -1) {
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    if (index >= landmarks.Length) {
        return false;
    }
    return landmarks[index].Waypoint != null ? landmarks[index].Waypoint.IsFinish : false;
}

bool isWaypointStart(int index) {
    if(index == -1){
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;

    if(index >= landmarks.Length){
        return false;
    }

    return landmarks[index].Tag == "Spawn";
}


bool isWaypointValid(int index) {
    if(index == -1){
        return false;
    }
    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    if(index >= landmarks.Length){
        return false;
    }
    bool valid = false;
    //valid |= (landmarks[index].Waypoint != null ? landmarks[index].Waypoint.IsFinish : false);
    //valid |= (landmarks[index].Tag == "Checkpoint");
    if (landmarks[index].Waypoint != null ? landmarks[index].Waypoint.IsFinish : false)
        valid = true;
    if ((landmarks[index].Tag == "Checkpoint"))
        valid = true;
    return valid;
}

void UpdateWaypoints() {
    numCps = 0;
    array < int > links = {};
    bool strictMode = true;

    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
    MwFastBuffer < CGameScriptMapLandmark @ > landmarks = playground.Arena.MapLandmarks;
    for (uint i = 0; i < landmarks.Length; i++) {
        // if(waypoint is start or finish or multilap, it's not a checkpoint)
        if (landmarks[i].Waypoint is null || landmarks[i].Waypoint.IsFinish || landmarks[i].Waypoint.IsMultiLap)
            continue;
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

//modified https://github.com/Phlarx/tm-ultimate-medals
void Render() {
    auto app = cast < CTrackMania > (GetApp());

#if TMNEXT || MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif

    bool windowVisible = true;
    bool lockPosition = false;
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

        bool hasComment = string(map.MapInfo.Comments).Length > 0;

        UI::BeginGroup();
        if ((showMapName || showAuthorName) && UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
            if (showMapName) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Best CP " + playerStartTime + " " + isWaypointStart(getCurrentCheckpoint()) + " - " + waitForCarReset);
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
                setMinWidth(0);
                UI::Text("Cp");

                UI::TableNextColumn();
                setMinWidth(timeWidth);
                UI::Text("BestTime");

                UI::TableNextColumn();
                setMinWidth(timeWidth);
                UI::Text("Time");

                UI::TableNextColumn();
                setMinWidth(timeWidth);
                UI::Text("Delta");
            }

            for (uint i = 0; i < bestTimes.Length; i++) {
                //if(times[i].hidden) {
                //	continue;
                //}
                UI::TableNextRow();

                UI::TableNextColumn();
                UI::Text("" + i);


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
                        UI::Text("+" + Time::Format(delta));
                    } else {
                        UI::Text("-" + Time::Format(-delta));

                    }
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

void setMinWidth(int width) {
    UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
    UI::Dummy(vec2(width, 0));
    UI::PopStyleVar();
}