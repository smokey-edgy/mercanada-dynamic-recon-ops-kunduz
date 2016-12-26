fnc_reinforceFriendly = compile preprocessFile "sunday_system\reinforceFriendly.sqf";

_taskList = ["HVT", "VEHICLE", "DEFEND"];
_selectedTask = selectRandom _taskList;
//_selectedTask = "VEHICLE";
switch (_selectedTask) do {
	case "HVT": {
		// Find start position
		_hvtSpawnPos = [centerPos, (aoSize/1.5), (aoSize/1.2), 2, 0, 0, 0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		if (_hvtSpawnPos isEqualTo [0,0,0]) exitWith {
			diag_log "DRO: Reactive HVT position not available";
		};
		// Get HVT unit
		_hvtType = [];
		if (count eOfficerClasses > 0) then {
			_hvtType = selectRandom eOfficerClasses;
		} else {
			_hvtType = selectRandom eInfClasses;
		};	
		_hvtChar = createVehicle [_hvtType, _hvtSpawnPos, [], 0, "NONE"];		
		_leadSquad = [_hvtSpawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [1,3]] call dro_spawnGroupWeighted;
		_rearSquad = [_hvtSpawnPos, enemySide, eInfClassesForWeights, eInfClassWeights, [2,3]] call dro_spawnGroupWeighted;
		
		(units _hvtGroup) joinSilent _leadSquad;
		(units _rearSquad) joinSilent _leadSquad;
		
		_wp0 = _leadSquad addWaypoint [_hvtSpawnPos, 0];
		_wp0 setWaypointBehaviour "SAFE";
		_wp0 setWaypointCombatMode "GREEN";
		_wp0 setWaypointSpeed "LIMITED";
		
		_wp1 = _leadSquad addWaypoint [centerPos, 300];		
				
		_arrowMarkerName = format["reactMkr%1", floor(random 10000)];		
		_arrowMarker = createMarker [_arrowMarkerName, _hvtSpawnPos];
		_arrowMarker setMarkerShape "ICON";		
		_arrowMarker setMarkerType "mil_arrow2";
		_arrowMarker setMarkerSize [2,2];
		_arrowMarker setMarkerAlpha 0.5;
		_arrowMarker setMarkerColor markerColorEnemy;
		_arrowMarker setMarkerDir ([_hvtSpawnPos, centerPos] call BIS_fnc_dirTo);
					
		_hvtName = ((configFile >> "CfgVehicles" >> _hvtType >> "displayName") call BIS_fnc_GetCfgData);		
		_taskName = format ["task%1", floor(random 100000)];
		_taskDesc = format ["We have reports that a %1 %2 is entering the AO from the <marker name='%3'>marked direction</marker>. Eliminate him before you extract.", enemyFactionName, _hvtName];
		_taskTitle = "Eliminate HVT";
		_taskType = "target";
		_hvtChar setVariable ["thisTask", _taskName, true];		
		missionNamespace setVariable [format ["%1Completed", _taskName], 0, true];		
		
		_id = [_taskName, true, [_taskDesc, _taskTitle, ""], _hvtSpawnPos, "CREATED", 10, true, true, _taskType, true] call BIS_fnc_setTask;
		
		[_hvtChar, _id] execVM "sunday_system\objectives\followingMarker.sqf";
		
		//[(group u1), _taskName, [_taskDesc, _taskTitle, ""], _hvtSpawnPos, "CREATED", 10, true, _taskType, false] call BIS_fnc_taskCreate;
		
		// Add killed event handler
		_hvtChar addEventHandler ["Killed", {[((_this select 0) getVariable ("thisTask")), "SUCCEEDED", true] spawn BIS_fnc_taskSetState; missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];}];		
		
		_radioDesc = format ["We have reports that a %1 %2 is entering the AO. Eliminate him before you extract.", enemyFactionName, _hvtName];
		[[], "sun_playRadioRandom", true] call BIS_fnc_MP;		
		[[[playersSide, "HQ"], _radioDesc], "sideChat", true] call BIS_fnc_MP;
		
		taskIDs pushBack _id;
		diag_log ["DRO: taskIDs is now: %1", taskIDs];
		[centerPos, _taskName] execVM "sunday_system\objectives\addTaskExtras.sqf";
	};
	case "VEHICLE": {
		if (count eCarClasses > 0) then {
			// Find start position
			_roads = centerPos nearRoads (aoSize/4);
			
			_allRoads = [];
			
			_rotDir = 0;
			for "_i" from 1 to 4 do {
				_rotPos = [centerPos, (aoSize/1.3), _rotDir] call dro_extendPos;
				_roads = _rotPos nearRoads 500;
				_allRoads = _allRoads + _roads;
				_rotDir = _rotDir + 90;
			};
			
			_vehSpawnPos = [];
			if (count _allRoads > 0) then {
				_vehSpawnPos = (getPos (selectRandom _allRoads));
			} else {		
				_vehSpawnPos = [centerPos, (aoSize/1.5), (aoSize/1.2), 2, 0, 0, 0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
				if (_vehSpawnPos isEqualTo [0,0,0]) exitWith {
					diag_log "DRO: Reactive vehicle position not available";
				};
			};
			
			_vehicleType = selectRandom eCarClasses;
			_thisVeh = createVehicle [_vehicleType, _vehSpawnPos, [], 0, "NONE"];			
			createVehicleCrew _thisVeh;
			
			_nearRoads = _thisVeh nearRoads 50;
			_dir = 0;
			if (count _nearRoads > 0) then {
				_firstRoad = _nearRoads select 0;
				if (count (roadsConnectedTo _firstRoad) > 0) then {			
					_connectedRoad = ((roadsConnectedTo _firstRoad) select 0);
					_dir = [_firstRoad, _connectedRoad] call BIS_fnc_dirTo;
					_thisVeh setDir _dir;
				} else {
					_thisVeh setDir (random 360);
				};
			};
			
			_wp0 = (group _thisVeh) addWaypoint [_vehSpawnPos, 0];
			_wp0 setWaypointBehaviour "SAFE";
			_wp0 setWaypointCombatMode "GREEN";
			_wp0 setWaypointSpeed "LIMITED";
			
			if (count AO_roadPosArray > 0) then {
				_wp1 = (group _thisVeh) addWaypoint [(selectRandom AO_roadPosArray), 0];	
			} else {		
				_wp1 = (group _thisVeh) addWaypoint [centerPos, 300];	
			};
			
			_arrowMarkerName = format["reactMkr%1", floor(random 10000)];		
			_arrowMarker = createMarker [_arrowMarkerName, _vehSpawnPos];
			_arrowMarker setMarkerShape "ICON";
			_arrowMarker setMarkerType "mil_arrow2";
			_arrowMarker setMarkerSize [2,2];
			_arrowMarker setMarkerAlpha 0.5;
			_arrowMarker setMarkerColor markerColorEnemy;
			_arrowMarker setMarkerDir ([_vehSpawnPos, centerPos] call BIS_fnc_dirTo);
			
			_vehicleName = ((configFile >> "CfgVehicles" >> _vehicleType >> "displayName") call BIS_fnc_GetCfgData);		
			_taskName = format ["task%1", floor(random 100000)];
			_taskDesc = format ["We have reports that a %1 %2 is entering the AO from the <marker name='%3'>marked direction</marker>. The %2 is carrying important cargo and must be destroyed before extraction.", enemyFactionName, _vehicleName, _arrowMarkerName];
			_taskTitle = "Destroy vehicle";		
			_taskType = "destroy";			
			
			_id = [_taskName, true, [_taskDesc, _taskTitle, ""], _vehSpawnPos, "CREATED", 10, true, true, _taskType, true] call BIS_fnc_setTask;
			
			[_thisVeh, _id] execVM "sunday_system\objectives\followingMarker.sqf";
			
			//[(group u1), _taskName, [_taskDesc, _taskTitle, ""], _vehSpawnPos, "CREATED", 10, true, _taskType, false] call BIS_fnc_taskCreate;
			
			
			_thisVeh setVariable ["thisTask", _taskName, true];

			// Add destruction event handler
			_thisVeh addEventHandler ["Killed", {
				[((_this select 0) getVariable ("thisTask")), "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
				missionNamespace setVariable [format ["%1Completed", ((_this select 0) getVariable ("thisTask"))], 1, true];
			} ];
			
			_radioDesc = format ["We have reports that a %1 %2 is entering the AO. The %2 is carrying important cargo and must be destroyed before extraction.", enemyFactionName, _vehicleName];
			[[], "sun_playRadioRandom", true] call BIS_fnc_MP;			
			[[[playersSide, "HQ"], _radioDesc], "sideChat", true] call BIS_fnc_MP;
			
			taskIDs pushBack _id;
			diag_log ["DRO: taskIDs is now: %1", taskIDs];
			[centerPos, _taskName] execVM "sunday_system\objectives\addTaskExtras.sqf";
		};
	};
	case "DEFEND": {
		
		_spawnPos = [centerPos, (aoSize/1.5), (aoSize/1.2), 2, 0, 0, 0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		if (_spawnPos isEqualTo [0,0,0]) exitWith {
			diag_log "DRO: Reactive HVT position not available";
		};
		
		_taskPos = [];		
		if (count AO_buildingPositions > 0) then {
			_taskPos = selectRandom AO_buildingPositions;
		} else {
			if (count AO_forestPositions > 0) then {
				_taskPos = selectRandom AO_forestPositions;
			} else {
				_taskPos = [centerPos, 0, (aoSize/4), 0, 1, 0.5, 0] call BIS_fnc_findSafePos;
			};			
		};
		
		//_spawnedSquad = [_spawnPos, playersSide, pInfClassesForWeights, pInfClassWeights, [8,12]] call dro_spawnGroupWeighted;
		
		_spawnedSquad = [_taskPos, [1,1]] call fnc_reinforceFriendly;
		
		if (isNil "_spawnedSquad") exitWith {};
		
		diag_log _spawnedSquad;
		/*
		_wp0 = _spawnedSquad addWaypoint [_spawnPos, 0];
		_wp0 setWaypointBehaviour "AWARE";
		_wp0 setWaypointCombatMode "GREEN";
		_wp0 setWaypointSpeed "FULL";		
		_wp0 setWaypointFormation "DIAMOND";		
		*/
		//_wp1 = _spawnedSquad addWaypoint [_taskPos, 0];				
	
		_arrowMarkerName = format["reactMkr%1", floor(random 10000)];
		_arrowMarkerPos = [_spawnPos, _taskPos] call sun_avgPos;		
		_arrowMarker = createMarker [_arrowMarkerName, _arrowMarkerPos];
		_arrowMarker setMarkerShape "ICON";
		_arrowMarker setMarkerType "mil_arrow2";
		_arrowMarker setMarkerSize [1.5, 1.5];
		_arrowMarker setMarkerAlpha 0.5;
		_arrowMarker setMarkerColor markerColorPlayers;
		_arrowMarker setMarkerDir ([_spawnPos, _taskPos] call BIS_fnc_dirTo);
		
		_defendMarkerName = format["reactMkr%1", floor(random 10000)];		
		_defendMarker = createMarker [_defendMarkerName, _taskPos];
		_defendMarker setMarkerShape "ICON";
		_defendMarker setMarkerType "mil_circle";
		_defendMarker setMarkerSize [1.5, 1.5];
		//_defendMarker setMarkerAlpha 0.7;
		_defendMarker setMarkerColor markerColorPlayers;
		
		sleep 2;
		
		_insertVehicle = vehicle (leader _spawnedSquad);
		_insertVehicleName = "";
		if (_insertVehicle != (leader _spawnedSquad)) then {
			_insertVehicleName = ((configFile >> "CfgVehicles" >> (typeOf _insertVehicle) >> "displayName") call BIS_fnc_GetCfgData);
		};
		diag_log _insertVehicleName;
		
		_taskName = format ["task%1", floor(random 100000)];
		_taskDesc = "";
		_taskTitle = "";
		if (count _insertVehicleName > 0) then {
			_taskTitle = "Defend";
			_taskDesc = format ["HQ is sending a friendly force to secure the AO inserted via %2. Defend the <marker name='%1'>marked position</marker> while they arrive.", _arrowMarkerName, _insertVehicleName];
		} else {
			_taskTitle = "Escort";
			_taskDesc = format ["HQ is sending a friendly force to secure the AO by foot. Escort them to the <marker name='%1'>marked position</marker>.", _arrowMarkerName];
		};			
		_taskType = "defend";			
		
		_id = [_taskName, true, [_taskDesc, _taskTitle, ""], (leader _spawnedSquad), "CREATED", 10, true, true, _taskType, true] call BIS_fnc_setTask;
		
		//[(group u1), _taskName, [_taskDesc, _taskTitle, ""], (leader _spawnedSquad), "CREATED", 10, true, _taskType, false] call BIS_fnc_taskCreate;		
		
		
		// Create triggers		
		_trgFail = createTrigger ["EmptyDetector", _taskPos, true];
		_trgFail setTriggerArea [0, 0, 0, false];
		_trgFail setTriggerActivation ["ANY", "PRESENT", false];
		_trgFail setTriggerStatements [
			"					
				(({(alive _x)} count units (thisTrigger getVariable 'group')) <= 0)
			",
			"				
				(getPos thisTrigger), (thisTrigger getVariable 'markerName') setMarkerAlpha 0;
				[(thisTrigger getVariable 'thisTask'), 'FAILED', true] spawn BIS_fnc_taskSetState;				
			", 
			""];					
		_trgFail setVariable ["group", _spawnedSquad];	
		_trgFail setVariable ["markerName", _defendMarkerName];	
		_trgFail setVariable ["thisTask", _taskName];	
		
		_trgOccupied = createTrigger ["EmptyDetector", _taskPos, true];
		_trgOccupied setTriggerArea [150, 150, 0, false];
		_trgOccupied setTriggerActivation ["ANY", "PRESENT", false];
		_trgOccupied setTriggerStatements [
			"					
				(({(group _x == (thisTrigger getVariable 'group'))} count thisList) > 0)
			",
			"				
				deleteVehicle (thisTrigger getVariable 'trgFail');
				(getPos thisTrigger), (thisTrigger getVariable 'markerName') setMarkerAlpha 0;
				[(thisTrigger getVariable 'thisTask'), 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;				
			", 
			""];			
		_trgOccupied setTriggerTimeout [10, 12, 15, true];
		_trgOccupied setVariable ["group", _spawnedSquad];	
		_trgOccupied setVariable ["markerName", _defendMarkerName];	
		_trgOccupied setVariable ["thisTask", _taskName];			
		_trgOccupied setVariable ["trgFail", _trgFail];			
		
		_radioDesc = "HQ is sending a friendly force to secure the AO, check tasks for info.";
		[[], "sun_playRadioRandom", true] call BIS_fnc_MP;			
		[[[playersSide, "HQ"], _radioDesc], "sideChat", true] call BIS_fnc_MP;		
		
		taskIDs pushBack _id;
		diag_log ["DRO: taskIDs is now: %1", taskIDs];
		[centerPos, _taskName] execVM "sunday_system\objectives\addTaskExtras.sqf";
	};
};