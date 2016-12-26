params ["_target", "_numbers"];
// _target can be marker name string or unit

_min = _numbers select 0;
_max = _numbers select 1;		

private _debug = 0;

// Convert target to center position array if not already
_targetPos = switch (typeName _target) do {
	case "STRING": {getMarkerPos _target};
	case "OBJECT": {getPos _target};
	case "ARRAY": {_target};
};

// Check available reinforcement types
_styles = ["INFANTRY"];

_carTransports = [];
_carNonTransports = [];
_heliTransports = [];

if (count eCarClasses > 0) then {
	{		
		if (((configFile >> "CfgVehicles" >> _x >> "transportSoldier") call BIS_fnc_GetCfgData) >= 4) then {
			_carTransports pushBack _x;
			_styles pushBackUnique "CARTRANSPORT";
		} else {
			//_carNonTransports pushBack _x;
			//_styles pushBackUnique "CAR";
		};
	} forEach eCarClasses;	
};

if (count eHeliClasses > 0 && count AO_flatPositions > 0) then {
	{
		if (((configFile >> "CfgVehicles" >> _x >> "transportSoldier") call BIS_fnc_GetCfgData) >= 4) then {		
			_heliTransports pushBack _x;
			_styles pushBackUnique "HELI";
		};
	} forEach eHeliClasses;
};

_weights = [];
{
	switch (_x) do {
		case "INFANTRY": {_weights pushBack 0.3};
		case "CARTRANSPORT": {_weights pushBack 0.6};
		case "CAR": {_weights pushBack 0.1};
		case "HELI": {_weights pushBack 0.5};
	};
} forEach _styles;

_numReinforcements = [_min, _max] call BIS_fnc_randomInt;

