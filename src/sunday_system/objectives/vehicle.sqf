// Vehicle target
_vehicleList = eCarClasses;
_vehicleType = selectRandom _vehicleList;		
_thisPos = AO_roadPosArray select 0;
AO_roadPosArray = AO_roadPosArray - [_thisPos];

// Marker
_markerName = format["vehMkr%1", floor(random 10000)];
_markerVehicle = createMarker [_markerName, _thisPos];
_markerVehicle setMarkerShape "ICON";
_markerVehicle setMarkerType  "o_motor_inf";
_markerVehicle setMarkerColor markerColorEnemy;
_markerVehicle setMarkerAlpha 0;

// Create Task		
_vehicleName = ((configFile >> "CfgVehicles" >> _vehicleType >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Destroy Vehicle";
_taskDesc = format ["Destroy the %3 %1 at the <marker name='%2'>marked location</marker>.", _vehicleName, _markerName, enemyFactionName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

_thisVeh = _vehicleType createVehicle _thisPos;	
_roads = _thisVeh nearRoads 50;
_dir = 0;
if (count _roads > 0) then {
	_firstRoad = _roads select 0;
	if (count (roadsConnectedTo _firstRoad) > 0) then {			
		_connectedRoad = ((roadsConnectedTo _firstRoad) select 0);
		_dir = [_firstRoad, _connectedRoad] call BIS_fnc_dirTo;
		_thisVeh setDir _dir;
	} else {
		_thisVeh setDir (random 360);
	};
};
// Find any doors to animate
{ 
	if ( ((configFile >> "CfgVehicles" >> _vehicleType >> "AnimationSources" >> (configName _x) >> "source") call BIS_fnc_GetCfgData) == "door") then {
		_thisVeh animateDoor [(configName _x), 1, true];
	};
} forEach ("true" configClasses (configFile >> "CfgVehicles" >> _vehicleType >> "AnimationSources"));

// Create fluff objects
_loadingChance = random 100;
if (_loadingChance > 50) then {
	_itemsArray = [		
		"CargoNet_01_barrels_F",
		"CargoNet_01_box_F",			
		"Land_PaperBox_closed_F",
		"Land_PaperBox_open_empty_F",
		"Land_PaperBox_open_full_F",
		"Land_Pallet_MilBoxes_F",
		"Land_Pallets_F",
		"Land_Pallet_F"					
	];
	_item1Pos = [getPos _thisVeh, 5, (_dir - 155)] call dro_extendPos;
	_item2Pos = [_item1Pos, 1.5, (_dir - 180)] call dro_extendPos;
	_item1 = selectRandom _itemsArray;
	_item2 = selectRandom _itemsArray;
	[_item1, _item1Pos, _dir] call dro_createSimpleObject;
	[_item2, _item2Pos, _dir] call dro_createSimpleObject;	
};

_guardPos = [getPos _thisVeh, 5, (_dir - 180)] call dro_extendPos;		
_group = [_guardPos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
_unit = ((units _group) select 0);
		
_thisVeh setVariable ["thisTask", _taskName];

// Add destruction event handler
_thisVeh addEventHandler ["Killed", {
	[((_this select 0) getVariable ("thisTask")), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
	missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];
} ];
		
_spawnPos = [_thisPos, 6, (random 360)] call dro_extendPos;
_minAI = 3;
_maxAI = 5;
if (aiSkill == 2) then {	
	_minAI = 2;
	_maxAI = 3;
};
_spawnedSquad = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;			
if (!isNil "_spawnedSquad") then {
	[_spawnedSquad, _thisPos, [10, 30], "limited"] execVM "sunday_system\orders\patrolArea.sqf";	
};

allObjectives pushBack _taskName;

objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_thisPos
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];