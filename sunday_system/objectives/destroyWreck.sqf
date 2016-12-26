// Destroy target
//_thisPos = [_pos, 0, 200, 10, 0, 10, 0] call BIS_fnc_findSafePos;
private ["_pVehicleWreckClasses"];
_pVehicleWreckClasses = _this select 0;

_thisPos = [];
_wreckType = "";
_wreckType = selectRandom _pVehicleWreckClasses;
while {count _wreckType == 0} do {
	_wreckType = selectRandom _pVehicleWreckClasses;
};
if (_wreckType isKindOf "Helicopter") then {
	_thisPos = AO_flatPositions select 0;
	AO_flatPositions = AO_flatPositions - [_thisPos];
} else {
	_posChance = (random 100);
	if (_posChance > 50) then {
		_thisPos = AO_flatPositions select 0;
		AO_flatPositions = AO_flatPositions - [_thisPos];
	} else {
		if (count AO_roadPosArray > 0) then {
			_thisPos = AO_roadPosArray select 0;
			AO_roadPosArray = AO_roadPosArray - [_thisPos];
		} else {
			_thisPos = AO_flatPositions select 0;
			AO_flatPositions = AO_flatPositions - [_thisPos];
		};						
	};
};

_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
_thisPos = _tempPos;

// Create objective
// Marker
_markerName = format["wreckMkr%1", floor(random 10000)];
_markerWreck = createMarker [_markerName, _thisPos];
_markerWreck setMarkerShape "ICON";
_markerWreck setMarkerType  "n_motor_inf";
_markerWreck setMarkerColor markerColorPlayers;
_markerWreck setMarkerAlpha 0;								

// Create Task				
_wreckName = ((configFile >> "CfgVehicles" >> _wreckType >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Destroy Wreck";
_taskDesc = format ["Deny the enemy use of our wrecked %1 located at the <marker name='%2'>marked area</marker>. Destroy the wreck by any means available.", _wreckName, _markerName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

_wreck = _wreckType createVehicle _thisPos;				
_wreck setVariable ["task", _taskName];
// Add destruction event handler
_wreck addEventHandler ["Killed", {
	(_this select 1)  addRating 7000;
	[((_this select 0) getVariable ('task')), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
	missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];	
} ];				
				
_wreck setVehicleAmmo 0;
_wreck setDamage 0.7;
_wreck setFuel 0;
_wreck lock true;
_wreck setDir (random 360);

_emitter = "#particlesource" createVehicleLocal _thisPos;
_emitter setParticleClass "BigDestructionSmoke";
_emitter setParticleFire [0.3,1.0,0.1];

// Create guards
_minAI = 3;
_maxAI = 5;
if (aiSkill == 2) then {	
	_minAI = 2;
	_maxAI = 3;
};
_spawnedSquad = [_thisPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI,_maxAI]] call dro_spawnGroupWeighted;									
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