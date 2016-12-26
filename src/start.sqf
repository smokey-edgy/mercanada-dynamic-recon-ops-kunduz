diag_log "DRO: Main DYN script started";

#include "sunday_system\sundayFunctions.sqf"
#include "sunday_system\generate_enemies\generateEnemiesFunctions.sqf"

adminID = owner u1;
publicVariable "adminID";

playersFaction = "";
enemyFaction = "";
civFaction = "";
pFactionIndex = 0;
adminID publicVariableClient "pFactionIndex";
playersFactionAdv = [0,0,0];
adminID publicVariableClient "playersFactionAdv";
eFactionIndex = 1;
adminID publicVariableClient "eFactionIndex";
enemyFactionAdv = [0,0,0];
adminID publicVariableClient "enemyFactionAdv";
cFactionIndex = 0;
adminID publicVariableClient "cFactionIndex";
timeOfDay = 0;
adminID publicVariableClient "timeOfDay";
insertType = 0;
adminID publicVariableClient "insertType";
randomSupports = 0;
adminID publicVariableClient "randomSupports";
customSupports = [0,0,0];
adminID publicVariableClient "customSupports";
aiSkill = 0;
adminID publicVariableClient "aiSkill";
numObjectives = 0;
adminID publicVariableClient "numObjectives";
aoOptionSelect = 2;
adminID publicVariableClient "aoOptionSelect";
customPos = [];
adminID publicVariableClient "customPos";
reviveDisabled = 0;
publicVariable "reviveDisabled";
readyPlayers = [];
playerGroup = [];
civTrue = false;
startVehicle = [0, ""];
publicVariable "startVehicle";
firstLobbyOpen = true;
publicVariable "firstLobbyOpen";
enemyIntelMarkers = [];
publicVariable "enemyIntelMarkers";

diag_log "DRO: Compile scripts";

fnc_generateAO = compile preprocessFile "sunday_system\generateAO.sqf";
fnc_selectObjective = compile preprocessFile "sunday_system\objSelect.sqf";
fnc_selectReactiveObjective = compile preprocessFile "sunday_system\objectives\selectReactiveTask.sqf";
fnc_defineFactionClasses = compile preprocessFile "sunday_system\defineFactionClasses.sqf";

blackList = [];

// *****
// EXTRACT FACTION DATA
// *****

// Check for factions that have units
_availableFactions = [];
availableFactionsData = [];
_unavailableFactions = [];
_factionsWithUnits = [];

// Record all factions with valid vehicles
{
	
	_factionsWithUnits pushBackUnique ((configFile >> "CfgVehicles" >> (configName _x) >> "faction") call BIS_fnc_GetCfgData);
} forEach ("(configName _x) isKindOf 'AllVehicles'" configClasses (configFile / "CfgVehicles"));
diag_log _factionsWithUnits;
// Filter out factions that have no vehicles
{
	if ((configName _x) in _factionsWithUnits) then {
		_availableFactions pushBackUnique (configName _x);
	} else {
		_unavailableFactions pushBackUnique (configName _x);
	};
} forEach ("true" configClasses (configFile / "CfgFactionClasses"));
_unavailableFactions pushBack "Virtual_F";

diag_log format ["DRO: Unavailable factions: %1", _unavailableFactions];

{
	_thisFaction = _x;
	_thisSideNum = ((configFile >> "CfgFactionClasses" >> _thisFaction >> "side") call BIS_fnc_GetCfgData);
	
	if (typeName _thisSideNum == "TEXT") then {
		if ((["west", _thisSideNum, false] call BIS_fnc_inString)) then {
			_thisSideNum = 1;
		};
		if ((["east", _thisSideNum, false] call BIS_fnc_inString)) then {
			_thisSideNum = 0;
		};
		if ((["guer", _thisSideNum, false] call BIS_fnc_inString) || (["ind", _thisSideNum, false] call BIS_fnc_inString)) then {
			_thisSideNum = 2;
		};
	};	
	
	if (typeName _thisSideNum == "SCALAR") then {
		if (_thisSideNum <= 3 && _thisSideNum > -1) then {
				
			_thisFactionName = ((configFile >> "CfgFactionClasses" >> _thisFaction >> "displayName") call BIS_fnc_GetCfgData);			
			_thisFactionFlag = ((configfile >> "CfgFactionClasses" >> _thisFaction >> "flag") call BIS_fnc_GetCfgData);
			
			if (_thisFaction in _unavailableFactions) then {
				
			} else {
				if (!isNil "_thisFactionFlag") then {
					availableFactionsData pushBack [_thisFaction, _thisFactionName, _thisFactionFlag, _thisSideNum];
				} else {
					availableFactionsData pushBack [_thisFaction, _thisFactionName, "", _thisSideNum];
				};
			};		
		};	
	};
} forEach _availableFactions;

