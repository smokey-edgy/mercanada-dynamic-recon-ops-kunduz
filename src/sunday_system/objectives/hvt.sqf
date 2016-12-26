private ["_hvtStyles"];
_hvtStyles = _this select 0;

// Get HVT unit
_hvtType = [];
if (count eOfficerClasses > 0) then {
	_hvtType = selectRandom eOfficerClasses;
} else {
	_hvtType = selectRandom eInfClasses;
};		
					
_hvtChar = nil;

_sceneTypes = ["MEETINGS", "FOBS"];
_hvtPos = [];

// Select hiding style
_hvtStyle = selectRandom _hvtStyles;
switch (_hvtStyle) do {
	case "INSIDE": {				
			_building = [AO_buildingPositions] call dro_selectRemove;
			_buildingPlaces = [_building] call BIS_fnc_buildingPositions;
			_thisBuildingPlace = [0,((count _buildingPlaces)-1)] call BIS_fnc_randomInt;
			
			// Create HVT unit
			_hvtChar = createVehicle [_hvtType, getPos _building, [], 0, "NONE"];			
			_hvtChar setPosATL (_building buildingPos _thisBuildingPlace);					
			_hvtPos	= getPos _building;
	};
	case "OUTSIDE": {										
		_hvtPos = AO_flatPositions select 0;
		AO_flatPositions = AO_flatPositions - [_hvtPos];
		
		_tempPos = [(_hvtPos select 0), (_hvtPos select 1), 0];
		_hvtPos = _tempPos;
		
		_sceneType = selectRandom _sceneTypes;
		switch (_sceneType) do {
			case "FOBS": {
				_objectLib = ["FOBS"] call fnc_selectObjects;
				_objects = selectRandom _objectLib;
				_spawnedObjects = [_hvtPos, (random 360), _objects] call BIS_fnc_ObjectsMapper;
				
				{
					if (typeOf _x == "Sign_Arrow_Blue_F") then {								
						_guardGroup = [getPos _x, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
						_guardUnit = ((units _guardGroup) select 0);
						if (!isNil "_guardUnit") then {	
							_guardUnit setFormDir (getDir _x);
							_guardUnit setDir (getDir _x);
						};
						deleteVehicle _x;
					};
				} forEach _spawnedObjects;
				
				// Create HVT unit						
				_hvtSpawnPos = _hvtPos findEmptyPosition [0, 15, _hvtType];
				_hvtChar = createVehicle [_hvtType, _hvtSpawnPos, [], 0, "NONE"];									
				
			};
			case "MEETINGS": {
				// Create HVT unit
				_hvtSpawnPos = _hvtPos findEmptyPosition [0, 15, _hvtType];
				_hvtChar = createVehicle [_hvtType, _hvtSpawnPos, [], 0, "NONE"];				
				_hvtChar setPos _hvtPos;	
			
				_civArray = ["C_man_p_beggar_F", "C_man_1", "C_man_polo_1_F", "C_man_polo_2_F", "C_man_polo_3_F", "C_man_polo_4_F", "C_man_polo_5_F", "C_man_polo_6_F", "C_man_shorts_1_F", "C_man_1_1_F", "C_man_1_2_F", "C_man_1_3_F", "C_man_w_worker_F"];
				_objectLib = ["MEETINGS"] call fnc_selectObjects;
				_objects = selectRandom _objectLib;
				_spawnedObjects = [_hvtPos, (random 360), _objects] call BIS_fnc_ObjectsMapper;
				
				{
					if (typeOf _x == "Sign_Arrow_Blue_F") then {
						_pos = getPos _x;
						_dir = getDir _x;
						deleteVehicle _x;								
						_guardGroup = [_pos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
						_guardUnit = ((units _guardGroup) select 0);
						if (!isNil "_guardUnit") then {
							_guardUnit setFormDir (_dir);
							_guardUnit setDir (_dir);
						};
					};
					if (typeOf _x == "Sign_Arrow_F") then {
						_pos = getPos _x;
						_dir = getDir _x;
						deleteVehicle _x;
						_hvtChar setPos _pos;
						_hvtChar setFormDir _dir;
						_hvtChar setDir _dir;									
					};
					if (typeOf _x == "Sign_Arrow_Yellow_F") then {
						_civType = selectRandom _civArray;
						_pos = getPos _x;
						_dir = getDir _x;
						deleteVehicle _x;
						_spawnedCiv = createVehicle [_civType, _pos, [], 0, "CAN_COLLIDE"];						
						_spawnedCiv setFormDir _dir;
						_spawnedCiv setDir _dir;									
					};
				} forEach _spawnedObjects;						
			};
		};								
	};
};


_hvtChar disableAI "MOVE";
		
// Marker
_markerPos = [_hvtPos, (random 120), (random 360)] call dro_extendPos;
//_markerPos = [_hvtPos, 0, 120, 0, 1, 100, 0] call BIS_fnc_findSafePos;
_markerName = format["hvtMkr%1", floor(random 10000)];		
_hvtMarker = createMarker [_markerName, _markerPos];
_hvtMarker setMarkerShape "ELLIPSE";
_hvtMarker setMarkerBrush "Solid";
_hvtMarker setMarkerColor markerColorEnemy;
_hvtMarker setMarkerSize [150, 150];
_hvtMarker setMarkerAlpha 0;
enemyIntelMarkers pushBack [_hvtMarker, _hvtPos];

// Create Task
_hvtName = ((configFile >> "CfgVehicles" >> _hvtType >> "displayName") call BIS_fnc_GetCfgData);		
_taskName = format ["task%1", floor(random 100000)];
_taskDesc = format ["Eliminate the %1 %2. Target is believed to be in the <marker name='%3'>marked area</marker>. Use caution and do not allow the target to escape.", enemyFactionName, _hvtName, _markerName];
_taskTitle = "Eliminate HVT";		
_taskType = "kill";
_hvtChar setVariable ["thisTask", _taskName];
_hvtChar setVariable ["markerName", _markerName];
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];

// Add killed event handler
_hvtChar addEventHandler ["Killed", {[((_this select 0) getVariable ("thisTask")), "SUCCEEDED", true] spawn BIS_fnc_taskSetState; missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true]; ((_this select 0) getVariable "markerName") setMarkerAlpha 0;}];		

