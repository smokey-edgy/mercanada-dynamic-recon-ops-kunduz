// Destroy target

diag_log AO_flatPositions;
_thisPos = selectRandom AO_flatPositions;
AO_flatPositions = AO_flatPositions - [_thisPos];

_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
_thisPos = _tempPos;

// Create objective
_boxType = "";
if (count eAmmoClasses > 0) then {
	_boxType = selectRandom eAmmoClasses;
} else {
	_boxType = "I_supplyCrate_F";
};

// Create marker
_markerName = format["boxMkr%1", floor(random 10000)];
_markerBox = createMarker [_markerName, _thisPos];
_markerBox setMarkerShape "ICON";
_markerBox setMarkerType  "mil_destroy";
//_markerBox setMarkerSize [3, 3];
_markerBox setMarkerColor markerColorEnemy;
_markerBox setMarkerAlpha 0;

// Create Task
_boxName = ((configFile >> "CfgVehicles" >> _boxType >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Destroy Cache";
_taskDesc = format ["Destroy the %1 ammunition cache.", enemyFactionName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
			
_box1 = _boxType createVehicle _thisPos;
_box1 setDir (random 360);
_box2 = _boxType createVehicle _thisPos;
_box2 setDir (random 360);
_box3 = _boxType createVehicle _thisPos;
_box3 setDir (random 360);

// Add destruction event handler
// Create trigger				
_trgComplete = createTrigger ["EmptyDetector", _thisPos, true];
_trgComplete setTriggerArea [0, 0, 0, false];
_trgComplete setTriggerActivation ["ANY", "PRESENT", false];
_trgComplete setTriggerStatements [
	"
		!alive (thisTrigger getVariable 'box1') &&
		!alive (thisTrigger getVariable 'box2') &&			
		!alive (thisTrigger getVariable 'box3') 			
	",
	"				
		[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;	
		missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];		
	", 
	""];
_trgComplete setVariable ["box1", _box1];
_trgComplete setVariable ["box2", _box2];
_trgComplete setVariable ["box3", _box3];
_trgComplete setVariable ["thisTask", _taskName];
						
// Create guards and fortifications
// Populate corner points
_startDir = random 360;	
_cornerFortClasses = ["Land_BagBunker_Small_F"];	

_dir = (_startDir - 45);
_rotation = (_startDir - 180);
for "_i" from 1 to 4 do {
	_popChance = (random 100);
	if (_popChance > 40) then {
		_cornerPos = [_thisPos, 10, _dir] call dro_extendPos;
		if (_popChance > 70) then {
			// Corner bunker							
			_cornerClass = selectRandom _cornerFortClasses;
			_corner = [_cornerClass, _cornerPos, _rotation] call dro_createSimpleObject;
							
			// Create guard							
			_group = [_cornerPos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
			_unit = ((units _group) select 0);
			if (!isNil "_unit") then {
				_unitDir = (_rotation-180);
				_unit setFormDir _unitDir;
				_unit setDir _unitDir;
			};
		};
		// Corner fortifications
		_cornerFortExtraClasses = ["Land_Razorwire_F", "Land_BagFence_Long_F"];
		_cornerFortPos1 = [_cornerPos, 5, (_dir-45)] call dro_extendPos;
		_cornerFortPos2 = [_cornerPos, 5, (_dir+45)] call dro_extendPos;
		
		_cornerFortClass = selectRandom _cornerFortExtraClasses;
		_cornerFortObject1 = [_cornerFortClass, _cornerFortPos1, (_rotation - 90)] call dro_createSimpleObject;
		_cornerFortObject2 = [_cornerFortClass, _cornerFortPos2, (_rotation)] call dro_createSimpleObject;
		
		_dir = _dir + 90;
		_rotation = _rotation + 90;
	};
};
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