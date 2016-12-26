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
if (count AO_TypeData > 0) then {
	
	for "_k" from 1 to 6 do {
		_markerName = format["barrierMkr%1", _k];
		_markerName setMarkerColor markerColorEnemy;
	};
	{
		_buildingPosition = (_x buildingPos 1);
		_group = [_buildingPosition, enemySide, eInfClassesForWeights, eInfClassWeights, [1,1]] call dro_spawnGroupWeighted;
		if (!isNil "_group") then {
			_unit = ((units _group) select 0);
			_unit setFormDir ((getDir _x)+180);
			_unit setDir ((getDir _x)+180);	
		};
	} forEach AO_TypeData;

	// Barrier patrols
	_numBarrierInf = [2,3] call BIS_fnc_randomInt;
	_numBarrierInf = _numBarrierInf + (ceil(_numPlayers/2));
	
	switch aoOptionSelect do {
		case 1: {_numBarrierInf = _numBarrierInf - 1};
		case 3: {_numBarrierInf = _numBarrierInf + 1};
	};

	if (aiSkill == 2) then {	
		if (_numBarrierInf > 2) then {
			_numBarrierInf = 2;
		};
	};
	
	_guardPostArray = AO_TypeData;
	for "_infIndex" from 1 to _numBarrierInf do {
				
		_maxIndex = 0;	
		if ((count _guardPostArray) == 1) then {
			if (!isNil "_spawnedSquad") then {
				_infBarrierSpawnPos = getPos(_guardPostArray select _select);	
				_spawnedSquad = nil;
				_minAI = 3;
				_maxAI = 6;
				if (aiSkill == 2) then {	
					_minAI = 2;
					_maxAI = 4;
				};
				_spawnedSquad = [_infBarrierSpawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;				
				if (!isNil "_spawnedSquad") then {
					[_spawnedSquad, _infBarrierSpawnPos, 50] call BIS_fnc_taskPatrol;
					enemyAlertableGroups pushBack _spawnedSquad;
				};
			};
		} else {
			_maxIndex = ((count _guardPostArray)-1);
			_select = 0;
			
			_select = (floor(random(count _guardPostArray)));
			if (_select == _maxIndex) then {_select = _maxIndex - 1};
				
			_infBarrierSpawnPos = getPos(_guardPostArray select _select);	
			_spawnedSquad = nil;
			_minAI = 3;
			_maxAI = 6;
			if (aiSkill == 2) then {	
				_minAI = 2;
				_maxAI = 3;
			};
			_spawnedSquad = [_infBarrierSpawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI, _maxAI]] call dro_spawnGroupWeighted;	
			if (!isNil "_spawnedSquad") then {				
				_wp0 = _spawnedSquad addWaypoint[_infBarrierSpawnPos, 10];
				_wp0 setWaypointBehaviour "SAFE";
				_wp0 setWaypointSpeed "LIMITED";
				_wp0 setWaypointType "MOVE";
				_wp0 setWaypointTimeout [5, 10, 6];
				
				_select2 = _select + 1;
				_nextPos = getPos(_guardPostArray select _select2);	
				_wp1 = _spawnedSquad addWaypoint[_nextPos, 10];
				_wp1 setWaypointTimeout [5, 10, 6];
				_wp1 setWaypointType "MOVE";
				
				_wp2 = _spawnedSquad addWaypoint[_nextPos, 10];				
				_wp2 setWaypointType "CYCLE";		

				enemyAlertableGroups pushBack _spawnedSquad;		
			};		
		};		
	};
};

// Roadblocks
_numRoadblocks = [3,4] call BIS_fnc_randomInt;
switch aoOptionSelect do {
	case 1: {_numRoadblocks = _numRoadblocks - 1};
	case 3: {_numRoadblocks = _numRoadblocks + 1};
};
if (aiSkill == 2) then {	
	if (_numRoadblocks > 2) then {
		_numRoadblocks = 2;
	};
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
_numInf = [1,2] call BIS_fnc_randomInt;
if (aiSkill == 2) then {	
	_numInf = [0,1] call BIS_fnc_randomInt;
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