// Spawn patrols
_minAI = 3;
_maxAI = 5;
if (aiSkill == 2) then {	
	_minAI = 2;
	_maxAI = 3;
};		
_spawnedSquad = [_hvtPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI,_maxAI]] call dro_spawnGroupWeighted;								
_allGuards = [];		
if (!isNil "_spawnedSquad") then {
	[_spawnedSquad, _hvtPos, [10, 30], "limited"] execVM "sunday_system\orders\patrolArea.sqf";	
	_allGuards = (units _spawnedSquad);			
};		

// Create fail state		
_trgFlee = createTrigger ["EmptyDetector", _hvtPos, true];
_trgFlee setTriggerArea [200, 200, 0, false];
_trgFlee setTriggerActivation ["ANY", "PRESENT", false];
_trgFlee setTriggerStatements [
	"
		({alive _x} count (thisTrigger getVariable 'allGuards')) < ((count (thisTrigger getVariable 'allGuards')) * 0.5)				
	",
	"				
		(thisTrigger getVariable 'hvt') enableAI 'MOVE';
		(thisTrigger getVariable 'hvt') allowFleeing 1;					
	", 
	""];
_trgFlee setVariable ["allGuards", _allGuards];
_trgFlee setVariable ["hvt", _hvtChar];
		
_trgFail = createTrigger ["EmptyDetector", _hvtPos, true];
_trgFail setTriggerArea [350, 350, 0, false];
_trgFail setTriggerActivation ["ANY", "PRESENT", false];
_trgFail setTriggerStatements [
	"
		(alive (thisTrigger getVariable 'hvt')) && 
		!((thisTrigger getVariable 'hvt') in thisList) && 
		((thisTrigger getVariable 'hvt') distance u1 > 1000)
	",
	"				
		[(thisTrigger getVariable 'thisTask'), 'FAILED', true] spawn BIS_fnc_taskSetState;
		hideObject (thisTrigger getVariable 'hvt');				
	", 
	""];
_trgFail setVariable ["hvt", _hvtChar];
_trgFail setVariable ["thisTask", _taskName];

allObjectives pushBack _taskName;
objData pushBack [
	_taskName,
	_taskDesc,
	_taskTitle,
	_markerName,
	_taskType,
	_hvtPos
];
diag_log format ["DRO: Task created: %1, %2", _taskTitle, _taskName];
diag_log format ["DRO: objData: %1", objData];
diag_log format ["DRO: allObjectives is now %1", allObjectives];