adminID publicVariableClient "availableFactionsData";

missionNameSpace setVariable ["factionDataReady", 1];
publicVariable "factionDataReady";

// Initialise potential AO markers
[] execVM "sunday_system\initAO.sqf";

// *****
// PLAYERS SETUP
// *****

waitUntil {(missionNameSpace getVariable "factionsChosen") == 1};


// Get player faction
_playerSideNum = (configFile >> "CfgFactionClasses" >> playersFaction >> "side") call BIS_fnc_GetCfgData;
playersSide = west;
playersSideCfgGroups = "West";

switch (_playerSideNum) do {
	case 0: {
		playersSide = east;
		playersSideCfgGroups = "East";
		_grp = createGroup east;
		{[_x] joinSilent _grp} forEach (units(group u1));
	};
	case 1: {
		playersSide = west;
		playersSideCfgGroups = "West";
	};
	case 2: {
		playersSide = resistance;
		playersSideCfgGroups = "Indep";
		_grp = createGroup resistance;
		{[_x] joinSilent _grp} forEach (units(group u1));
	};
	case 3: {
		playersSide = civilian
	};
};

publicVariable "playersSideCfgGroups";
publicVariable "playersSide";

diag_log "DRO: Define player group";
playerGroup = (units(group u1));
DROgroupPlayers = (group u1);
groupLeader = leader DROgroupPlayers;

publicVariable "playerGroup";
publicVariable "DROgroupPlayers";
publicVariable "groupLeader";


{
	removeFromRemainsCollector [_x];
} forEach playerGroup;

unitDirs = [];
{
	if (!isNull _x) then {
		unitDirs set [_forEachIndex, (getDir _x)];
	};
} forEach playerGroup;
publicVariable "unitDirs";

// Prepare data for player lobby
_playersFactionData = [playersFaction, playersFactionAdv] call fnc_defineFactionClasses;

DROgroupPlayers = (group u1);
grpNetId = group u1 call BIS_fnc_netId;
publicVariable "grpNetId";
diag_log grpNetId;

pInfClasses = _playersFactionData select 0;
pOfficerClasses = _playersFactionData select 1;
pCarClasses = _playersFactionData select 2;
pCarNoTurretClasses = _playersFactionData select 3;
pTankClasses = _playersFactionData select 4;
pArtyClasses = _playersFactionData select 5;
pMortarClasses = _playersFactionData select 6;
pHeliClasses = _playersFactionData select 7;
pPlaneClasses = _playersFactionData select 8;
pShipClasses = _playersFactionData select 9;
pAmmoClasses  = _playersFactionData select 10;
pGenericNames = _playersFactionData select 11;
pLanguage = _playersFactionData select 12;
pUAVClasses = _playersFactionData select 13;
pInfClassesForWeights = _playersFactionData select 14;
pInfClassWeights = _playersFactionData select 15;
pStaticClasses = _playersFactionData select 16;

publicVariable "pCarClasses";
publicVariable "pHeliClasses";

// Define unitList for all selectable lobby classes
unitList = [];
publicVariable "unitList";
{
	unitList pushBackUnique [_x, ((configfile >> "CfgVehicles" >> _x >> "displayName") call BIS_fnc_getCfgData)];
} forEach pInfClasses;
publicVariable "unitList";

// Init player unit lobby variables
{
	_thisUnitType = (selectRandom unitList);	
	[[_x, _thisUnitType], 'sunday_system\switchUnitLoadout.sqf'] remoteExec ["execVM", _x, false];	
	
	switch (_x) do {
		case u1: {
			_x setVariable ['unitLoadoutIDC', 1201, true];
			_x setVariable ['unitArsenalIDC', 1301, true];
			_x setVariable ['unitDeleteIDC', 1501, true];
		};
		case u2: {
			_x setVariable ['unitLoadoutIDC', 1203, true];
			_x setVariable ['unitArsenalIDC', 1302, true];
			_x setVariable ['unitDeleteIDC', 1502, true];
		};
		case u3: {
			_x setVariable ['unitLoadoutIDC', 1205, true];
			_x setVariable ['unitArsenalIDC', 1303, true];
			_x setVariable ['unitDeleteIDC', 1503, true];
		};
		case u4: {
			_x setVariable ['unitLoadoutIDC', 1207, true];
			_x setVariable ['unitArsenalIDC', 1304, true];
			_x setVariable ['unitDeleteIDC', 1504, true];
		};
		case u5: {
			_x setVariable ['unitLoadoutIDC', 1209, true];
			_x setVariable ['unitArsenalIDC', 1305, true];
			_x setVariable ['unitDeleteIDC', 1505, true];
		};
		case u6: {
			_x setVariable ['unitLoadoutIDC', 1211, true];
			_x setVariable ['unitArsenalIDC', 1306, true];
			_x setVariable ['unitDeleteIDC', 1506, true];
		};
		case u7: {
			_x setVariable ['unitLoadoutIDC', 1213, true];
			_x setVariable ['unitArsenalIDC', 1307, true];
			_x setVariable ['unitDeleteIDC', 1507, true];
		};
		case u8: {
			_x setVariable ['unitLoadoutIDC', 1215, true];
			_x setVariable ['unitArsenalIDC', 1308, true];
			_x setVariable ['unitDeleteIDC', 1508, true];
		};
	};	
} forEach playerGroup;

