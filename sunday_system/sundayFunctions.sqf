dro_revealMapIntel = {
	params ["_numReveals", "_revealUnits"];
	
	for "_i" from 1 to _numReveals step 1 do {
		if (_revealUnits) then {
			if ((random 1)>0.4) then {
				for "_j" from 0 to ([1,3] call BIS_fnc_randomInt) step 1 do {
					_unit = (selectRandom allUnits);
					_whileAttempts = 0;
					while {side _unit != enemySide || _whileAttempts < 20} do {
						_unit = (selectRandom allUnits);
						_whileAttempts = _whileAttempts + 1;
					};
					if (side _unit == enemySide) then {
						[(grpNetId call BIS_fnc_groupFromNetId), _unit] remoteExec ["reveal", 0];
						//hint "Revealed a unit";
					};
				};
			};
		} else {
			if (count enemyIntelMarkers > 0) then {
				_thisMarker = [enemyIntelMarkers] call dro_selectRemove;
				diag_log _thisMarker;
				if (typeName _thisMarker == "ARRAY") then {
					_marker = _thisMarker select 0;
					_realPos = _thisMarker select 1;
					_markerSize = getMarkerSize _marker;
					_markerSize set [0, (((_markerSize select 0)-30) max 20)];
					_markerSize set [1, (((_markerSize select 1)-30) max 20)];
					_markerShiftAmount = (_markerSize select 0) min (_markerSize select 1);
					_markerPos = [_realPos, random(_markerShiftAmount-(_markerShiftAmount*0.1)), (random 360)] call dro_extendPos;
					_marker setMarkerPos [(_markerPos select 0), (_markerPos select 1)];
					_marker setMarkerSize _markerSize;
					enemyIntelMarkers pushBack [_marker, _realPos];					
					//hint "Narrowed a search marker";
				} else {	
					_thisMarker setMarkerAlpha 1;					
					//hint "Revealed a marker";					
				};
				
			};
		};		
	};
	publicVariable "enemyIntelMarkers";		
};

sun_groupToVehicle = {
	params ["_group", "_vehicle", "_cargoOnly", "_availableRoles", "_thisUnit"];
	
	if (typeName _group == "GROUP") then {
		_group = units _group;
	};
		
	_commanderPositions = _vehicle emptyPositions "Commander";
	_driverPositions = _vehicle emptyPositions "Driver";	
	_gunnerPositions = _vehicle emptyPositions "Gunner";
	
	if (!isNil "_cargoOnly") then {
		if (_cargoOnly) then {
			_commanderPositions = 0;
			_driverPositions = 0;	
			_gunnerPositions = 0;
		};
	};
	
	_cargoPositions = _vehicle emptyPositions "Cargo";	
	
	{
		_unit = _x;
		
		if (_commanderPositions > 0) then {			
			_unit assignAsCommander _vehicle;
			if (local _unit) then {
				_unit moveInCommander _vehicle;
			} else {
				[_unit, _vehicle] remoteExec ["moveInCommander", _unit];
			};			
			_commanderPositions = _commanderPositions - 1;			
		} else {
			if (_driverPositions > 0) then {			
				_unit assignAsDriver _vehicle;
				if (local _unit) then {
					_unit moveInDriver _vehicle;
				} else {
					[_unit, _vehicle] remoteExec ["moveInDriver", _unit];
				};
				_driverPositions = _driverPositions - 1;			
			} else {
				if (_gunnerPositions > 0) then {			
					_unit assignAsGunner _vehicle;
					if (local _unit) then {
						_unit moveInGunner _vehicle;
					} else {
						[_unit, _vehicle] remoteExec ["moveInGunner", _unit];
					};
					_gunnerPositions = _gunnerPositions - 1;			
				} else {
					if (_cargoPositions > 0) then {			
						_unit assignAsCargo _vehicle;
						if (local _unit) then {
							_unit moveInCargo _vehicle;
						} else {
							[_unit, _vehicle] remoteExec ["moveInCargo", _unit];
						};
						_cargoPositions = _cargoPositions - 1;			
					};
				};
			};
		};		
	} forEach _group;
	
};

