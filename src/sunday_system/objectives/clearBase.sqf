_thisPos = AO_flatPositions select 0;
AO_flatPositions = AO_flatPositions - [_thisPos];

_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
_thisPos = _tempPos;

// Create main base
_startDir = random 360;	
_HQ = createVehicle ["Land_Cargo_HQ_V3_F", _thisPos, [], 0, "CAN_COLLIDE"];
_HQ setDir _startDir;		
// Create guards
_buildingPositionsHQ = [_HQ] call BIS_fnc_buildingPositions;
_totalInf = 6;
_infCount = 0;
if (aiSkill == 2) then {_totalInf = 4};
{ 
	_unitChance = (random 100);
	if (_unitChance > 50) then {
		if (_infCount < _totalInf) then {
			_group = createGroup enemySide;
			_group = [_x, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
			_unit = ((units _group) select 0);														
			_unit setFormDir (random 360);
			_unit setDir (random 360);
			_infCount = _infCount + 1;
		};
	};
} forEach _buildingPositionsHQ;

// Populate corner points		
_cornerFortClasses = ["Land_Cargo_Patrol_V3_F", "Land_HBarrierTower_F"];	

_dir = (_startDir - 45);
_rotation = (_startDir - 180);
for "_i" from 1 to 4 do {
	_popChance = (random 100);
	if (_popChance > 40) then {
		// Corner bunker
		_cornerPos = [_thisPos, 25, _dir] call dro_extendPos;
		_cornerClass = selectRandom _cornerFortClasses;
		_corner = [_cornerClass, _cornerPos, _rotation] call dro_createSimpleObject;
						
		// Create guards
		_buildingPositions = [_corner] call BIS_fnc_buildingPositions;
		{ 
			_unitChance = (random 100);
			if (_unitChance > 50) then {
				_group = [_x, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
				_unit = ((units _group) select 0);						
				if (!isNil "_unit") then {						
					_unit setFormDir (_rotation-180);
					_unit setDir (_rotation-180);
				};
			};
		} forEach _buildingPositions;
		
		// Corner fortifications
		_cornerFortExtraClasses = ["Land_Razorwire_F", "Land_HBarrier_Big_F"];
		_cornerFortPos1 = [_cornerPos, 5.5, (_dir-45)] call dro_extendPos;
		_cornerFortPos2 = [_cornerPos, 5.5, (_dir+45)] call dro_extendPos;
		
		_cornerFortClass = selectRandom _cornerFortExtraClasses;
		_cornerFortObject1 = [_cornerFortClass, _cornerFortPos1, (_rotation - 90)] call dro_createSimpleObject;
		_cornerFortObject2 = [_cornerFortClass, _cornerFortPos2, (_rotation)] call dro_createSimpleObject;
		
		_dir = _dir + 90;
		_rotation = _rotation + 90;
	};
};

// Populate side points
_sideFortClasses = ["Land_Razorwire_F", "Land_HBarrier_Big_F", "Land_HBarrier_5_F"];
_rotation = (_startDir);
_dir = (_startDir);
for "_i" from 1 to 4 do {
	_sidePos = [_thisPos, 20, _dir] call dro_extendPos;
	_sidePos2 = [_sidePos, 4.5, (_dir+90)] call dro_extendPos;
	_sidePos1 = [_sidePos, 4.5, (_dir-90)] call dro_extendPos;
	_sideClass = selectRandom _sideFortClasses;
	_sideObject1 = [_sideClass, _sidePos1, _rotation] call dro_createSimpleObject;
	_sideObject2 = [_sideClass, _sidePos2, _rotation] call dro_createSimpleObject;
	_dir = _dir + 90;
	_rotation = _rotation + 90;
};		

// Marker
_markerName = format["baseMkr%1", floor(random 10000)];
_markerBase = createMarker [_markerName, _thisPos];
_markerBase setMarkerShape "ICON";
_markerBase setMarkerType "loc_Fortress";		
_markerBase setMarkerSize [3.5, 3.5];			
_markerBase setMarkerColor markerColorEnemy;
_markerBase setMarkerAlpha 0;		

// Create Task						
_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Clear Base";
_taskDesc = format ["Clear the fortified %2 base at the <marker name='%1'>marked location</marker>.", _markerName, enemyFactionName];
_taskType = "attack";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

// Create guards
_spawnPos = [_thisPos, 0, 70, 1, 0, 30, 0] call BIS_fnc_findSafePos;
_minAI = 2;
_maxAI = 4;
if (aiSkill == 2) then {	
	_minAI = 1;
	_maxAI = 2;
};
_spawnedSquad = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;				
if (!isNil "_spawnedSquad") then {	
	[_spawnedSquad, _thisPos, [0, 50], "limited"] execVM "sunday_system\orders\patrolArea.sqf";	
};		
// Create triggers
_trgAreaClear = createTrigger ["EmptyDetector", _thisPos, true];
_trgAreaClear setTriggerArea [100, 100, 0, false];
_trgAreaClear setTriggerActivation ["ANY", "PRESENT", false];
_trgAreaClear setTriggerStatements [
	"
		(({(side _x == (thisTrigger getVariable 'side')) && ((lifeState _x == 'HEALTHY') OR (lifeState _x == 'INJURED'))} count thisList) <= 0)
	",
	"
		[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
		missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];		
	", 
	""];
_trgAreaClear setVariable ["thisTask", _taskName];
_trgAreaClear setVariable ["side", enemySide];		

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