// *****
// ENEMY SETUP
// *****

// Get enemy faction
_enemySideNum = (configFile >> "CfgFactionClasses" >> enemyFaction >> "side") call BIS_fnc_GetCfgData;
enemyFactionName = (configFile >> "CfgFactionClasses" >> enemyFaction >> "displayName") call BIS_fnc_GetCfgData;
enemySide = resistance;
enemySideCfgGroups = "Indep";

switch (_enemySideNum) do {
	case 0: {enemySide = east; enemySideCfgGroups = "East"};
	case 1: {enemySide = west; enemySideCfgGroups = "West"};
	case 2: {enemySide = resistance; enemySideCfgGroups = "Indep"};
	case 3: {enemySide = civilian};
};

// *****
// DEFINE MARKER COLOURS
// *****

markerColorPlayers = "colorBLUFOR";
switch (playersSide) do {
	case west: {		
		markerColorPlayers = "colorBLUFOR";
	};
	case east: {		
		markerColorPlayers = "colorOPFOR";
	};
	case resistance: {		
		markerColorPlayers = "colorIndependent";
	};	
};
publicVariable "markerColorPlayers";

markerColorEnemy = "colorOPFOR";
switch (enemySide) do {
	case west: {		
		markerColorEnemy = "colorBLUFOR";
	};
	case east: {		
		markerColorEnemy = "colorOPFOR";
	};
	case resistance: {		
		markerColorEnemy = "colorIndependent";
	};	
};
publicVariable "markerColorEnemy";

// *****
// AO SETUP
// *****

diag_log "DRO: Call AO script";

// Generate AO and collect data
_aoData = [] call fnc_generateAO;
_center = _aoData select 0;
centerPos = _aoData select 0;
_AREAMARKER_WIDTH = _aoData select 1;
_randomLoc = _aoData select 2;

waitUntil {count _aoData > 0};

// Reconfigure AO markers
"mkrN" setMarkerColor markerColorEnemy;
"mkrS" setMarkerColor markerColorEnemy;
"mkrE" setMarkerColor markerColorEnemy;
"mkrW" setMarkerColor markerColorEnemy;

// Enemy AO flag marker
_enemyFactionFlagIcon = ((configfile >> "CfgFactionClasses" >> enemyFaction >> "flag") call BIS_fnc_GetCfgData);
_enemyFactionName = ((configfile >> "CfgFactionClasses" >> enemyFaction >> "displayName") call BIS_fnc_GetCfgData);
_enemyFactionFlag = "";
_nonBaseFaction = 0;

if (!isNil "_enemyFactionName") then {
	{ 
		if (((configFile >> "CfgMarkers" >> (configName _x) >> "name") call BIS_fnc_GetCfgData) == _enemyFactionName) then {
			_enemyFactionFlag = (configName _x);			
		};
	} forEach ("true" configClasses (configFile / "CfgMarkers"));
};

if (count _enemyFactionFlag == 0) then {
	if (!isNil "_enemyFactionFlagIcon") then {		
		{ 
			if ([((configFile >> "CfgMarkers" >> (configName _x) >> "icon") call BIS_fnc_GetCfgData), _enemyFactionFlagIcon, false] call BIS_fnc_inString) then {
				_enemyFactionFlag = (configName _x);
				_nonBaseFaction = 1;
			};
		} forEach ("true" configClasses (configFile / "CfgMarkers"));

		switch (enemyFaction) do {
			case "BLU_F": {
				_enemyFactionFlag = "flag_NATO";
			};
			case "BLU_G_F": {
				_enemyFactionFlag = "flag_FIA";
			};
			case "IND_F": {
				_enemyFactionFlag = "flag_AAF";
			};
			case "OPF_F": {
				_enemyFactionFlag = "flag_CSAT";
			};
		};
	};
};
if (count _enemyFactionFlag == 0) then {
	deleteMarker "mkrFlag";
} else {
	"mkrFlag" setMarkerType _enemyFactionFlag;
	if (_nonBaseFaction == 1) then {
		"mkrFlag" setMarkerSize [2, 1.3];
	};
};

