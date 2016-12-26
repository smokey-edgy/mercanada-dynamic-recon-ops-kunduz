// Destroy building

// Find a random building in the area
_building = [AO_buildingPositions] call dro_selectRemove;
_buildingClass = typeOf _building;		
_buildingPos = getPos _building;
	
// Populate building
_buildingPositions = [_building] call BIS_fnc_buildingPositions;
_buildingPositionsShuffled = _buildingPositions call BIS_fnc_arrayShuffle;

_targetArray = ["Land_Pallet_MilBoxes_F", "Land_DataTerminal_01_F", "Land_PaperBox_open_full_F", "MapBoard_altis_F", "Land_MetalBarrel_F"];
_spawnedObjects = [];
_infCount = 0;
_totalInf = 6;
if (aiSkill == 2) then {_totalInf = 3};
{
	if ((count _spawnedObjects) < 6) then {
		_thisTarget = selectRandom _targetArray;
		_object = createVehicle [_thisTarget, _x, [], 0, "CAN_COLLIDE"];		
		if (!isNil "_object") then {
			_spawnedObjects pushBack _object;
		};
	} else {	
		if (_infCount < _totalInf) then {
			_group = [_x, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
			_unit = ((units _group) select 0);									
			if (!isNil "_unit") then {
				_unit setUnitPos "UP";
				_infCount = _infCount + 1;
			};					
		};
	};		
} forEach _buildingPositionsShuffled;

// Spawn enemies to guard the building
_minAI = 2;
_maxAI = 5;
if (aiSkill == 2) then {	
	_minAI = 1;
	_maxAI = 2;
};
_spawnedSquad2 = [getPos _building, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;				
if (!isNil "_spawnedSquad2") then {
	[_spawnedSquad2, getPos _building, 100] call bis_fnc_taskPatrol;
};
// Marker
_markerName = format ["structureMkr%1", random 10000];
_markerBuilding = createMarker [_markerName, _buildingPos];
_markerBuilding setMarkerShape "ICON";
_markerBuilding setMarkerType "mil_destroy";
_markerBuilding setMarkerSize [1, 1];
_markerBuilding setMarkerColor markerColorEnemy;
_markerBuilding setMarkerAlpha 0;


// Create task
_taskName = format ["task%1", floor(random 10000)];
_taskTitle = "Destroy Structure";
_buildingName = ((configFile >> "CfgVehicles" >> _buildingClass >> "displayName") call BIS_fnc_GetCfgData);
_taskDesc = format ["Destroy the %2 containing %1 strategic elements at the marked <marker name='%3'>location</marker>.",enemyFactionName, _buildingName, _markerName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

_building setVariable ["thisTask", _taskName];
_building setVariable ["objects", _spawnedObjects];

// Add destruction event handler
_building addEventHandler ["Explosion", {
	if ((_this select 1) > 0.2) then {
		(_this select 0) setdamage 1;
		{
			deleteVehicle _x;
		} forEach ((_this select 0) getVariable 'objects');
		_taskState = [((_this select 0) getVariable 'thisTask')] call BIS_fnc_taskState;
		diag_log _taskState;
		if (_taskState != "SUCCEEDED") then {
			[((_this select 0) getVariable 'thisTask'), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
			missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];
		};
		(_this select 0) removeAllEventHandlers "Explosion";
	};
}];

_building addEventHandler ["Killed", {			
	{
		deleteVehicle _x;
	} forEach ((_this select 0) getVariable 'objects');
	_taskState = [((_this select 0) getVariable 'thisTask')] call BIS_fnc_taskState;
	diag_log _taskState;
	if (_taskState != "SUCCEEDED") then {
		[((_this select 0) getVariable 'thisTask'), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
		missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];
	};			
	(_this select 0) removeAllEventHandlers "Killed";
}];

allObjectives pushBack _taskName;
objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_buildingPos
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];