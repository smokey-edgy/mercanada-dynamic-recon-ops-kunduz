// Destroy target				
_thisPos = AO_flatPositions select 0;
AO_flatPositions = AO_flatPositions - [_thisPos];

_tempPos = [(_thisPos select 0), (_thisPos select 1), 0];
_thisPos = _tempPos;

// Marker
_markerName = format["mortMkr%1", floor(random 10000)];
_markerMortar = createMarker [_markerName, _thisPos];
_markerMortar setMarkerShape "ICON";
_markerMortar setMarkerType  "o_mortar";
_markerMortar setMarkerColor markerColorEnemy;
_markerMortar setMarkerAlpha 0;
				
// Create objective
_mortarType = selectRandom eMortarClasses;
// Create Task
_mortarName = ((configFile >> "CfgVehicles" >> _mortarType >> "displayName") call BIS_fnc_GetCfgData);

_taskName = format ["task%1", floor(random 100000)];
_taskTitle = "Destroy Mortar Emplacement";
_taskDesc = format ["Destroy the %1 %2s. Mortar emplacement can be found at the <marker name='%3'>marked area</marker>.", enemyFactionName, _mortarName, _markerName];
_taskType = "destroy";
missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];
				
// Create mortar units
_mortPos = [_thisPos, 3, (random 360)] call dro_extendPos;				
_mortar = _mortarType createVehicle _mortPos;				
createVehicleCrew _mortar;				
_mort2Dir = [_mortPos, _thisPos] call BIS_fnc_dirTo;
_mort2Pos = [_thisPos, 3, _mort2Dir] call dro_extendPos;
_mortar2 = _mortarType createVehicle _mort2Pos;				
createVehicleCrew _mortar2;

// Create trigger				
_trgComplete = createTrigger ["EmptyDetector", _thisPos, true];
_trgComplete setTriggerArea [0, 0, 0, false];
_trgComplete setTriggerActivation ["ANY", "PRESENT", false];
_trgComplete setTriggerStatements [
	"
		!alive (thisTrigger getVariable 'mortar1') && !alive (thisTrigger getVariable 'mortar2') 			
	",
	"				
		[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
		missionNamespace setVariable [format ['%1Completed', (thisTrigger getVariable 'thisTask')], 1, true];
	", 
	""];
_trgComplete setVariable ["mortar1", _mortar];
_trgComplete setVariable ["mortar2", _mortar2];
_trgComplete setVariable ["thisTask", _taskName];
						

// Create guards and fortifications
// Populate corner points		
_cornerFortClasses = ["Land_BagBunker_Small_F"];	
_startDir = random 360;	
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
_randItems = [1,3] call BIS_fnc_randomInt;
_itemsArray = [
	"Land_Cargo10_grey_F",
	"Land_Cargo10_military_green_F",					
	"CargoNet_01_box_F",					
	"Land_Pallet_MilBoxes_F"						
];
for "_i" from 1 to _randItems do {
	_itemPos = [_thisPos, 7, 11, 1, 0, 1, 0] call BIS_fnc_findSafePos;
	_thisItem = selectRandom _itemsArray;
	_item = createVehicle [_thisItem, _itemPos, [], 0, "CAN_COLLIDE"];
	_item setDir (random 360);	
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