if (aoOptionSelect == 0) then {
	aoOptionSelect = [1,3] call BIS_fnc_randomInt;
};

// *****
// WEATHER & TIME
// *****

if (timeOfDay == 0) then {
	timeOfDay = [1,4] call BIS_fnc_randomInt;
};
publicVariable "timeOfDay";

_year = date select 0;
_month = [1, 12] call BIS_fnc_randomInt;
_day = [1, 28] call BIS_fnc_randomInt;

setDate [_year, _month, _day, 0, 0];

_dawnDusk = date call BIS_fnc_sunriseSunsetTime;
_dawnNum = _dawnDusk select 0;
_duskNum = _dawnDusk select 1;
_fog = 0;
_overcast = 0;
sleep 0.2;
switch (timeOfDay) do {
	case 1: {
		// DAWN
		_fogChance = (random 100);
		if (_fogChance > 35) then {
			_fog = [(random 0.05), (random [0.02, 0.045, 0.03]), (random [20, 100, 40])]
		} else {
			_fog = 0;
		};				
		_overcast = (random [0, 0.4, 1]);
		skipTime _dawnNum;				
	};
	case 2: {
		// DAY		
		_dayTime = [_dawnNum, _duskNum] call BIS_fnc_randomNum;		
		_overcast = (random 1);		
		_fog = ([0,1] call BIS_fnc_randomInt);
		if (_fog == 1) then {_fog = [(random [0, (_overcast/6), 0]), 0, 0]};	
		skipTime _dayTime;				
	};
	case 3: {
		// DUSK
		_fogChance = (random 100);
		if (_fogChance > 35) then {
			_fog = [(random 0.05), (random [0.02, 0.045, 0.03]), (random [20, 100, 40])]
		} else {
			_fog = 0;
		};		
		_overcast = (random [0, 0.4, 1]);		
		skipTime _duskNum;			
	};
	case 4: {
		// NIGHT
		_nightTime1 = [(_duskNum + 1), 24] call BIS_fnc_randomNum;
		_nightTime2 = [0, (_dawnNum - 1)] call BIS_fnc_randomNum;
		_nightTime = selectRandom [_nightTime1, _nightTime2];				
		_overcast = (random [0, 0.4, 1]);				
		_fog = ([0,1] call BIS_fnc_randomInt);
		if (_fog == 1) then {_fog = [(random [0, (_overcast/6), 0]), 0, 0]};
		skipTime _nightTime;
						
	};
};
sleep 0.1;

[_overcast] call BIS_fnc_setOvercast;
_fog call BIS_fnc_setFog;
simulWeatherSync;
_nextOvercast = (random 1);
_nextFog = if (_nextOvercast < 0.5) then {
	[(random 0.03), 0, 0];	
} else {
	[(random 0.10), 0, 0];
};
[2500, _nextOvercast] remoteExec ["setOvercast", 0, true];
[2500, _nextFog] remoteExec ["setFog", 0, true];

diag_log format ["DRO: time of day is %1", timeOfDay];

// *****
// INTRO SETUP
// *****

// Intro Music
_musicArrayDay = [
	"LeadTrack02_F_EXP",	
	"AmbientTrack03_F",
	"LeadTrack02_F_EPA",
	"LeadTrack01_F_EPA",
	"LeadTrack03_F_EPA",
	"LeadTrack01_F_EPB",
	"LeadTrack06_F",
	"BackgroundTrack02_F_EPC",	
	"LeadTrack03_F_Mark",
	"LeadTrack02_F_EPB"
];
_musicArrayNight = [
	"AmbientTrack04_F",
	"AmbientTrack04a_F",
	"AmbientTrack01_F_EPB",
	"AmbientTrack01b_F",
	"AmbientTrack01_F_EXP",
	"LeadTrack03_F_EPA",
	"LeadTrack03_F_EPC",
	"BackgroundTrack04_F_EPC",
	"EventTrack03_F_EPC"	
];
_track = nil;
if (timeOfDay <= 2) then {
	_track = selectRandom _musicArrayDay;
} else {
	_track = selectRandom _musicArrayNight;
};
[[_track,0,1],"bis_fnc_playmusic",true] call BIS_fnc_MP;