for "_i" from 1 to _numReinforcements do {
			
	diag_log "DRO: Reinforcing";
	
	_reinforceType = [_styles, _weights] call BIS_fnc_selectRandomWeighted;
	//_reinforceType = "HELI";
	if (!isNil "_reinforceType") then {
		switch (_reinforceType) do {
			case "INFANTRY": {
				// Get position data			
				_spawnPos = [_targetPos,900,1100,1,0,100,0] call BIS_fnc_findSafePos;
				
				if ((({(_spawnPos distance _x) < 600} count (units group player)) == 0)) then {
									
					// Debug marker
					if (_debug == 1) then {
						hint "REINFORCING";
						_markerRB = createMarker [format ["rbMkr%1",(random 10000)], _spawnPos];
						_markerRB setMarkerShape "ICON";
						_markerRB setMarkerColor "ColorOrange";
						_markerRB setMarkerType "mil_objective";
					};
					
					// Spawn units
					_minAI = 4;
					_maxAI = 8;
					if (aiSkill == 2) then {	
						_minAI = 3;
						_maxAI = 6;
					};	
					_reinfGroup = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI,_maxAI]] call dro_spawnGroupWeighted;				
					if (!isNil "_reinfGroup") then {							
						[_reinfGroup, _targetPos, [50, 300], "FULL"] execVM "sunday_system\orders\patrolArea.sqf";											
						diag_log format ["REINFORCEMENT: Infantry group %1 spawned at %2",_reinfGroup, _spawnPos];
					};
				};
			};
			
			case "CARTRANSPORT": {
				// Ground type truck
				_initPos = [_targetPos,1500,2000,0,0,30,0] call BIS_fnc_findSafePos;				
				_roadList = [];	
				_spawnPos = [];	
				_roadList = _initPos nearRoads 500;			
			
				if (count _roadList > 0) then {
					_thisRoad = (selectRandom _roadList);
					_spawnPos = getPos _thisRoad;				
				} else {
					_spawnPos = _initPos;
				};
				
				if ((({(_spawnPos distance _x) < 600} count (units group player)) == 0)) then {				
					// Debug marker
					if (_debug == 1) then {
						hint "REINFORCING";
						_markerRB = createMarker [format ["rbMkr%1",(random 10000)], _spawnPos];
						_markerRB setMarkerShape "ICON";
						_markerRB setMarkerColor "ColorOrange";
						_markerRB setMarkerType "mil_objective";
					};				
							
					
					// Spawn vehicle
					_vehType = selectRandom _carTransports;
					_reinfVeh = createVehicle [_vehType, _spawnPos, [], 0, "NONE"];					
					createVehicleCrew _reinfVeh;
					
					// Spawn units
					_maxUnits = ((configFile >> "CfgVehicles" >> _vehType >> "transportSoldier") call BIS_fnc_GetCfgData);
					_minAI = 4;				
					if (aiSkill == 2) then {
						_minAI = 3;	
						if (_maxUnits > 6) then {
							_maxUnits = 6;
						};	
					};
					_reinfGroup = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI,_maxUnits]] call dro_spawnGroupWeighted;				
					if (!isNil "_reinfGroup") then {
						[_reinfGroup, _reinfVeh, true] spawn sun_groupToVehicle;												
						[_reinfVeh, _reinfGroup, _targetPos, true] execVM "sunday_system\orders\insertGroup.sqf";																				
						diag_log format ["REINFORCEMENT: Car transport group %1 spawned at %2; inserting at %3",_reinfGroup, _spawnPos, _targetPos];
					};
				};
			};	
			
			case "CAR": {
				_initPos = [_targetPos,1500,2000,0,0,30,0] call BIS_fnc_findSafePos;
				_roadList = [];	
				_spawnPos = [];	
				_roadList = _initPos nearRoads 500;			
					
				if (count _roadList > 0) then {
					_thisRoad = (selectRandom _roadList);
					_spawnPos = getPos _thisRoad;				
				} else {
					_spawnPos = _initPos;
				};
				if ((({(_spawnPos distance _x) < 600} count (units group player)) == 0)) then {				
					// Debug marker
					if (_debug == 1) then {
						hint "REINFORCING";
						_markerRB = createMarker [format ["rbMkr%1",(random 10000)], _spawnPos];
						_markerRB setMarkerShape "ICON";
						_markerRB setMarkerColor "ColorOrange";
						_markerRB setMarkerType "mil_objective";
					};					
					
					// Spawn vehicle
					_vehType = selectRandom _carNonTransports;
					if (!isNil "_vehType") then {
						_reinfVeh = createVehicle [_vehType, _spawnPos, [], 0, "NONE"];
						createVehicleCrew _reinfVeh;
						[group(driver _reinfVeh), _targetPos, 200] call bis_fnc_taskPatrol;						
						
						diag_log format ["REINFORCEMENT: Car attack group %1 spawned at %2; inserting at %3",_reinfVeh, _spawnPos, _targetPos];
						if (count _styles > 1) then {
							_styles = _styles - ["CAR"];
						};
					};
				};
			};
		
			case "HELI": {
				// Heli type
				_spawnPos = [_targetPos,1000,1500,0,1,100,0] call BIS_fnc_findSafePos;
				
				_insertPos = selectRandom AO_flatPositions;			
				
				_heliInsertType = selectRandom ["LAND", "PARACHUTE"];
				_height = switch (_heliInsertType) do {
					case "LAND": {40};
					case "PARACHUTE": {300};
					default {300};
				};
				_spawnPos set [2,_height];
												
				// Debug marker
				if (_debug == 1) then {
					hint "REINFORCING";
					_markerRB = createMarker [format ["rbMkr%1",(random 10000)], _spawnPos];
					_markerRB setMarkerShape "ICON";
					_markerRB setMarkerColor "ColorOrange";
					_markerRB setMarkerType "mil_objective";
				};
				
				// Spawn vehicle
				_vehType = selectRandom _heliTransports;	
				while {count _vehType == 0} do{
					_vehType = selectRandom _heliTransports;
				};
				_reinfVeh = createVehicle [_vehType, _spawnPos, [], 0, "FLY"];
				_reinfVeh setPos _spawnPos;
				createVehicleCrew _reinfVeh;
				
				// Spawn units
				_maxUnits = ((configFile >> "CfgVehicles" >> _vehType >> "transportSoldier") call BIS_fnc_GetCfgData);
				_minAI = 4;				
				if (aiSkill == 2) then {
					_minAI = 3;	
					if (_maxUnits > 6) then {
						_maxUnits = 6;
					};	
				};
				_reinfGroup = [_spawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [_minAI,_maxUnits]] call dro_spawnGroupWeighted;			
				if (!isNil "_reinfGroup") then {
					[_reinfGroup, _reinfVeh, true] spawn sun_groupToVehicle;					
					[_reinfVeh, _reinfGroup, _insertPos, true, _heliInsertType] execVM "sunday_system\orders\insertGroup.sqf";						
					diag_log format ["REINFORCEMENT: Heli transport group %1 spawned at %2; inserting at %3",_reinfGroup, _spawnPos, _insertPos];
				} else {
					{deleteVehicle _x} forEach crew _reinfVeh;
					deleteVehicle _reinfVeh;
				};
			};
		};		
	};
	
	sleep ([90,120] call BIS_fnc_randomInt);
	
};