sun_moveGroup = {
	params ["_group", "_pos", "_extendArray", "_posParams"];
	
	_extendArray = [];
	{
		_distToLead = (leader _group) distance _x;
		_dirFromLead = [(leader _group), _x] call BIS_fnc_dirTo;
		_extendArray pushBack [_distToLead, _dirFromLead];
	} forEach units _group;
	
	(leader _group) setPos _pos;
	{
		_posParams = _extendArray select _forEachIndex;
		_extendPos = [_pos, (_posParams select 0), (_posParams select 1)] call dro_extendPos;
		_x setPos _extendPos;
	} forEach units _group;
	
};	

sun_defineGrid = {
	params ["_center", "_numPosX", "_numPosY", "_spacing"];	
	_positions = [];
	_totalXSpacing = _spacing * _numPosX;
	_totalYSpacing = _spacing * _numPosY;
	
	_xOrigin = (_center select 0) - (_totalXSpacing/2);
	_yOrigin = (_center select 1) - (_totalYSpacing/2);
	
	_thisX = 0;
	_thisY = 0;
	for "_i" from 0 to (_numPosY - 1) step 1 do {
		for "_j" from 0 to (_numPosX - 1) step 1 do {
			_thisX = _xOrigin + (_spacing * _i);
			_thisY = _yOrigin + (_spacing * _j);			
			_positions pushBack [_thisX, _thisY, 0];
		};
	};
	_positions
	
};

dro_createSimpleObject = {
	params ["_class", "_pos", "_dir", "_object"];
	_pos set [2, 0];
	_object = createVehicle [_class, _pos, [], 0, "CAN_COLLIDE"];	
	//_object = _class createVehicle _pos;
	_object setDir _dir;
	_object setVectorUp (surfaceNormal (getPosATL _object));
	_simpleObject = [_object] call BIS_fnc_replaceWithSimpleObject;	
	_simpleObject
};

sun_removeEnemyNVG = {
	{
		if (side _x != side u1) then {
			_unit = _x;		
			_nvgs = hmd _unit;			
			_unit unassignItem _nvgs;
			_unit removeItem _nvgs;			
			_unit removePrimaryWeaponItem "acc_pointer_IR";   
			_unit addPrimaryWeaponItem "acc_flashlight";
			_unit enableGunLights "forceon";		
		};
	} forEach allunits;
};

sun_getUnitPositionId = {
	private ["_vvn", "_str"];
	_vvn = vehicleVarName (_this select 0);
	(_this select 0) setVehicleVarName "";
	_str = str (_this select 0);
	(_this select 0) setVehicleVarName _vvn;
	parseNumber (_str select [(_str find ":") + 1])
};

sun_avgPos = {
	params ["_positions"];
	_xTotal = 0;
	_yTotal = 0;	
	{	
		_pos = switch (typeName _x) do {
			case "STRING": {getMarkerPos _x};
			case "OBJECT": {getPos _x};
			case "ARRAY": {_x};
			default {_x};
		};
		_xTotal = _xTotal + (_pos select 0);
		_yTotal = _yTotal + (_pos select 1);
	} forEach _positions;
	_numPositions = count _positions;	
	([(_xTotal / _numPositions), (_yTotal / _numPositions), 0])
};

dro_extendPos = {
	//private ["_extendCenter", "_dist", "angle", "_x2", "_y2"];
	//_extendCenter = (_this select 0);
	//_dist = (_this select 1);
	//_angle = (_this select 2);
	_x2 = (((_this select 0) select 0) + ((cos (90-(_this select 2))) * (_this select 1)));
	_y2 = (((_this select 0) select 1) + ((sin (90-(_this select 2))) * (_this select 1)));
	[_x2, _y2, 0]
};