// Mission Name
_missionNameType = selectRandom ["OneWord", "DoubleWord", "TwoWords"];
_missionName = switch (_missionNameType) do {
	case "OneWord": {
		_nameArray = ["Garrotte", "Castle", "Tower", "Sword", "Moat", "Traveller", "Headwind", "Fountain", "Taskmaster", "Tulip", "Carnation", "Gaunt", "Goshawk", "Jasper", "Flashbulb", "Banker", "Piano", "Rook", "Knight", "Bishop", "Pyrite", "Granite", "Hearth", "Staircase"];
		format ["Operation %1", selectRandom _nameArray];
	};
	case "DoubleWord": {
		_name1Array = ["Dust", "Swamp", "Red", "Green", "Black", "Gold", "Silver", "Lion", "Bear", "Dog", "Tiger", "Eagle", "Fox", "North", "Moon", "Watch", "Under", "Key", "Court", "Palm", "Fire", "Fast", "Light", "Blind", "Spite", "Smoke", "Castle"];
		_name2Array = ["bowl", "catcher", "fisher", "claw", "house", "master", "man", "fly", "market", "cap", "wind", "break", "cut", "tree", "woods", "fall", "force", "storm", "blade", "knife", "cut", "cutter", "taker", "torch"];
		format ["Operation %1%2", selectRandom _name1Array, selectRandom _name2Array];
	};
	case "TwoWords": {		
		_name1Array = ["Midnight", "Fallen", "Turbulent", "Nesting", "Daunting", "Dogged", "Darkened", "Shallow", "Second", "First", "Third", "Blank", "Absent", "Parallel", "Restless"];		
		_useWorldName = random 1;
		_name2Array = if (_useWorldName > 0.2) then {
			["Sky", "Moon", "Sun", "Hand", "Monk", "Priest", "Viper", "Snake", "Boon", "Cannon", "Market", "Rook", "Knight", "Bishop", "Command", "Mirror", "Crisis", "Spider", "Charter", "Court", "Hearth"]
		} else {
			[worldName]
		};				
		
		format ["Operation %1 %2", selectRandom _name1Array, selectRandom _name2Array];
	};
};

missionNameSpace setVariable ["mName", _missionName];
publicVariable "mName";
missionNameSpace setVariable ["weatherChanged", 1];
publicVariable "weatherChanged";

// *****
// PLAYERS SETUP
// *****

// Setup player identities
_firstNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> pGenericNames >> "FirstNames");
_firstNames = [];
for "_i" from 0 to count _firstNameClass - 1 do {
	_firstNames pushBack (getText (_firstNameClass select _i));
};
_lastNameClass = (configFile >> "CfgWorlds" >> "GenericNames" >> pGenericNames >> "LastNames");
_lastNames = [];
for "_i" from 0 to count _lastNameClass - 1 do {
	_lastNames pushBack (getText (_lastNameClass select _i));
};

// Extract voice data
_speakersArray = [];
{
	_thisVoice = (configName _x);	
	_scopeVar = typeName ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData);
	switch (_scopeVar) do {
		case "STRING": {
			if ( ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData) == "public") then {		
				{
					if (typeName _x == "STRING") then {
						if (pLanguage == _x) then {
							_speakersArray pushBack _thisVoice;
						};
					};
				} forEach ((configFile >> "CfgVoice" >> _thisVoice >> "identityTypes") call BIS_fnc_GetCfgData);
			};	
		};		
		case "SCALAR": {
			if ( ((configFile >> "CfgVoice" >> _thisVoice >> "scope") call BIS_fnc_GetCfgData) == 2) then {		
				{			
					if (typeName _x == "STRING") then {
						if (pLanguage == _x) then {
							_speakersArray pushBack _thisVoice;
						};
					};
				} forEach ((configFile >> "CfgVoice" >> _thisVoice >> "identityTypes") call BIS_fnc_GetCfgData);
			};	
		};		
	};	
} forEach ("true" configClasses (configFile / "CfgVoice"));

if (count _speakersArray == 0) then {	
	switch (playersSide) do {
		case west: {
			_speakersArray = ["Male01ENG", "Male02ENG", "Male03ENG", "Male04ENG", "Male05ENG", "Male06ENG", "Male07ENG", "Male08ENG", "Male10ENG", "Male11ENG", "Male12ENG", "Male01ENGB", "Male02ENGB", "Male03ENGB", "Male04ENGB", "Male05ENGB"];
		};
		case east: {
			_speakersArray = ["Male01PER", "Male02PER", "Male03PER"];
		};
		case resistance: {
			_speakersArray = ["Male01GRE", "Male02GRE", "Male03GRE", "Male04GRE", "Male05GRE", "Male06GRE"];
		};
	};	
};

diag_log format ["DRO: Available voices: %1", _speakersArray];

