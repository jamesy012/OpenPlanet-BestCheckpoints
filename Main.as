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

void Main() {
    print("Hello from the new plugin system!");
}

// void Render() {
//         if (showTimer && CP::inGame) {
//             string text = predictedTimeString;
    
//             nvg::FontSize(fontSize);
//             if (font!is null) {
//                 nvg::FontFace(font);
//             }
//             nvg::TextAlign(nvg::Align::Center | nvg::Align::Middle);
    
//             if (showBackground) {
//                 nvg::FillColor(vec4(0, 0, 0, 0.8));
//                 vec2 size = nvg::TextBoxBounds(XPos * Draw::GetWidth() - 100, YPos * Draw::GetHeight(), 200, text);
//                 nvg::BeginPath();
//                 nvg::RoundedRect(XPos * Draw::GetWidth() - size.x * 0.6, YPos * Draw::GetHeight() - size.y * 0.67, size.x * 1.2, size.y * 1.2, 5);
//                 nvg::Fill();
//                 nvg::ClosePath();
//             }
    
//             nvg::FillColor(fontColor);
    
//             nvg::TextBox(XPos * Draw::GetWidth() - 100, YPos * Draw::GetHeight(), 200, text);
//         }
// }

void Render() {
	auto app = cast<CTrackMania>(GetApp());
	
#if TMNEXT||MP4
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

	if(hideWithIFace) {
		auto playground = app.CurrentPlayground;
		if(playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
			return;
		}
	}
	
	 if(windowVisible && map !is null && map.MapInfo.MapUid != "" && app.Editor is null)
     {
		if(lockPosition) {
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
		
		if(!lockPosition) {
			anchor = UI::GetWindowPos();
		}
		
		bool hasComment = string(map.MapInfo.Comments).Length > 0;
		
		UI::BeginGroup();
		if((showMapName || showAuthorName) && UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
			if(showMapName) {
				UI::TableNextRow();
				UI::TableNextColumn();
                UI::Text("Best CP " + (CP::NewStart == true) + " " + CP::curCP);
//#if TURBO
//				UI::Text((campaignMap ? "#" : "") + StripFormatCodes(map.MapInfo.Name) + (hasComment && !showAuthorName ? " \\$68f" + Icons::InfoCircle : ""));
//#else
//				UI::Text(StripFormatCodes(map.MapInfo.Name) + (hasComment && !showAuthorName ? " \\$68f" + Icons::InfoCircle : ""));
//#endif
			}
			if(showAuthorName) {
				UI::TableNextRow();
				UI::TableNextColumn();
				//UI::Text("\\$888by " + map.MapInfo.AuthorNickName + (hasComment ? " \\$68f" + Icons::InfoCircle : ""));
				UI::Text("\\$888by " + map.MapInfo.AuthorNickName);
			}
			UI::EndTable();
		}
		
		int numCols = 3; // name and time columns are always shown
		if(showMedalIcons) numCols++;
		if(showPbestDelta) numCols++;
		
		if(UI::BeginTable("table", numCols, UI::TableFlags::SizingFixedFit)) {
			if(showHeader) {
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
			
			for(uint i = 0; i < bestTimes.Length; i++) {
				//if(times[i].hidden) {
				//	continue;
				//}
				UI::TableNextRow();

				UI::TableNextColumn();
                UI::Text(""+i);


                UI::TableNextColumn();
                UI::Text(Time::Format(bestTimes[i]));
                //UI::Text(getTimeString(bestTimes[i]));

                if(currTimes.Length > i){
                    UI::TableNextColumn();
                    UI::Text(Time::Format(currTimes[i]));  
                    //UI::Text(getTimeString(currTimes[i]));  
                    UI::TableNextColumn();
                    int delta = currTimes[i] - bestTimes[i];
                    if(delta > 0){
                    UI::Text("+" +Time::Format(delta));  
                    }else{
                    UI::Text("-" +Time::Format(-delta));  

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
		
		if(hasComment && showComment && UI::IsItemHovered()) {
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

bool isCarReady() {
    CSmPlayer @ smPlayer = GetViewingPlayer();
    if (smPlayer != null && smPlayer.ScriptAPI != null) {
        return smPlayer.ScriptAPI.Post == CSmScriptPlayer::EPost::CarDriver;
    }
    return false;
}

void Update(float dt) {

    if (CP::NewStart == true && isCarReady()) {
        CP::NewStart = false;
        startTime = Time::get_Now();
        predictedTimeString = "00:00:00:000";

        lastCP = 0;
        lastCpTime = 0;

        UpdateWaypoints();
                warn("reset array");

        for(uint i = 0; i < currTimes.Length; i++) {
        if(currTimes[i] < bestTimes[i]){
        bestTimes[i] = currTimes[i] ;
        }
        }
        			for(uint i = 0; i < currTimes.Length; i++) {
                        currTimes.RemoveAt(0);
                    }
                            			for(uint i = 0; i < currTimes.Length; i++) {
                        currTimes.RemoveAt(0);
                    }
    }

    //if ((Time::get_Now() - startTime) > 0 && (CP::curCP > lastCP || CP::currCP == 0 &&CP::currCP!= lastCP )) {
    if ((Time::get_Now() - startTime) > 0 && CP::curCP!= lastCP) {
        lastCP = CP::curCP;

        int raceTime = Time::get_Now() - startTime;

        int avgTimePerLap = raceTime / 1;

        if (CP::curCP > 0) {
            avgTimePerLap = raceTime / CP::curCP;
        }

        predictedTime = raceTime - lastCpTime; //(avgTimePerLap * ((CP::maxCP + 1) - CP::curCP)) + raceTime;

        predictedTimeString = getTimeString(predictedTime);

        lastCpTime = raceTime;

                warn("adding to array " + lastCP);
        int cpNum = lastCP-1;
        if(cpNum == -1){
            cpNum = numCps;
        }
        if(bestTimes.Length<=cpNum){
            bestTimes.InsertLast(predictedTime);
        }

        //if(predictedTime < bestTimes[cpNum]){
        //    bestTimes[cpNum] = predictedTime;
        //}
        currTimes.InsertLast(predictedTime);
    }

    //    if(startTime != 0){
    //        CGamePlayer@ gameplayer = GetViewingPlayer();
    //	    CTrackManiaPlayer@ trackPlayer = cast<CTrackManiaPlayer@>(gameplayer);
    //        CSmPlayer@ smPlayer = GetViewingPlayer2();
    //        
    //	//CTrackManiaScriptPlayer@ m_scriptapi;
    ////
    //	//CSceneVehicleVisState(CTrackManiaPlayer@ player)
    //	//{
    //	//	@m_player = player;
    //	//	@m_scriptapi = m_player.ScriptAPI;
    //	//}
    //
    //if(smPlayer == null){
    // predictedTimeString = "null";
    //}else{
    //        predictedTimeString = getTimeString(Time::get_Now() - startTime);
    //        //predictedTimeString = "0"+trackPlayer.IsSpawned;
    //        predictedTimeString = "0"+(smPlayer.ScriptAPI.IdleDuration);
    //        predictedTimeString = "0"+(smPlayer.ScriptAPI.EngineRpm);
    //        predictedTimeString = "0"+(smPlayer.ScriptAPI.Post);
    //        predictedTimeString = "0"+(smPlayer.ScriptAPI.CurrentLapNumber);
    //}
    //    }
    //
    //predictedTimeString = "0" + numCps;
    CP::Update();
}

string getTimeString(int givenTime) {
    int msTimeAbsolute = 0;
    int secTimeAbsolute = 0;
    int minTimeAbsolute = 0;
    int hrTimeAbsolute = 0;

    msTimeAbsolute = givenTime;
    secTimeAbsolute = Math::Round(givenTime / 1000);
    minTimeAbsolute = Math::Round(givenTime / (1000 * 60));
    hrTimeAbsolute = Math::Round(givenTime / (1000 * 60 * 60));

    int msTimeFinal = msTimeAbsolute - (secTimeAbsolute * 1000);
    int secTimeFinal = secTimeAbsolute - (minTimeAbsolute * 60);
    int minTimeFinal = minTimeAbsolute - (hrTimeAbsolute * 60);
    int hrTimeFinal = hrTimeAbsolute;

    string msTimeString = "" + msTimeFinal;
    string secTimeString = "" + secTimeFinal;
    string minTimeString = "" + minTimeFinal;
    string hrTimeString = "" + hrTimeFinal;

    if (msTimeFinal < 100 && msTimeFinal > 10) {
        msTimeString = "0" + msTimeFinal;
    }

    if (msTimeFinal < 10) {
        msTimeString = "00" + msTimeFinal;
    }

    if (secTimeFinal < 10) {
        secTimeString = "0" + secTimeFinal;
    }

    //if (minTimeFinal < 10) {
    //    minTimeString = "0" + minTimeFinal;
    //}
//
    //if (hrTimeFinal < 10) {
    //    hrTimeString = "0" + hrTimeFinal;
    //}

    string resultString = hrTimeString + ":" + minTimeString + ":" + secTimeString + ":" + msTimeString;

    return resultString;
}

CSmPlayer @ GetViewingPlayer() {
    auto playground = GetApp().CurrentPlayground;
    if (playground is null || playground.GameTerminals.Length != 1) {
        return null;
    }
    return cast < CSmPlayer > (playground.GameTerminals[0].GUIPlayer);
}

//int GetNumWaypoints() {
//    auto playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
//    return playground.Arena.MapLandmarks.Length;
//}

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