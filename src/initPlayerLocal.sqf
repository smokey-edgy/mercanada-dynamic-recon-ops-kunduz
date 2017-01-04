
diag_log format ["DRO: Player %1 waiting for player init", player];
waitUntil {!isNull player};

player enableFatigue false;

[] execVM "hearts_and_minds\heliIntroDateTimeLocationText.sqf";
waitUntil {(missionNamespace getVariable ["squadHasDisembarkedAtFOB", 0]) == 1};
sleep 10;

#include "sunday_system\sundayFunctions.sqf"
#include "sunday_revive\reviveFunctions.sqf";

player createDiarySubject ["dro", "Dynamic Recon Ops"];
player createDiaryRecord ["dro", ["Dynamic Recon Ops", "
<font image='images\recon_image_collection.jpg' width='350' height='175'></font><br /><br />
Dynamic Recon Ops is a randomised, replayable scenario that generates an enemy occupied AO with a selection of tasks to complete within.
Select your AO location, the factions you want to use and any supports available or leave them all randomised and see what mission you are sent on.<br /><br />
Thank you for playing! If you have any feedback or bug reports please email me at mbrdmn@gmail.com.
<br /><br />
If you've enjoyed DRO and want to support further development of this mission and what comes next please consider donating through my Patreon page (www.patreon.com/mbrdmn).
Everything is appreciated and will directly go towards new content for DRO and my planned future missions.
"]];


player setVariable ["AllowAi", true];
player setVariable ["respawnLoadout", (getUnitLoadout player), true];
VAR_CAMERA_VIEW = cameraView;

if (didJIP) exitWith {
	if (getMarkerColor "respawn" == "") then {
		player setPos (getMarkerPos "campMkr");
	} else {
		player setPos (getMarkerPos "respawn");
	};
	cutText ["", "BLACK IN", 3];
};

diag_log format ["clientOwner = %1", clientOwner];
playerReady = 0;
enableTeamSwitch false;
enableSentences false;

//["Preload"] spawn BIS_fnc_arsenal;
sleep 2;
waitUntil {(missionNameSpace getVariable ["factionDataReady", 0]) == 1};
if (player == u1) then {
	waitUntil {!dialog};
	// Faction dialog
	diag_log "DRO: Create menu dialog";
	_handle = createDialog "sundayDialog";
	diag_log format ["DRO: Created dialog: %1", _handle];
	[] execVM "sunday_system\dialogs\populateStartupMenu.sqf";
};

waitUntil {(missionNameSpace getVariable ["serverReady", 0]) == 1};
diag_log format ["DRO: Player %1 init", player];
waitUntil{(missionNameSpace getVariable ["weatherChanged", 0]) == 0};

while {(missionNameSpace getVariable ["weatherChanged", 0]) == 0} do {
	if (player == u1) then {
		//cutText ["Extracting faction data", "BLACK FADED"];
	} else {
		cutText ["Please wait while mission is generated", "BLACK FADED"];
	};
};

diag_log format ["DRO: Player %1 weatherChanged == 1", player];

addWeaponItemEverywhere = compileFinal " _this select 0 addPrimaryWeaponItem (_this select 1); ";
addHandgunItemEverywhere = compileFinal " _this select 0 addHandgunItem (_this select 1); ";
removeWeaponItemEverywhere = compileFinal "_this select 0 removePrimaryWeaponItem (_this select 1)";

while {(missionNameSpace getVariable ["objectivesSpawned", 0]) == 0} do {
	cutText ["Please wait while mission is generated", "BLACK FADED"];
};

waitUntil{(missionNameSpace getVariable ["objectivesSpawned", 0]) == 1};

diag_log format ["DRO: Player %1 objectivesSpawned == 1", player];

// Get camera target point
_heightEnd = getTerrainHeightASL (missionNameSpace getVariable ["aoCamPos", []]);
_camEndPos = [(missionNameSpace getVariable "aoCamPos") select 0, (missionNameSpace getVariable ["aoCamPos", []]) select 1, 10];
_iconPos = ASLToAGL _camEndPos;

_aoLocationName = (missionNameSpace getVariable "aoLocationName");
_introNameHandle = CreateDialog "DRO_introDialog";


((findDisplay 424242) displayCtrl 3000) ctrlSetFade 1;
((findDisplay 424242) displayCtrl 3000) ctrlSetPosition [([-0.6, 0.6] call BIS_fnc_randomNum), ([-0.2, 0.15] call BIS_fnc_randomNum)];
((findDisplay 424242) displayCtrl 3000) ctrlCommit 0;
((findDisplay 424242) displayCtrl 3000) ctrlSetText (toUpper _aoLocationName);
((findDisplay 424242) displayCtrl 3000) ctrlSetFade 0;
((findDisplay 424242) displayCtrl 3000) ctrlCommit 1;

// Create camera start point
_extendPos = [_camEndPos, 500, (random 360)] call dro_extendPos;
_heightStart = getTerrainHeightASL _extendPos;
if (_heightStart < _heightEnd) then {
	_heightStart = _heightEnd;
};
if (_heightStart < 20) then {_heightStart = 0};
_camStartPos = [(_extendPos select 0), (_extendPos select 1), (_heightStart+20)];

// Init camera
cam = "camera" camCreate _camStartPos;
cam cameraEffect ["internal", "BACK"];
cam camSetPos _camStartPos;
cam camSetTarget _camEndPos;
cam camCommit 0;
if (timeOfDay == 4) then {
	camUseNVG true;
};
cameraEffectEnableHUD false;
cam camPreparePos _camEndPos;
cam camCommitPrepared 50;

diag_log format ["DRO: Player %1 camera initialised", player];

waitUntil{(missionNameSpace getVariable ["factionsChosen", 0]) == 1};

diag_log format ["DRO: Player %1 arsenal start selected", player];
//["BlackAndWhite"] call BIS_fnc_setPPeffectTemplate;
cutText ["", "BLACK IN", 1];
//["Default", 6] call BIS_fnc_setPPeffectTemplate;
sleep 6;
((findDisplay 424242) displayCtrl 3000) ctrlSetFade 1;
((findDisplay 424242) displayCtrl 3000) ctrlCommit 1;
cutText ["", "BLACK OUT", 1];
sleep 1;


closeDialog 1;

cam cameraEffect ["terminate","back"];
camUseNVG false;
camDestroy cam;
diag_log format ["DRO: Player %1 cam terminated", player];

// Open map
_mapOpen = openMap [true, false];
mapAnimAdd [0, 0.05, markerPos "centerMkr"];
mapAnimCommit;
cutText ["", "BLACK IN", 1];
hintSilent "Close map when ready to access loadout menu";
diag_log format ["DRO: Player %1 map initialised", player];

waitUntil {!visibleMap};
diag_log format ["DRO: Player %1 map closed", player];
hintSilent "";

//player switchCamera "GROUP";
// Init camera
_handle = CreateDialog "DRO_lobbyDialog";
diag_log format ["DRO: Player %1 created DRO_lobbyDialog: %2", player, _handle];
[] execVM "sunday_system\dialogs\populateLobby.sqf";

_actionID = player addAction ["Open Team Planning",
	{
		_handle = CreateDialog "DRO_lobbyDialog";
		[] execVM "sunday_system\dialogs\populateLobby.sqf";
	}, nil, 6];

diag_log format ["DRO: Player %1 waiting for all arsenals to close", player];

while {
	_handle
} do {
	sleep 1;

	if ((getMarkerColor "campMkr" == "")) then {
		((findDisplay 626262) displayCtrl 6006) ctrlSetText "Insertion position: RANDOM";
	} else {
		((findDisplay 626262) displayCtrl 6006) ctrlSetText format ["Insertion position: %1", (mapGridPosition (getMarkerPos 'campMkr'))];
	};

	if ((missionNameSpace getVariable "lobbyComplete") == 1) exitWith {
		closeDialog 1;
	};
};

waitUntil {((missionNameSpace getVariable "lobbyComplete") == 1)};

// Close dialogs twice in case player has arsenal open
closeDialog 1;
closeDialog 1;

player removeAction _actionID;

(format ["DRO: Player %1 lobby closed", player]) remoteExec ["diag_log", 2, false];

//player setVariable ["playerLoadout", (getUnitLoadout player)];

cutText ["", "BLACK FADED"];
/*
camLobby cameraEffect ["terminate","back"];
camUseNVG false;
camDestroy camLobby;
*/



player switchCamera "INTERNAL";
sleep 2;

enableSentences true;
cutText ["", "BLACK IN", 3];

// Mission info readout
_startPos = (missionNameSpace getVariable "startPos");
_campName = (missionNameSpace getVariable "publicCampName");

diag_log format ["DRO: Player %1 establishing shot initialised", player];

sleep 3;
[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", toUpper _campName], true, nil, 5, 0.7, 0] spawn BIS_fnc_textTiles;
sleep 6;

_hours = "";
if ((date select 3) < 10) then {
	_hours = format ["0%1", (date select 3)];
} else {
	_hours = str (date select 3);
};

_minutes = "";
if ((date select 4) < 10) then {
	_minutes = format ["0%1", (date select 4)];
} else {
	_minutes = str (date select 4);
};

[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1  %2</t>", str(date select 1) + "." + str(date select 2) + "." + str(date select 0), _hours + _minutes + " HOURS"], true, nil, 5, 0.7, 0] spawn BIS_fnc_textTiles;
sleep 6;

// Operation title text
_missionName = missionNameSpace getVariable "mName";
_string = format ["<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", _missionName];
[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1</t>", toUpper _missionName], true, nil, 7, 0.7, 0] spawn BIS_fnc_textTiles;