// Change units to correct ethnicity and voices
nameLookup = [];
{
	_thisUnit = _x;			
	if (count _speakersArray > 0) then {
		_firstName = selectRandom _firstNames;
		_lastName = selectRandom _lastNames;
		_speaker = selectRandom _speakersArray;
		[[_thisUnit, _firstName, _lastName, _speaker], 'sun_setNameMP', true] call BIS_fnc_MP;
		nameLookup pushBack [_firstName, _lastName];
	};			
} forEach playerGroup;
publicVariable "nameLookup";

missionNameSpace setVariable ["initArsenal", 1];
publicVariable "initArsenal";

// *****
// ENEMIES SETUP
// *****

_enemyFactionData = [enemyFaction, enemyFactionAdv] call fnc_defineFactionClasses;

eInfClasses = _enemyFactionData select 0;
eOfficerClasses = _enemyFactionData select 1;
eCarClasses = _enemyFactionData select 2;
eCarNoTurretClasses = _enemyFactionData select 3;
eTankClasses = _enemyFactionData select 4;
eArtyClasses = _enemyFactionData select 5;
eMortarClasses = _enemyFactionData select 6;
eHeliClasses = _enemyFactionData select 7;
ePlaneClasses = _enemyFactionData select 8;
eShipClasses = _enemyFactionData select 9;
eAmmoClasses  = _enemyFactionData select 10;
eGenericNames = _enemyFactionData select 11;
eLanguage = _enemyFactionData select 12;
eUAVClasses = _enemyFactionData select 13;
eInfClassesForWeights = _enemyFactionData select 14;
eInfClassWeights = _enemyFactionData select 15;
eStaticClasses = _enemyFactionData select 16;

// *****
// OBJECTIVES SETUP
// *****

// Get number of tasks
_numObjs = 1;
if (numObjectives == 0) then {
	_numObjs = [1,3] call BIS_fnc_randomInt;
} else {
	_numObjs = numObjectives;
};

// Generate task data and physical objects
_prevObj = [];
allObjectives = [];
objData = [];
taskIDs = [];
reconPatrolUnused = true;
for "_i" from 1 to (_numObjs) do {
	_thisObj = [_prevObj] call fnc_selectObjective;
	_prevObj = _thisObj;	
};
waitUntil {count allObjectives == _numObjs};
diag_log format ["allObjectives = %1", allObjectives];

// Based on task data, assign tasks to players or assign recon tasks instead
{
	_reconChance = random 100;
	if (_reconChance < 80) then {
		// Create task for task data
		diag_log "DRO: Creating regular task";
		_markerPos = getMarkerPos (_x select 3);
		
		_id = [(_x select 0), true, [(_x select 1), (_x select 2), (_x select 3)], [(_markerPos select 0), (_markerPos select 1), 0], "CREATED", 1, false, true, (_x select 4), true] call BIS_fnc_setTask;		
		taskIDs pushBack _id;
		diag_log ["DRO: taskIDs is now: %1", taskIDs];
		if (markerShape (_x select 3) == "ICON") then {
			(_x select 3) setMarkerAlpha 0;
		} else {
			(_x select 3) setMarkerAlpha 0.5;
		};
		[(_x select 5), (_x select 0)] execVM "sunday_system\objectives\addTaskExtras.sqf";
	} else {
		// Recon addition selected, check the current task is not a recon task already
		if ((_x select 4) == "scout") then {
			// Create task for task data
			diag_log "DRO: Creating regular task as task is already a recon task";
			_markerPos = getMarkerPos (_x select 3);
						
			_id = [(_x select 0), true, [(_x select 1), (_x select 2), (_x select 3)], [(_markerPos select 0), (_markerPos select 1), 0], "CREATED", 1, false, true, (_x select 4), true] call BIS_fnc_setTask;			
			taskIDs pushBack _id;
			diag_log ["DRO: taskIDs is now: %1", taskIDs];
			if (markerShape (_x select 3) == "ICON") then {
				(_x select 3) setMarkerAlpha 0;
			} else {
				(_x select 3) setMarkerAlpha 0.5;
			};
			[(_x select 5), (_x select 0)] execVM "sunday_system\objectives\addTaskExtras.sqf";
		} else {
			// Create recon addition
			diag_log "DRO: Creating a recon task";
			[_x] execVM "sunday_system\objectives\reconTask.sqf";
		};
	};
} forEach objData;


// *****
// CIVILIAN SETUP
// *****

