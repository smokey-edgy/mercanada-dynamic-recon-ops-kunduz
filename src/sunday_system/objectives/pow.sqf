// POW

private ["_powStyles"];
_powStyles = _this select 0;

_powPos = [];
_powStyle = selectRandom _powStyles;					

_powChar = nil;
_spawnedSquad = nil;
_spawnedSquad2 = nil;

_powClass = "";		
_powClass = selectRandom pInfClasses;


switch (_powStyle) do {			
	case "OUTSIDE": {
		// Move to random location					
		_powPos = AO_forestPositions select 0;
		AO_forestPositions = AO_forestPositions - [_powPos];
		
		_tempPos = [(_powPos select 0), (_powPos select 1), 0];
		_powPos = _tempPos;
		
		_powSpawnPos = [];
		_powSpawnPos = [_powPos, 0, 150, 1.5, 0, 50, 0] call BIS_fnc_findSafePos;
		if (count _powSpawnPos > 0) then {
			_powPos = _powSpawnPos;
		};				
		
		_campObjects = [
			"Land_CampingTable_F",
			"Land_Camping_Light_F",
			"Land_CampingChair_V2_F",
			"Land_GasTank_01_khaki_F",
			"Land_Pillow_old_F",
			"Land_Ground_sheet_khaki_F",
			"Land_TentA_F",
			"Land_TentDome_F",
			"Land_WoodenLog_F",
			"Land_WoodPile_F",
			"Land_WoodPile_large_F",
			"Land_Garbage_square3_F",
			"Land_GarbageBags_F",					
			"Land_JunkPile_F"
		];
		_numCampObjects = [3,8] call BIS_fnc_randomInt;
		for "_i" from 1 to _numCampObjects do {
			_spawnPos = [_powPos, (1.5 + random 3), (random 360)] call dro_extendPos;
			_selectedObject = selectRandom _campObjects;
			_object = createVehicle [_selectedObject, _spawnPos, [], 2, "NONE"];
			_object setDir (random 360);
		};
						
		_group = createGroup side u1;
		_powChar = _group createUnit [_powClass, _powPos, [], 0, "NONE"];
					
	};
	case "INSIDE": {	
		// If nearby building possible then move to that building and spawn guards
		_building = [AO_buildingPositions] call dro_selectRemove;
		_buildingPlaces = [_building] call BIS_fnc_buildingPositions;
		_thisBuildingPlace = [0,((count _buildingPlaces)-1)] call BIS_fnc_randomInt;				
		_powPos = getPos _building;
		
		_group = createGroup side u1;
		_powChar = _group createUnit [_powClass, _powPos, [], 0, "NONE"];			
		_powChar setPosATL (_building buildingPos _thisBuildingPlace);			
	};		
};

_powChar switchMove "Acts_AidlPsitMstpSsurWnonDnon_loop";
_powChar setVariable["hostageBound", true, true];
_powChar setVariable["hostageActionID", 0, true];
_powChar setVariable["taskName", "", true];

[
	_powChar,
	"Unbind Hostage",
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
	"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
	"(alive _target) && (_target getVariable['hostageBound', false]) && ((_this distance _target) < 3)",
	"true",
	{playSound "BIS_Steerable_Parachute_Opening"},
	{},
	{
		[(_this select 0), (_this select 1)] call dro_hostageRelease;		
	},
	{},
	[],
	5,
	10,
	true,
	false
] remoteExec ["bis_fnc_holdActionAdd", 0, true];

_powChar setCaptive true;
_powChar disableAI "MOVE";	 
_powChar removeWeaponGlobal (primaryWeapon _powChar);
_powChar removeWeaponGlobal (secondaryWeapon _powChar);
_powChar removeWeaponGlobal (handgunWeapon _powChar);	
removeVest _powChar;
removeHeadgear _powChar;
removeGoggles _powChar;
removeBackpack _powChar;
removeAllItems _powChar;

[[_powChar], "sun_aiNudge"] call BIS_fnc_MP;	

// Spawn patrolling guards
_minAI = 2;
_maxAI = 3;
if (aiSkill == 2) then {	
	_minAI = 1;
	_maxAI = 2;
};
_spawnedSquad = [_powPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;						
if (!isNil "_spawnedSquad") then {
	[_spawnedSquad, _powPos, [10, 30], "limited"] execVM "sunday_system\orders\patrolArea.sqf";	
};
_spawnedSquad2 = [_powPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;		
if (!isNil "_spawnedSquad2") then {			
	[_spawnedSquad2, getPos _powChar] call bis_fnc_taskDefend;
};
//_allGuards = (((units(_spawnedSquad)))+(units(_spawnedSquad2)));

// Marker
_nearHouses = _powPos nearObjects ["House", 170];
_numHouses = {[_x] call BIS_fnc_isBuildingEnterable} count _nearHouses;
_markerSize = if (_numHouses > 10) then {
	80
} else {
	170
};
_markerPos = [_powPos, random(_markerSize-(_markerSize*0.1)), (random 360)] call dro_extendPos;
//_markerPos = [_powPos, 0, 150, 0, 1, 100, 0] call BIS_fnc_findSafePos;

_markerName = format["powMkr%1", floor(random 10000)];
_markerPOW = createMarker [_markerName, _markerPos];
_markerPOW setMarkerShape "ELLIPSE";
_markerPOW setMarkerBrush "Solid";
_markerPOW setMarkerColor markerColorPlayers;
_markerPOW setMarkerSize [_markerSize, _markerSize];
_markerPOW setMarkerAlpha 0;
enemyIntelMarkers pushBack [_markerPOW, _powPos];

// Create Task		
_powName = ((configFile >> "CfgVehicles" >> _powClass >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Rescue Captive";
_taskDesc = format ["Locate and rescue the captured %1. We believe the target is being held by the %3 somewhere within the <marker name='%2'>marked area</marker>. Exercise caution; we have every reason to believe the target will be executed if the enemy feels threatened.", _powName, _markerPOW, enemyFactionName];
_taskType = "meet";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
_powChar setVariable["taskName", _taskName, true];

 // Add triggers
_trgFail = createTrigger ["EmptyDetector", _powPos, true];
_trgFail setTriggerArea [0, 0, 0, false];
_trgFail setTriggerActivation ["ANY", "PRESENT", false];
_trgFail setTriggerStatements [
	"
		!alive (thisTrigger getVariable 'powChar')
	",
	"				
		[(thisTrigger getVariable 'thisTask'), 'FAILED', true] spawn BIS_fnc_taskSetState;										
	", 
	""];
_trgFail setVariable ["powChar", _powChar];		
_trgFail setVariable ["thisTask", _taskName];

/*
_trgExecute = createTrigger ["EmptyDetector", _powPos, true];
_trgExecute setTriggerArea [200, 200, 0, false];
_trgExecute setTriggerActivation ["ANY", "PRESENT", false];
_trgExecute setTriggerStatements [
	"
		({alive _x} count (thisTrigger getVariable 'allGuards')) < ((count (thisTrigger getVariable 'allGuards')) * 0.2)
	",
	"				
		(thisTrigger getVariable 'pow') setCaptive false;				
	", 
	""];
_trgExecute setVariable ["allGuards", _allGuards];
_trgExecute setVariable ["pow", _powChar];
*/

allObjectives pushBack _taskName;
objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_powPos
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];