dro_selectRemove = {
	_index = [0, (count (_this select 0)-1)] call BIS_fnc_randomInt;	
	private _return = (_this select 0) select _index;
	(_this select 0) deleteAt _index;
	_return
};

dro_initLobbyCam = {
	private ["_playerPos", "_camLobbyStartPos", "_camLobbyEndPos"];
	_playerPos = [((getPos player) select 0), ((getPos player) select 1), (((getPos player) select 2)+1.2)];
	_camLobbyStartPos = [(getPos player), 5, (getDir player)-35] call dro_extendPos;
	_camLobbyStartPos = [(_camLobbyStartPos select 0), (_camLobbyStartPos select 1), (_camLobbyStartPos select 2)+1];
	camLobby = "camera" camCreate _camLobbyStartPos;
	camLobby cameraEffect ["internal", "BACK"];
	camLobby camSetPos _camLobbyStartPos;
	camLobby camSetTarget _playerPos;
	camLobby camCommit 0;
	cameraEffectEnableHUD false;
	_camLobbyEndPos = [(getPos player), 5, (getDir player)+35] call dro_extendPos;
	_camLobbyEndPos = [(_camLobbyEndPos select 0), (_camLobbyEndPos select 1), (_camLobbyEndPos select 2)+1];
	camLobby camPreparePos _camLobbyEndPos;
	camLobby camPrepareTarget _playerPos;
	camLobby camCommitPrepared 120;
};

dro_hostageRelease = {
	params ["_hostage", "_player"];	
	_hostage setVariable ["hostageBound", false, true];
	[_hostage, "Acts_AidlPsitMstpSsurWnonDnon_out"] remoteExec ["playMoveNow", 0]; 
	[_hostage] joinSilent (group _player);			
	[_hostage, false] remoteExec ["setCaptive", _hostage, true];	
	[_hostage, 'MOVE'] remoteExec ["enableAI", _hostage, true];			
	[(_hostage getVariable 'taskName'), 'SUCCEEDED', true] remoteExec ["BIS_fnc_taskSetState", (leader(group _player)), true];			
	missionNamespace setVariable [format ['%1Completed', ((_this select 0) getVariable 'taskName')], 1, true];	
};

dro_getArtilleryRanges = {
	private ["_turrets", "_vehicleMinRange", "_vehicleMaxRange", "_turretMinRange", "_turretMaxRange"];
	_turrets = [(_this select 0)] call BIS_fnc_getTurrets;
	_vehicleMinRange = 100000;
	_vehicleMaxRange = 0;
	{
		_modesToTest = [];
		_thisTurret = _x;
		_weapons = ((_thisTurret >> "weapons") call BIS_fnc_GetCfgData);	
		{		
			_thisWeapon = _x;		
			_modes = ((configfile >> "CfgWeapons" >> _thisWeapon >> "modes") call BIS_fnc_GetCfgData);		
			{
				_weaponChild = _x;
				_weaponChildName = (configName _x);
				{
					if (_x == _weaponChildName) then {					
						_modesToTest pushBackUnique _weaponChild;
					};
				} forEach _modes;
			} forEach ([(configfile >> "CfgWeapons" >> _thisWeapon), 0, true] call BIS_fnc_returnChildren);
			
		} forEach _weapons;	
		_turretMinRange = 100000;
		_turretMaxRange = 0;
		if (count _modesToTest > 0) then {
			{
				_minRange = ((_x >> "minRange") call BIS_fnc_GetCfgData);
				if (_minRange < _turretMinRange) then {_turretMinRange = _minRange};
				_maxRange = ((_x >> "maxRange") call BIS_fnc_GetCfgData);
				if (_maxRange > _turretMaxRange) then {_turretMaxRange = _maxRange};
			} forEach _modesToTest;	
		};	
		
		if (_turretMinRange < _vehicleMinRange) then {_vehicleMinRange = _turretMinRange};	
		if (_turretMaxRange > _vehicleMaxRange) then {_vehicleMaxRange = _turretMaxRange};
		
	} forEach _turrets;

	[_vehicleMinRange, _vehicleMaxRange]
};