// Collect civilian classes
civClasses = [];
{
	if (((configFile >> "CfgVehicles" >> (configName _x) >> "faction") call BIS_fnc_GetCfgData) == civFaction) then {		
		if ( ((configFile >> "CfgVehicles" >> (configName _x) >> "scope") call BIS_fnc_GetCfgData) == 2) then {	
			if (configName _x isKindOf 'Man') then {
				if (
					(["_vr_", (configName _x), false] call BIS_fnc_inString) ||
					(["driver", (configName _x), false] call BIS_fnc_inString) ||
					(count ((configFile >> "CfgVehicles" >> (configName _x) >> "weapons") call BIS_fnc_GetCfgData) > 2)
				) then {
				
				} else {
					civClasses pushBack (configName _x);
				};				
			};
		};
	};
} forEach ("true" configClasses (configFile / "CfgVehicles"));

// Civilians only spawned if time of day is not nighttime
if (timeOfDay <= 3) then {	
	_civilians = random 100;
	if (_civilians > 60) then {
		civTrue = true;	
		[_randomLoc] execVM "sunday_system\generateCivilians.sqf";	
	};	
};

missionNameSpace setVariable ["objectivesSpawned", 1, true];

// *****
// GENERATE ENEMIES
// *****

_garrisionScriptHandle = [] execVM "sunday_system\findGarrisonBuildings.sqf";
waitUntil {scriptDone _garrisionScriptHandle};

if (AO_Type == "PEACEKEEPERS" && (count civClasses == 0)) then {
	AO_Type = "DEFAULT";
};

_enemyScript = nil;
switch (AO_Type) do {
	case "DEFAULT": {_enemyScript = [] execVM "sunday_system\generate_enemies\generateEnemies.sqf"};
	case "NOMAD": {_enemyScript = [] execVM "sunday_system\generate_enemies\generateEnemiesNomad.sqf"};
	case "BARRIER": {_enemyScript = [] execVM "sunday_system\generate_enemies\generateEnemiesBarrier.sqf"};
	case "PEACEKEEPERS": {_enemyScript = [] execVM "sunday_system\generate_enemies\generateEnemiesCivs.sqf"};
};

// *****
// WAIT FOR LOBBY COMPLETION
// *****

waitUntil {(missionNameSpace getVariable "lobbyComplete") == 1};

_setupPlayersHandle = [_center, playerGroup] execVM "sunday_system\setupPlayersFaction.sqf";
waitUntil {scriptDone _setupPlayersHandle};
diag_log "DRO: setupPlayersFaction completed";

// *****
// MISC EXTRAS
// *****

// Create a few empty enemy vehicles for use in escape
_numEscapeVehicles = [1,2] call BIS_fnc_randomInt;
for "_i" from 1 to _numEscapeVehicles do {
	_vehClass = "";
	if (count eCarNoTurretClasses > 0) then {
		_vehClass = selectRandom eCarNoTurretClasses;
	} else {
		_vehClass = selectRandom eCarClasses;
	};
	if (count _vehClass > 0) then {
		_pos = [AO_roadPosArray] call dro_selectRemove;
		_veh = _vehClass createVehicle _pos;
		
		_roadList = _pos nearRoads 10;
		if (count _roadList > 0) then {
			_thisRoad = _roadList select 0;
			_roadConnectedTo = roadsConnectedTo _thisRoad;
			_direction = 0;
			if (count _roadConnectedTo == 0) then {
				_direction = 0; 
			} else {
				_connectedRoad = _roadConnectedTo select 0;
				_direction = [_thisRoad, _connectedRoad] call BIS_fnc_DirTo;
			};
			
			_veh setDir _direction;
			_newPos = [_pos, 4, (_direction + 90)] call dro_extendPos;
			_veh setPos _newPos;
		};
	};
};

// Ambient flyover setup
_ambientFlyByChance = random 100;
if (_ambientFlyByChance > 60) then {
	_flyerClasses = (eHeliClasses + ePlaneClasses);
	if (count _flyerClasses > 0) then {
		[_center, _flyerClasses] execVM "sunday_system\ambientFlyBy.sqf";
	};
};

[_center] execVM "sunday_system\generateAnimals.sqf";
[] execVM "sunday_system\civMoveAction.sqf";

// Briefing init
_locType = type _randomLoc;
_locName = (missionNameSpace getVariable "aoLocationName");
_briefLocType = _aoData select 3;

[_locName, _locType, _briefLocType, "locMkr", "campMkr", "resupplyMkr", _missionName] execVM "briefing.sqf";

waitUntil {scriptDone _enemyScript};
[] execVM "sunday_system\addEnemyIntel.sqf";
[_center] execVM "sunday_system\generateMinefield.sqf";
[] call sun_removeEnemyNVG;

// *****
// SEQUENCING
// *****

