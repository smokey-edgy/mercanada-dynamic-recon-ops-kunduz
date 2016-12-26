// *****
// SETUP ENEMIES
// *****

fnc_selectObjects = compile preprocessFile "sunday_system\objectsLibrary.sqf";

_debug = 0;

_numPlayers = count allPlayers;

_aiSkill = "";
if (aiSkill == 0) then {_aiSkill = "Militia"};

enemyAlertableGroups = [];
enemySemiAlertableGroups = [];

{
	[_x] call dro_spawnEnemyCamp;
} forEach (AO_TypeData select 0);


// Roadblocks
_numRoadblocks = [2,3] call BIS_fnc_randomInt;
if (aiSkill == 2) then {	
	_numRoadblocks = [1,2] call BIS_fnc_randomInt;
};
switch aoOptionSelect do {
	case 1: {_numRoadblocks = _numRoadblocks - 1};
	case 3: {_numRoadblocks = _numRoadblocks + 1};
};

for "_x" from 1 to _numRoadblocks do {
	if (count roadblockPosArray > 0) then {
		_roadPosition = [roadblockPosArray] call dro_selectRemove; 
		
		// Get road direction
		_roadList = _roadPosition nearRoads 50;
		_thisRoad = _roadList select 0;
		_roadConnectedTo = roadsConnectedTo _thisRoad;
		if (count _roadConnectedTo == 0) exitWith {_bunker = "Land_BagBunker_Small_F" createVehicle _roadPosition;};
		_connectedRoad = _roadConnectedTo select 0;
		_direction = [_thisRoad, _connectedRoad] call BIS_fnc_DirTo;
				
		_objectLib = ["ROADBLOCKS"] call fnc_selectObjects;
		_objects = selectRandom _objectLib;
		_spawnedObjects = [_roadPosition, _direction, _objects] call BIS_fnc_ObjectsMapper;
		
		// Collect guard positions
		_guardPositions = [];		
		{
			if (typeOf _x == "Sign_Arrow_Blue_F") then {
				_spawnPos = getPos _x;
				_dir = getDir _x;				
				_guardPositions pushBack [_spawnPos, _dir];				
				deleteVehicle _x;			
			};
		} forEach _spawnedObjects;
		
		// Spawn guards at guard positions
		_leader = nil;
		_leaderChosen = 0;
		_totalRoadInf = 6;
		if (aiSkill == 2) then {_totalRoadInf = 3};
		_roadInfCount = 0;
		{
			_spawnPos = (_x select 0) findEmptyPosition [0,10];
			if (count _spawnPos > 0) then {
				if (_roadInfCount < _totalRoadInf) then {
					_group = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;				
					if (!isNil "_group") then {
						_guardUnit = ((units _group) select 0);
						_guardUnit setFormDir (_x select 1);
						_guardUnit setDir (_x select 1);
						
						if (_leaderChosen == 0) then {
							_leader = _guardUnit;
							_leaderChosen = 1;
						} else {
							[_guardUnit] joinSilent _leader;
							doStop _guardUnit;
						};
					};
				};
			};
		} forEach _guardPositions;	
		
		if (count eStaticClasses > 0) then {
			if ((random 1) > 0.6) then {
				_turretClass = selectRandom eStaticClasses;
				_turretPos = _roadPosition findEmptyPosition [0, 16, _turretClass];
				if (count _turretPos > 0) then {
					_turret = _turretClass createVehicle _turretPos;
					createVehicleCrew _turret;
				};
			};
		};
		
		// Create Marker
		_markerName = format["roadblockMkr%1", floor(random 10000)];
		_markerRoadblock = createMarker [_markerName, _roadPosition];			
		_markerRoadblock setMarkerShape "ICON";
		_markerRoadblock setMarkerType "hd_warning";
		_markerRoadblock setMarkerText "Checkpoint";		
		_markerRoadblock setMarkerColor markerColorEnemy;
		_markerRoadblock setMarkerAlpha 0;
		enemyIntelMarkers pushBack _markerRoadblock;
				
	};
};

// Generate building garrisons
[] call dro_localBuildingPatrol;

{
	_chance = (random 1);
	if (_chance > 0.3) then {
		[_x, 1] call dro_spawnEnemyGarrison;
	};
} forEach milBuildings;


/*
_numBuildings = count AO_buildingPositions;

_percentToFill = 0.15;
if (_numBuildings < 6) then {_percentToFill = 0.4};

_numHousesToFill = _numBuildings * _percentToFill;

if (_numHousesToFill > 7) then {_numHousesToFill = 7};

_numHousesToFill = _numHousesToFill + (_numPlayers*2);
switch aoOptionSelect do {
	case 1: {if (_numHousesToFill > 1) then {_numHousesToFill = _numHousesToFill - 1}};
	case 3: {_numHousesToFill = _numHousesToFill + 1};
};

if (aiSkill == 2) then {	
	if (_numHousesToFill > 3) then {
		_numHousesToFill = 3;
	};
};

for "_i" from 1 to _numHousesToFill do {
	
	if (count AO_buildingPositions > 0) then {
		[] call dro_spawnEnemyGarrison;
	};
};
*/
// Infantry patrols
_numInf = [3,4] call BIS_fnc_randomInt;
if (aiSkill == 2) then {
	_numInf = [1,2] call BIS_fnc_randomInt;
};
_numInf = _numInf + (floor(_numPlayers/2));
switch aoOptionSelect do {
	case 1: {_numInf = _numInf - 1};
	case 3: {_numInf = _numInf + 1};
};

for "_infIndex" from 1 to _numInf do {
	_infPosition = [];
	if (_infIndex <= 1) then {_infPosition = selectRandom AO_groundPosClose} else {_infPosition = selectRandom AO_groundPosFar};	
	_spawnedSquad = nil;
	_spawnedSquad = [_infPosition, enemySide, eInfClassesForWeights, eInfClassWeights, [2,3]] call dro_spawnGroupWeighted;				
	if (!isNil "_spawnedSquad") then {
		[_spawnedSquad, _infPosition, 200] call bis_fnc_taskPatrol;	
		enemyAlertableGroups pushBack _spawnedSquad;		
	};
};

// Bunkers
_numBunkers = [1,2] call BIS_fnc_randomInt;

for "_x" from 1 to _numBunkers do {	
	if (count AO_flatPositionsFar > 0) then {		
		[] call dro_spawnEnemyBunker;		
	};
};

// Vehicle patrol
if (count eCarClasses > 0) then {
	_vehRand = (random 100);
	if (_vehRand > 60) then {
		_vehPos = [AO_roadPosArray] call dro_selectRemove;
		_numVeh = [1,2] call BIS_fnc_randomInt;
		for "_x" from 1 to _numVeh do {
			_vehType = selectRandom eCarClasses;
			_veh = createVehicle [_vehType, _vehPos, [], 0, "NONE"];
			createVehicleCrew _veh;
			[(group(driver _veh)), _vehPos, 800] call BIS_fnc_taskPatrol;		
			_vehPos = selectRandom AO_roadPosArray;
		};	
	};
};

	
publicVariable "enemyIntelMarkers";