// Destroy helicopter

_vehicleList = eHeliClasses;
_vehicleType = selectRandom _vehicleList;


_helipadUsed = 0;
_thisPos = [];		
if (count AO_helipads > 0) then {			
	_thisPos = getPos (AO_helipads select 0);
	AO_helipads = AO_helipads - [(AO_helipads select 0)];
	_helipadUsed = 1;
} else {
	_thisPos = AO_flatPositions select 0;
	AO_flatPositions = AO_flatPositions - [_thisPos];
	
	_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
	_thisPos = _tempPos;			
};		

	
// Marker
_markerName = format["heliMkr%1", floor(random 10000)];
_markerHeli = createMarker [_markerName, _thisPos];
_markerHeli setMarkerShape "ICON";
_markerHeli setMarkerType  "o_air";
_markerHeli setMarkerColor markerColorEnemy;
_markerHeli setMarkerAlpha 0;		

// Create Task		
_heliName = ((configFile >> "CfgVehicles" >> _vehicleType >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Destroy Helicopter";
_taskDesc = format ["Destroy the %3 %1 helicopter at the <marker name='%2'>marked location</marker>. Exercise caution, if the crew realise they are under threat they may decide to fly the helicopter out of the AO.", _heliName, _markerName, enemyFactionName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

_thisVeh = _vehicleType createVehicle _thisPos;	
createVehicleCrew _thisVeh;			
_thisVeh setVariable ["thisTask", _taskName];			

// Add destruction event handler
_thisVeh addEventHandler ["Killed", {
	[((_this select 0) getVariable ("thisTask")), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
	missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];
} ];

// Create helipad and emplacements
if (_helipadUsed == 0) then {
	_startDir = random 360;
	_helipad = createVehicle  ["Land_HelipadSquare_F", _thisPos, [], 0, "CAN_COLLIDE"];
	_helipad setDir (_startDir+45);	
	_dir = _startDir;
	_rotation = (_startDir - 45);
	for "_i" from 1 to 4 do {
		_cornerPos = [_thisPos, 16, _dir] call dro_extendPos;
		_corner = ["Land_HBarrierWall_corner_F", _cornerPos, _rotation] call dro_createSimpleObject;		
		_lightPos = [_thisPos, 10, _dir] call dro_extendPos;
		_light = ["PortableHelipadLight_01_red_F", _lightPos, _rotation] call dro_createSimpleObject;		
		_dir = _dir + 90;
		_rotation = _rotation + 90;
	};
	
	_towerPos = [_thisPos, 20, random 360] call dro_extendPos;
	["Land_HBarrierTower_F", _towerPos, (_startDir+45)] call dro_createSimpleObject;	
} else {
	_thisPad = nearestObject [_thisPos, "HeliH"];
	_dir = (getDir _thisPad);
	for "_i" from 1 to 4 do {				
		_lightPos = [_thisPos, 10, _dir] call dro_extendPos;
		_light = ["PortableHelipadLight_01_red_F", _lightPos, _dir] call dro_createSimpleObject;		
		_dir = _dir + 90;				
	};
};

_randItems = floor (random 4);
_itemsArray = ["Land_AirIntakePlug_05_F", "Land_DieselGroundPowerUnit_01_F", "Land_HelicopterWheels_01_assembled_F", "Land_HelicopterWheels_01_disassembled_F", "Land_RotorCoversBag_01_F", "Windsock_01_F"];
for "_i" from 1 to _randItems do {
	_itemPos = [_thisPos, 8, 20, 1, 0, 1, 0] call BIS_fnc_findSafePos;
	_thisItem = selectRandom _itemsArray;
	[_thisItem, _itemPos, (random 360)] call dro_createSimpleObject;	
};

// Guards
_minAI = 2;
_maxAI = 4;
if (aiSkill == 2) then {	
	_minAI = 1;
	_maxAI = 2;
};
_spawnedSquad = [_thisPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;						
if (!isNil "_spawnedSquad") then {
	[_spawnedSquad, _thisPos] call bis_fnc_taskDefend;
};
_minAI = 2;
_maxAI = 4;
if (aiSkill == 2) then {	
	_minAI = 1;
	_maxAI = 2;
};
_spawnedSquad2 = [_thisPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;					
if (!isNil "_spawnedSquad2") then {
	[_spawnedSquad2, _thisPos, 150] call bis_fnc_taskPatrol;				
};

// Create failstate trigger
_trgFlee = createTrigger ["EmptyDetector", _thisPos, true];
_trgFlee setTriggerArea [0, 0, 0, false];
_trgFlee setTriggerActivation ["ANY", "PRESENT", false];
_trgFlee setTriggerStatements [
	"
		{behaviour _x == 'COMBAT'} count [(thisTrigger getVariable 'heli')] > 0
	",
	"	
		_fleePos = [getPos (thisTrigger getVariable 'heli'), 3500, (random 360)] call dro_extendPos;
		while {(count (waypoints (group (thisTrigger getVariable 'heli')))) > 0} do {
			deleteWaypoint ((waypoints (group (thisTrigger getVariable 'heli'))) select 0);
		};
		_wp = (group (thisTrigger getVariable 'heli')) addWaypoint [_fleePos, 0];				
		_wp setWaypointSpeed 'FULL';
		_wp setWaypointType 'MOVE';		
	", 
	""];
_trgFlee setTriggerTimeout [180, 250, 300, true];			
_trgFlee setVariable ["heli", _thisVeh];

_trgFail = createTrigger ["EmptyDetector", _thisPos, true];
_trgFail setTriggerArea [2500, 2500, 0, false];
_trgFail setTriggerActivation ["ANY", "PRESENT", false];
_trgFail setTriggerStatements [
	"
		(alive (thisTrigger getVariable 'heli')) && 
		!((thisTrigger getVariable 'heli') in thisList) && 
		((thisTrigger getVariable 'heli') distance u1 > 1500)
	",
	"	
		[(thisTrigger getVariable 'thisTask'), 'FAILED', true] spawn BIS_fnc_taskSetState;				
		hideObject (thisTrigger getVariable 'heli');				
	", 
	""];
_trgFail setVariable ["heli", _thisVeh];
_trgFail setVariable ["thisTask", _taskName];		
				
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