dro_detectPosMP = {
	private ["_taskName", "_taskPosFake"];
	_taskName = _this select 0;
	_taskPosFake = _this select 1;
	
	_aimedPos = screenToWorld [0.5, 0.5];
	if ((alive player) && ((_aimedPos distance _taskPosFake) < 100) && ((((vehicle player) distance _taskPosFake) < 1000) || (((getConnectedUAV player) distance _taskPosFake) < 1000))) then {		
		_currentInspTime = (missionNamespace getVariable _taskName);
		_currentInspTime = _currentInspTime + 1;
		missionNamespace setVariable [_taskName, _currentInspTime, true];
	};
};

dro_heliInsertion = {
	_heli = _this select 0;
	_insertPos = _this select 1;
	_type = _this select 2;
	
	diag_log format ["DRO: Init heli insertion with heli %1 to %2", _heli, _insertPos];
	
	_heliGroup = (group _heli);
	_startPos = [((getPos _heli) select 0), ((getPos _heli) select 1), ((getPos _heli) select 2)];
	_height = getTerrainHeightASL _insertPos; 
	_insertPosHigh = [(_insertPos select 0), (_insertPos select 1), _height+150];
	
	_flyDir = [_startPos, _insertPosHigh] call BIS_fnc_dirTo;
	_flyByPosExtend = [_insertPosHigh, 3000, _flyDir] call dro_extendPos;
	_flyByPos = [(_flyByPosExtend select 0), (_flyByPosExtend select 1), 200];
	
	_heli flyInHeight 200;
	_heliGroup = (group _heli);
	
	_driver = driver _heli;
	_heliGroup setBehaviour "careless";
    _driver disableAI "FSM";
    _driver disableAI "Target";
    _driver disableAI "AutoTarget";
	
	// Clear current waypoints
	while {(count (waypoints _heliGroup)) > 0} do {
		deleteWaypoint ((waypoints _heliGroup) select 0);
	};	
	
	_wp0 = _heliGroup addWaypoint [_startPos, 0];	
	_wp0 setWaypointSpeed "FULL";
	_wp0 setWaypointType "MOVE";	
	_wp0 setWaypointBehaviour "COMBAT";
	
	_wp1 = _heliGroup addWaypoint [_flyByPos, 0];	
	_wp1 setWaypointSpeed "FULL";
	_wp1 setWaypointType "MOVE";	
	
	_trgEject = createTrigger ["EmptyDetector", _insertPosHigh];
	_trgEject setTriggerArea [800, 50, _flyDir, false];
	_trgEject setTriggerActivation ["ANY", "PRESENT", false];
	_trgEject setTriggerStatements ["(thisTrigger getVariable 'heli') in thisList", "[(assignedCargo (thisTrigger getVariable 'heli'))] execVM 'sunday_system\callParadrop.sqf';", ""];
	_trgEject setVariable ["heli", _heli];
	
	_trgDelete = createTrigger ["EmptyDetector", _flyByPos];
	_trgDelete setTriggerArea [100, 100, 0, false];
	_trgDelete setTriggerActivation ["ANY", "PRESENT", false];
	_trgDelete setTriggerStatements ["(thisTrigger getVariable 'heli') in thisList", "deleteVehicle (thisTrigger getVariable 'heli');", ""];
	_trgDelete setVariable ["heli", _heli];
	
	
	diag_log format ["DRO: heli waypoints %1, %2", waypointPosition [_heliGroup, 0], waypointPosition [_heliGroup, 1]];
	
};