// Reinforcement trigger
_trgReinf = createTrigger ["EmptyDetector", _center, true];
_trgReinf setTriggerArea [(_AREAMARKER_WIDTH*2.5), (_AREAMARKER_WIDTH*2.5), 0, false];
_trgReinf setTriggerActivation ["ANY", "PRESENT", false];
_trgReinf setTriggerStatements ["
	({alive _x && side _x == enemySide} count thisList) < (({alive _x && group _x == (thisTrigger getVariable 'DROgroupPlayers')} count thisList)*4.5)
", "diag_log 'DRO: Reinforcing due to player incursion'; ['aoSmallMkr', [1,2]] execVM 'sunday_system\reinforce.sqf';", ""];
_trgReinf setVariable ["DROgroupPlayers", (grpNetId call BIS_fnc_groupFromNetId)];

// Wait until all basic tasks are complete

diag_log format ["DRO: taskIDs = %1", taskIDs];

waituntil { 
	sleep 10;	
	_completeReturn = true;
	{
		_complete = [_x] call BIS_fnc_taskCompleted;
		if (!_complete) then {
			_completeReturn = false;
		};
	} forEach taskIDs;
	_completeReturn	
};

// Once all basic tasks are complete wait until any reactive tasks are also complete
_reactiveChance = random 100;
if (_reactiveChance > 70) then {
	diag_log "DRO: Creating reactive task";
	_thisObj = [] call fnc_selectReactiveObjective;
	waituntil { 
		sleep 10;
		_completeReturn = true;
		{
			_complete = [_x] call BIS_fnc_taskCompleted;
			if (!_complete) then {
				_completeReturn = false;
			};
		} forEach taskIDs;
		_completeReturn		
	};
};

// Filter available helicopters for transportation space
_numPassengers = count (units (grpNetId call BIS_fnc_groupFromNetId));
_heliTransports = [];
{
	if (((configFile >> "CfgVehicles" >> _x >> "transportSoldier") call BIS_fnc_GetCfgData) >= _numPassengers) then {
		_heliTransports pushBack _x;
	};
} forEach pHeliClasses;

// Create extract task
if ((count _heliTransports) > 0) then {	
	_taskCreated = ["taskExtract", true, ["Extract from the AO. A helicopter transport is available to support. Alternatively leave the AO by any means available.", "Extract", ""], objNull, "CREATED", 5, true, true, "default", true] call BIS_fnc_setTask;
	//_taskCreated = [DROgroupPlayers, ["taskExtract"], ["Extract from the AO. A helicopter transport is available to support. Alternatively leave the AO by any means available.", "Extract", ""], objNull, true, 5, true, "default", false] call BIS_fnc_taskCreate;	
	diag_log format ["DRO: Extract task created: %1", _taskCreated];
	[
		_heliTransports		
	] execVM 'sunday_system\heliExtractionSupport.sqf';	
} else {	
	_taskCreated = ["taskExtract", true, ["Leave the AO by any means to extract. Helicopter transport is unavailable.", "Extract", ""], objNull, "CREATED", 5, true, true, "default", true] call BIS_fnc_setTask;
	//_taskCreated = [DROgroupPlayers, ["taskExtract"], ["Leave the AO by any means to extract. Helicopter transport is unavailable.", "Extract", ""], objNull, true, 5, true, "default", false] call BIS_fnc_taskCreate;
	diag_log format ["DRO: Extract task created: %1", _taskCreated];
};

// Extraction success trigger
trgExtract = createTrigger ["EmptyDetector", _center, true];
trgExtract setTriggerArea [(aoSize/2), (aoSize/2), 0, true];
trgExtract setTriggerActivation ["ANY", "PRESENT", false];
trgExtract setTriggerStatements [
	"		
		({vehicle _x in thisList} count allPlayers == 0) &&
		({alive _x} count allPlayers > 0)
	",
	"
		['taskExtract', 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;		
		if (isMultiplayer) then {
			diag_log 'DRO: Ending MP mission: success';
			'Won' call BIS_fnc_endMissionServer;
		} else {
			diag_log 'DRO: Ending SP mission: success';
			'end1' call BIS_fnc_endMission;
		};		
	",
	""
];
trgExtract setVariable ["groupPlayers", (grpNetId call BIS_fnc_groupFromNetId)];

// Send new enemies to chase players
diag_log 'DRO: Reinforcing due to mission completion';
[(leader (grpNetId call BIS_fnc_groupFromNetId)), [2,4]] execVM 'sunday_system\reinforce.sqf';

// Make existing enemies close in on players
diag_log "DRO: Init staggered attack";
[30] execVM 'sunday_system\staggeredAttack.sqf';

// Music
[["LeadTrack02_F_Mark",0,1],"bis_fnc_playmusic",true] call BIS_fnc_MP;



