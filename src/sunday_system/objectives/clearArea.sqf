// Find suitable posision
_posArr = [];
_thisPos = [];
if (count AO_flatPositions > 0) then {
	_posArr pushBack "AO_flatPositions";
};
if (count AO_forestPositions > 0) then {
	_posArr pushBack "AO_forestPositions";
};
_posSelect = selectRandom _posArr;
switch (_posSelect) do {
	case "AO_flatPositions": {
		_thisPos = AO_flatPositions select 0;
		AO_flatPositions = AO_flatPositions - [_thisPos];
	};
	case "AO_forestPositions": {
		_thisPos = AO_forestPositions select 0;
		AO_forestPositions = AO_forestPositions - [_thisPos];
	};
};

_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
_thisPos = _tempPos;	

// Create area marker
_markerName = format["areaMkr%1", floor(random 10000)];
_markerArea = createMarker [_markerName, _thisPos];
_markerArea setMarkerShape "ELLIPSE";
_markerArea setMarkerBrush "Solid";
_markerArea setMarkerColor markerColorEnemy;
_markerArea setMarkerSize [150, 150];
_markerArea setMarkerAlpha 0;
		
// Create guards
//_spawnPos = [_thisPos, 0, 100, 1, 0, 30, 0] call BIS_fnc_findSafePos;
_minAI = 2;
_maxAI = 4;
if (aiSkill == 2) then {	
	_minAI = 2;
	_maxAI = 2;
};
_spawnedSquad = [_thisPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;				
if (!isNil "_spawnedSquad") then {
	diag_log "spawned";
	[_spawnedSquad, _thisPos, [0, 120], "LIMITED"] execVM "sunday_system\orders\patrolArea.sqf";			
};

_minAI = 2;
_maxAI = 4;
if (aiSkill == 2) then {	
	_minAI = 2;
	_maxAI = 2;
};
_spawnedSquad2 = [_thisPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;			
if (!isNil "_spawnedSquad2") then {
	diag_log "spawned";
	[_spawnedSquad, _thisPos, [0, 120], "LIMITED"] execVM "sunday_system\orders\patrolArea.sqf";
};
// Create Task
_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Clear Area";
_taskDesc = format ["Clear <marker name='%1'>marked area</marker> held by %2 troops.", _markerName, enemyFactionName];
_taskType = "attack";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
	
// Create triggers
_trgAreaClear = createTrigger ["EmptyDetector", _thisPos, true];
_trgAreaClear setTriggerArea [150, 150, 0, false];
_trgAreaClear setTriggerActivation ["ANY", "PRESENT", false];
_trgAreaClear setTriggerStatements [
	"
			
		(({(side _x == (thisTrigger getVariable 'side')) && ((lifeState _x == 'HEALTHY') OR (lifeState _x == 'INJURED'))} count thisList) <= 0)
	",
	"				
		(thisTrigger getVariable 'markerName') setMarkerAlpha 0;
		[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
		missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];
	", 
	""];			
_trgAreaClear setTriggerTimeout [5, 8, 10, true];
_trgAreaClear setVariable ["side", enemySide];	
_trgAreaClear setVariable ["markerName", _markerName];	
_trgAreaClear setVariable ["thisTask", _taskName];	

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