dro_spawnGroupWeighted = {	
	_pos = [];
	if (!isNil {(_this select 0)}) then {
		_pos = _this select 0;
	};
	_side = _this select 1;			
	_unitArr = _this select 2;		// Array : [classnames]
	_unitArrWeights = _this select 3;		// Array : [weights]
	_unitNumbers = _this select 4;	// Array : [min units, max units]
	

	if (count _pos > 0) then {	
		
		// Get a random number of units to select between the boundaries
		_minUnits = (_unitNumbers select 0);
		if (_minUnits < 1) then {_minUnits = 1};
		_maxUnits = (_unitNumbers select 1);	
		_limitUnits = [_minUnits, _maxUnits] call BIS_fnc_randomInt;
		
		_unitsToSpawn = [];
		for "_i" from 1 to _limitUnits do {
			_thisUnit = nil;
			if (count _unitArrWeights > 0) then {
				_thisUnit = [_unitArr, _unitArrWeights] call BIS_fnc_selectRandomWeighted;
			} else {
				_thisUnit = selectRandom _unitArr;
			};				
			_unitsToSpawn pushBack _thisUnit;
		};
		
		_group = [_pos, _side, _unitsToSpawn] call BIS_fnc_spawnGroup;
		if (!isNil "aiSkill") then {
			if (aiSkill <= 1) then {
				[_group] call dro_setSkillAction;
			};
		};	
		_group
	};	
};

dro_setSkillAction = {
	switch (aiSkill) do {
		case 0: {
			if (typeName (_this select 0) == "OBJECT") then {
				_unit = (_this select 0);
				_unit setSkill ["aimingAccuracy", random [0.06, 0.07, 0.08]];
				_unit setSkill ["aimingShake", random [0.01, 0.015, 0.02]];
				_unit setSkill ["aimingSpeed", random [0.1, 0.1, 0.15]];
				_unit setSkill ["spotDistance", random [0.6, 0.75, 0.8]];
				_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
				_unit setSkill ["general", random [0.7, 0.75, 0.8]];	
				_unit setSkill ["courage", random [0.1, 0.2, 0.3]];
				_unit setSkill ["reloadSpeed", random [0.1, 0.1, 0.2]];
			};
			if (typeName (_this select 0) == "GROUP") then {		
				{
					_unit = _x;
					_unit setSkill ["aimingAccuracy", random [0.06, 0.07, 0.08]];
					_unit setSkill ["aimingShake", random [0.01, 0.015, 0.02]];
					_unit setSkill ["aimingSpeed", random [0.1, 0.1, 0.15]];
					_unit setSkill ["spotDistance", random [0.6, 0.75, 0.8]];
					_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
					_unit setSkill ["general", random [0.7, 0.75, 0.8]];	
					_unit setSkill ["courage", random [0.1, 0.2, 0.3]];
					_unit setSkill ["reloadSpeed", random [0.1, 0.1, 0.2]];
				} forEach (units (_this select 0));
			};
		};
		case 1: {
			if (typeName (_this select 0) == "OBJECT") then {
				_unit = (_this select 0);
				_unit setSkill ["aimingAccuracy", random [0.15, 0.18, 0.2]];
				_unit setSkill ["aimingShake", random [0.06, 0.08, 0.1]];
				_unit setSkill ["aimingSpeed", random [0.2, 0.2, 0.25]];
				_unit setSkill ["spotDistance", random [0.6, 0.75, 0.8]];
				_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
				_unit setSkill ["general", random [0.7, 0.75, 0.8]];	
				_unit setSkill ["courage", random [0.3, 0.4, 0.5]];
				_unit setSkill ["reloadSpeed", random [0.2, 0.3, 0.3]];
			};
			if (typeName (_this select 0) == "GROUP") then {		
				{
					_unit = _x;
					_unit setSkill ["aimingAccuracy", random [0.15, 0.18, 0.2]];
					_unit setSkill ["aimingShake", random [0.06, 0.08, 0.1]];
					_unit setSkill ["aimingSpeed", random [0.2, 0.2, 0.25]];
					_unit setSkill ["spotDistance", random [0.6, 0.75, 0.8]];
					_unit setSkill ["spotTime", random [0.3, 0.4, 0.5]];
					_unit setSkill ["general", random [0.7, 0.75, 0.8]];	
					_unit setSkill ["courage", random [0.3, 0.4, 0.5]];
					_unit setSkill ["reloadSpeed", random [0.2, 0.3, 0.3]];
				} forEach (units (_this select 0));
			};
		};
	}; 
	
};


sun_addArsenal = {
	(_this select 0) addAction ["Arsenal", "['Open', true] call BIS_fnc_arsenal", nil, 6];
};	

sun_pasteLoadoutAdd = {
	_target = _this select 0;
	
	_actionIndex = _target addAction [
		"Paste Loadout",
		{
			_unit = _this select 1;
			_target = _this select 0;
			
			// Remove current loadout			
			_target removeWeaponGlobal (primaryWeapon _target);
			_target removeWeaponGlobal (secondaryWeapon _target);
			_target removeWeaponGlobal (handgunWeapon _target);
			removeUniform _target;
			removeVest _target;
			removeHeadgear _target;
			removeGoggles _target;
			removeBackpack _target;
			_target unassignItem "NVGoggles";
			_target removeItem "NVGoggles";	
			
			// Paste player's loadout
			_loadoutName = format ["loadout%1", _unit];
			[_unit, [missionNameSpace, _loadoutName]] call BIS_fnc_saveInventory;
			[_target, [missionNameSpace, _loadoutName]] call BIS_fnc_loadInventory;			
		},
		nil,
		1.5,
		false,
		false
	];
	
	// Record this action index for later removal
	_target setVariable ["loadoutAction", _actionIndex];
	
};

sun_pasteLoadoutRemove = {
	_target = _this select 0;
	_actionIndex = _target getVariable "loadoutAction";		
	_target removeAction _actionIndex;
};

sun_moveInCargo = {
	//_unit = _this select 0;
	_vehicle = _this select 0;
	
	player moveInCargo _vehicle;
	
};

sun_playRadioRandom = {
	_radioArray = [		
		"RadioAmbient2",
		"RadioAmbient6",
		"RadioAmbient8"
	];
	playSound [(selectRandom _radioArray), true];
};

sun_setNameMP = {	
	_unit = _this select 0;
	_firstName = _this select 1;
	_lastName = _this select 2;
	_speaker = _this select 3;
	_unit setName [format ["%1 %2", _firstName, _lastName], _firstName, _lastName];
	_unit setNameSound _lastName;
	_unit setSpeaker _speaker;
};

sun_spawnGroup = {
	_pos = [];
	if (!isNil {(_this select 0)}) then {
		_pos = _this select 0;
	};
	_side = _this select 1;			
	_unitArr = _this select 2;		// Array : [classnames]
	_unitNumbers = _this select 3;	// Array : [min units, max units]
	_skill = _this select 4;
	
	if (count _unitArr > 0) then {
		if (count _pos > 0) then {	
			// Get a random number of units to select between the boundaries
			_minUnits = (_unitNumbers select 0);
			_maxUnits = (_unitNumbers select 1);	
			_limitUnits = [_minUnits,_maxUnits] call BIS_fnc_randomInt;
			
			_unitsToSpawn = [];
			for "_i" from 1 to _limitUnits do {
				_thisUnit = selectRandom _unitArr;
				_unitsToSpawn pushBack _thisUnit;
			};
			
			_group = [_pos, _side, _unitsToSpawn] call BIS_fnc_spawnGroup;
			if (!isNil "_skill") then {
				if (_skill == "Militia") then {
					[_group] call dro_setSkillAction;
				};
			};
			_group
		};
	};
};

sun_spawnCfgGroup = {
	_pos = [];
	if (!isNil {(_this select 0)}) then {
		_pos = _this select 0;
	};
	_side = _this select 1;			
	_groupsCfgArr = _this select 2;		// Array : [group classnames]
	_unitNumbers = _this select 3;
	_skill = _this select 4;
	_unitArr = _this select 5;			// Array : [unit classnames] optional, for use if no groups found
	
	_minUnits = (_unitNumbers select 0);
	_maxUnits = (_unitNumbers select 1);	
	
	if (count _groupsCfgArr > 0) then {			
		if (count _pos > 0) then {	
			{		
				if ((count ([_x, 0, true] call BIS_fnc_returnChildren)) > _maxUnits) then {
					_groupsCfgArr = _groupsCfgArr - [_x];
				}
			} forEach _groupsCfgArr;
			
			_thisGroup = selectRandom _groupsCfgArr;
			if (!isNil "_thisGroup") then {
				diag_log "DRO: Spawning group using Cfg data";
				_group = [_pos, _side, _thisGroup, [], [], [], [], [_minUnits, 0.65]] call BIS_fnc_spawnGroup;
				if (_skill == "Militia") then {
					[_group] call dro_setSkillAction;
				};
				_group
			} else {
				if (!isNil "_unitArr") then {
					if (count _unitArr > 0) then {
						diag_log "DRO: Spawning group using array data";
						_group = [_pos, _side, _unitArr, _unitNumbers, _skill] call sun_spawnGroup;
						if (_skill == "Militia") then {
							[_group] call dro_setSkillAction;
						};
						_group
					};
				};
			};
		};
	} else {
		if (!isNil "_unitArr") then {
			if (count _unitArr > 0) then {
				diag_log "DRO: Spawning group using array data";
				_group = [_pos, _side, _unitArr, _unitNumbers, _skill] call sun_spawnGroup;
				if (_skill == "Militia") then {
					[_group] call dro_setSkillAction;
				};
				_group
			};
		};
	};

};

sun_spawnGroupSingleUnit = {
	_pos = [];
	if (!isNil {(_this select 0)}) then {
		_pos = _this select 0;
	};
	_side = _this select 1;			
	_groupsCfgArr = _this select 2;		// Array : [group classnames]
	_skill = _this select 3;
	_unitArr = _this select 4;			// Array : [unit classnames] optional, for use if no groups found
		
	if (count _groupsCfgArr > 0) then {
		if (count _pos > 0) then {		
			_thisUnitClass = selectRandom _groupsCfgArr;
			if (count _thisUnitClass > 0) then {
				_group = createGroup _side;
				_unit = _group createUnit [_thisUnitClass, _pos, [], 0, "NONE"];	
				if (_skill == "Militia") then {
					[_unit] call dro_setSkillAction;
				};			
				_unit
			} else {
				if (isNil "_thisUnitClass") then {
					_thisUnitClass = selectRandom _unitArr;
					_group = createGroup _side;
					_unit = _group createUnit [_thisUnitClass, _pos, [], 0, "NONE"];	
					if (_skill == "Militia") then {
						[_unit] call dro_setSkillAction;
					};
					_unit
				};
			};
		};
	} else {
		if (!isNil "_unitArr") then {
			if (count _unitArr > 0) then {
				_thisUnitClass = selectRandom _unitArr;
				_group = createGroup _side;
				_unit = _group createUnit [_thisUnitClass, _pos, [], 0, "NONE"];	
				if (_skill == "Militia") then {
					[_unit] call dro_setSkillAction;
				};
				_unit
			};
		};
	};
};

sun_addIntel = {
	_intelObject = _this select 0;
	_taskName = _this select 1;
	_intelObject setVariable ["task", _taskName];
	
	
	_intelObject addAction [
		"Collect Intel",
		{
			[_this select 3, 'SUCCEEDED', true] spawn BIS_fnc_taskSetState;
			missionNamespace setVariable [format ["%1Completed", (_this select 3)], 1, true];
			deleteVehicle (_this select 0);
			[([3,5] call BIS_fnc_randomInt), false] call dro_revealMapIntel;
		},
		_taskName,
		6,
		true,
		true		
		
	];
	
};