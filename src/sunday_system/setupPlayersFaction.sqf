// *****
// SETUP PLAYER START
// *****

fnc_selectObjects = compile preprocessFile "sunday_system\objectsLibrary.sqf";

private _center = getPos trgAOC;
_playerGroup = (units(group u1));

{
	if (isObjectHidden _x) then {		
		deleteVehicle _x;
		diag_log format ["DRO: Deleting unit %1", _x];
	};
} forEach _playerGroup;
diag_log _playerGroup;

if (isMultiplayer) then {
	/*
	if ((paramsArray select 0) == 2) then {
		{
			[_x, 3, true] call BIS_fnc_respawnTickets;
		} forEach (units (group u1));	
	};
	*/
	//if ((paramsArray select 0) == 0) then {	
		{
			_x setVariable ["respawnLoadout", (getUnitLoadout _x), true];
			_x setVariable ["respawnPWeapon", [(primaryWeapon  _x), primaryWeaponItems _x], true];
		} forEach (units (group u1));
	//};
};

if (insertType == 0) then {
	insertType = [1,2] call BIS_fnc_randomInt;		
};

_customStart = false;
_randomStartingLocation = [];
_forceSeaStart = 0;
if (count customPos == 0) then {
	diag_log "No custom start position found, will generate random.";
	_randomStartingLocation = [];
} else {
	diag_log "Custom start position found.";
	_randomStartingLocation = customPos;
	if (surfaceIsWater _randomStartingLocation) then {
		_forceSeaStart = 1;
	};
	_customStart = true;
};

_seaSpawnReal = [];
_airStartPos = [];

// Random resupply
_ResupplyOnePos = [_center, 0, 500, 2, 0, 0.4, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
if !(_ResupplyOnePos isEqualTo [0,0,0]) then {
	_resupply = "B_supplyCrate_F" createVehicle _ResupplyOnePos;

	clearWeaponCargoGlobal _resupply;
	clearMagazineCargoGlobal _resupply;
	clearItemCargoGlobal _resupply;

	_resupply addMagazineCargoGlobal ["SatchelCharge_Remote_Mag", 2];
	_resupply addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 4];
	_resupply addItemCargoGlobal ["Medikit", 1];
	_resupply addItemCargoGlobal ["FirstAidKit", 10];
	{
		//_magazines = magazines _x;
		_magazines = magazinesAmmoFull _x;
		
		{
			_resupply addMagazineCargoGlobal [(_x select 0), 2];
		} forEach _magazines;	
	} forEach _playerGroup;

	markerResupply = createMarker ["resupplyMkr", _ResupplyOnePos];
	markerResupply setMarkerShape "ICON";
	markerResupply setMarkerColor markerColorPlayers;
	markerResupply setMarkerType "mil_flag";
	markerResupply setMarkerText "Resupply";
	markerResupply setMarkerSize [0.6, 0.6];
};

_carClasses = [];
_carWeights = [];
_slots = [];

if (count pCarNoTurretClasses > 0) then {
	{
		_vehicleClass = (configFile >> "CfgVehicles" >> _x >> "vehicleClass") call BIS_fnc_GetCfgData;		
		_vehRoles = (count([_x] call BIS_fnc_vehicleRoles));
		
		if (_vehicleClass != "Support") then {		
			_carClasses pushBack _x;						
			_vehRoles = (count([_x] call BIS_fnc_vehicleRoles));						
			_slots pushBack _vehRoles;
			_weight = (1-((_vehRoles * 3)/100));		
			_carWeights pushBack _weight;		
			
		};
	} forEach pCarNoTurretClasses;
};

{
	_vehicleClass = (configFile >> "CfgVehicles" >> _x >> "vehicleClass") call BIS_fnc_GetCfgData;
	_vehRoles = (count([_x] call BIS_fnc_vehicleRoles));
	
	if (_vehicleClass != "Support") then {		
		if (_x in _carClasses) then {} else {
			_carClasses pushBack _x;				
			_vehRoles = (count([_x] call BIS_fnc_vehicleRoles));
			_slots pushBack _vehRoles;		
			_weight = (1-((_vehRoles * 7)/100));		
			_carWeights pushBack _weight;
		};		
	};		
} forEach pCarClasses;

_heliClasses = [];
{		
	if (((configFile >> "CfgVehicles" >> _x >> "transportSoldier") call BIS_fnc_GetCfgData) >= (count _playerGroup)) then {
		_heliClasses pushBack _x;
	}
} forEach pHeliClasses;

_shipClasses = pShipClasses;
if (count _shipClasses == 0) then {
	_shipClasses pushBack "B_Boat_Transport_01_F";
};

if ((count _carClasses) == 0) then {
	_carClasses pushBack "B_G_Offroad_01_F";
	_carWeights pushBack 1;
};

if ((count _heliClasses) == 0) then {
	switch (playersSide) do {
		case west: {_heliClasses pushBack "B_Heli_Transport_01_F"};
		case east: {_heliClasses pushBack "O_Heli_Light_02_F"};
		case resistance: {_heliClasses pushBack "I_Heli_Transport_02_F"};
	};
};

diag_log format ["DRO: Insert will be %1", insertType];

switch (insertType) do {

	case 1: {
		// GROUND INSERTION		
		_groundStylesAvailable = [];
		_fobPos = [];
		_seaSpawn = nil;
		
		if (_forceSeaStart == 1) then {
			_groundStylesAvailable = ["SEA"];
		} else {		
			// Check for sea start possibility
			_seaPositions = [];	
			if (!_customStart) then {
				_seaPlaces = selectBestPlaces [_center, aoSize, "(1 + sea)", 50, 5];							
				{
					_thisPos = (_x select 0);
					_zValue = getTerrainHeightASL _thisPos;
					
					if (_zValue < -10) then {
						_seaPositions pushBack [((_x select 0)select 0), ((_x select 0)select 1), _zValue];	
					};
					
				} forEach _seaPlaces;
				
				_seaPositions = [_seaPositions, [_center], {_input0 distance _x}, "DESCEND"] call BIS_fnc_sortBy;
				diag_log format ["DRO: Potential sea positions: %1", _seaPositions];
			};
			// Generate random ground start position for player group
			if (count _randomStartingLocation == 0) then {
				_randomStartingLocation = [_center, ((aoSize/2) + 400), (aoSize+200), 8, 0, 0.25, 0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
			};
			if (_randomStartingLocation isEqualTo [0,0,0]) then {
				_randomStartingLocation = [_center, ((aoSize/2) + 400), (aoSize+2000), 8, 0, 0.25, 0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;				
			};			
			if (_forceSeaStart == 1) then {
				_groundStylesAvailable = ["SEA"];
			} else {
				if (!(_randomStartingLocation isEqualTo [0,0,0])) then {
					_groundStylesAvailable pushback "CAMP";					
					// Check for FOB possibility
					_fobPos = _randomStartingLocation findEmptyPosition [0, 100, "Land_Cargo_House_V3_F"];
					if (count _fobPos > 0) then {			
						_groundStylesAvailable pushback "FOB";
					};
				};
			};
			
		
			
			if (count _groundStylesAvailable == 0) then {			
				if ((count _seaPositions > 0) && (count _shipClasses > 0)) then {
					_seaSpawn = _seaPositions select 0;
					_groundStylesAvailable pushBackUnique "SEA";
				};		
			} else {
				_seaRand = (random 100);
				if (_seaRand > 85) then {
					if ((count _seaPositions > 0) && (count _shipClasses > 0)) then {
						_seaSpawn = _seaPositions select 0;
						_groundStylesAvailable pushBackUnique "SEA";
					};
				};
			};		
		};
		_groundStyleSelect =  selectRandom _groundStylesAvailable;
		diag_log format ["DRO: Ground insert style will be %1", _groundStyleSelect];
		
		// Check for land passage to objective	
		if (_groundStyleSelect == "FOB" || _groundStyleSelect == "CAMP") then {	
			diag_log "DRO: Searching for water";
			_dir = [_randomStartingLocation, _center] call BIS_fnc_dirTo;
			_checkPos = _randomStartingLocation;
			_waterPlaces = [];
			while {(_checkPos distance _center) > 200} do {				
				_checkPos = [_checkPos, 50, _dir] call dro_extendPos;			
				if (surfaceIsWater _checkPos) exitWith {
					diag_log "DRO: Found water for extra boat spawn";
					_waterPlaces = selectBestPlaces [_checkPos, 200, "sea - waterDepth + (waterDepth factor [0.25, 0.5])", 20, 5];					
					diag_log format ["DRO: _waterPlaces = %1", _waterPlaces];
					_deepestPos = ((_waterPlaces select 0) select 0);
					_deepestHeight = getTerrainHeightASL ((_waterPlaces select 0) select 0);					
					{
						_height = getTerrainHeightASL (_x select 0);
						if (_height < _deepestHeight) then {
							_deepestHeight = _height;
							_deepestPos = (_x select 0);
						};
					} forEach _waterPlaces;					
					//_deepestPosReal = (_deepestPos select 0);
									
					_boatPos = [(_deepestPos select 0), (_deepestPos select 1), 0];
					diag_log format ["DRO: _boatPos = %1", _boatPos];
					// Spawn boats until there are enough slots for players
					_rolesFilled = 0;
					while {_rolesFilled < (count(units(group u1)))} do {
					
						_shipClass = selectRandom _shipClasses;
						_vehRoles = (count([_shipClass] call BIS_fnc_vehicleRoles));
						
						_boat = createVehicle [_shipClass, _boatPos, [], 0, "NONE"];
						_boat setDir _dir;
						
						[
							_boat,
							[
								"Nudge",  
								{  
								   _dir = [(_this select 1), (_this select 0)] call BIS_fnc_dirTo;  
								   _nudgePos = [(getPos (_this select 0)), 2, _dir] call dro_extendPos;  
									(_this select 0) setVelocity [(sin _dir)*3, (cos _dir)*3, 0.5];	
								},  
								nil,  
								6,  
								false,  
								false,  
								"",  
								"(_this distance _target < 8) && (vehicle _this == _this)"
							]
						] remoteExec ["addAction", 0, true];
						
						
						_rolesFilled = _rolesFilled + _vehRoles;
						
					};	
					
					_markerName = format["boatMkr%1", floor(random 10000)];
					_markerBoat = createMarker [_markerName, _boatPos];			
					_markerBoat setMarkerShape "ICON";
					_markerBoat setMarkerType "mil_pickup";							
					_markerBoat setMarkerColor markerColorPlayers;						
					_markerBoat setMarkerText "Sea transport";					
				};
			
			};
			diag_log "while loop exited";
		};			
		
		switch (_groundStyleSelect) do {
			case "FOB": {
					
				// Spawn FOB
				_objectLib = ["FOBS"] call fnc_selectObjects;
				_objects = selectRandom _objectLib;
				_spawnedObjects = [_fobPos, (random 360), _objects] call BIS_fnc_ObjectsMapper;
				
				{
					if (typeOf _x == "Sign_Arrow_Blue_F") then {
						_guardUnit = [getPos _x, side u1, pInfClasses, 'Infantry', pInfClasses] call sun_spawnGroupSingleUnit;
						_guardUnit setFormDir (getDir _x);
						_guardUnit setDir (getDir _x);
						_guardUnit disableAI "TARGET";
						_guardUnit disableAI "MOVE";
						deleteVehicle _x;
					};
				} forEach _spawnedObjects;
				
				// Move player group to that position
				_extPos = [_fobPos, 20, (random 360)] call dro_extendPos;
				[group u1, _extPos] call sun_moveGroup;
				
				_rolesFilled = 0;
				_whileAttempts = 0;
				while {(_rolesFilled < (count(units (group u1))))} do {
					_vehClass = "";
					diag_log format ["DRO: startVehicle = %1", startVehicle];
					if ((count (startVehicle select 1) > 0) && _whileAttempts == 0) then {
						_vehClass = (startVehicle select 1);
					} else {
						_vehClass =  [_carClasses, _carWeights] call BIS_fnc_selectRandomWeighted;
					};					
					_vehRoles = (count([_vehClass] call BIS_fnc_vehicleRoles));
					_vehLocation = _randomStartingLocation findEmptyPosition [10, 40, _vehClass];
					diag_log format ["DRO: spawning insert vehicle %1 at %2 with %3 roles", _vehClass, _vehLocation, _vehRoles];
						if (!isNil "_vehLocation" && count _vehLocation > 0) then {
							if (_vehClass isKindOf "Helicopter") then {
								_padTypes = ["Land_HelipadCircle_F", "Land_HelipadCivil_F", "Land_HelipadSquare_F"];
								_veh = createVehicle [(selectRandom _padTypes), _vehLocation, [], 0, "NONE"];
							};
							_veh = createVehicle [_vehClass, _vehLocation, [], 0, "NONE"];
							_veh respawnVehicle	[-1, 0];						
							_rolesFilled = _rolesFilled + _vehRoles;
						};
					_whileAttempts = _whileAttempts + 1;
					if (_whileAttempts >= 8) exitWith {
						diag_log "DRO: spawning insert vehicle while attempts exceeded";
					};
				};
								
				_box = createVehicle ["B_supplyCrate_F", _fobPos, [], 0, "NONE"];
				clearWeaponCargoGlobal _box;
				clearMagazineCargoGlobal _box;
				clearItemCargoGlobal _box;

				_box addMagazineCargoGlobal ["SatchelCharge_Remote_Mag", 2];
				_box addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 4];
				_box addItemCargoGlobal ["Medikit", 1];
				_box addItemCargoGlobal ["FirstAidKit", 10];

				{
					//_magazines = magazines _x;
					_magazines = magazinesAmmoFull _x;
					
					{
						_box addMagazineCargoGlobal [(_x select 0), 2];
					} forEach _magazines;	
				} forEach (units (group u1));
				
				// Check for UAV terminals and spawn random UAV if possible
				if (count pUAVClasses > 0) then {
					{
						_itemsPresent = assignedItems _x;
						{
							if (["UavTerminal", _x] call BIS_fnc_inString) then {
								_availableUAVs = [];
								{
									if (_x isKindOf "Car" || _x isKindOf "Helicopter") then {
										_availableUAVs pushBack _x;
									};
								} forEach pUAVClasses;
								
								_uavClass = selectRandom _availableUAVs;
								_uavLocation = _randomStartingLocation findEmptyPosition [10, 30, _uavClass];
								if (count _uavLocation > 0) then {
									_uav = createVehicle [_uavClass, _uavLocation, [], 0, "NONE"];
								};								
							};
						} forEach _itemsPresent;
					} forEach (units (group u1));
				};
				
				{
					_x enableAI "MOVE";
				} forEach _playerGroup;
				
				// FOB marker
				deleteMarker "campMkr";
				_campNames = ["Partisan", "Shepherd", "Warden", "Stone", "Gullion", "Beech", "Elm", "Ash", "Cedar"];
				_campName = format ["FOB %1", selectRandom _campNames];
				missionNameSpace setVariable ["publicCampName", _campName];
				publicVariable "publicCampName";
				markerPlayerStart = createMarker ["campMkr", _randomStartingLocation];
				markerPlayerStart setMarkerShape "ICON";
				markerPlayerStart setMarkerColor markerColorPlayers;
				markerPlayerStart setMarkerType "loc_Bunker";
				markerPlayerStart setMarkerSize [3, 3];
				markerPlayerStart setMarkerText _campName;
				if ((paramsArray select 0) == 0) then {	
					respawnFOB = [missionNamespace, "campMkr", _campName] call BIS_fnc_addRespawnPosition;
				};
				
			};
			
			case "CAMP": {
				scopeName "camp";				
				// Spawn campsite
				_campObjects = [
					"Land_CampingTable_F",
					"Land_Camping_Light_F",
					"Land_CampingChair_V2_F",
					"Land_GasTank_01_khaki_F",
					"Land_Pillow_old_F",
					"Land_Ground_sheet_khaki_F",
					"Land_TentA_F",
					"Land_TentDome_F",
					"Land_WoodenLog_F",
					"Land_WoodPile_F",
					"Land_WoodPile_large_F",
					"Land_Garbage_square3_F",
					"Land_GarbageBags_F",					
					"Land_JunkPile_F"
				];
				_numCampObjects = [3,8] call BIS_fnc_randomInt;
				for "_i" from 1 to _numCampObjects do {
					_spawnPos = [_randomStartingLocation, (1.5 + random 3), (random 360)] call dro_extendPos;
					_selectedObject = selectRandom _campObjects;
					_object = createVehicle [_selectedObject, _spawnPos, [], 2, "NONE"];
					_object setDir (random 360);
				};
				
				// Move player group to that position
				_playersPos = [_randomStartingLocation, 20, (random 360)] call dro_extendPos;				
				[group u1, _playersPos] call sun_moveGroup;
				
				// Create vehicle
				_rolesFilled = 0;
				_whileAttempts = 0;
				while {(_rolesFilled < (count(units (group u1))))} do {
					_vehClass = "";
					diag_log format ["DRO: startVehicle = %1", startVehicle];					
					if ((count (startVehicle select 1) > 0) && _whileAttempts == 0) then {
						_vehClass = (startVehicle select 1);
					} else {
						_vehClass =  [_carClasses, _carWeights] call BIS_fnc_selectRandomWeighted;
					};
					_vehRoles = (count([_vehClass] call BIS_fnc_vehicleRoles));
					_vehLocation = _randomStartingLocation findEmptyPosition [10, 60, _vehClass];
					diag_log format ["DRO: spawning insert vehicle %1 at %2 with %3 roles", _vehClass, _vehLocation, _vehRoles];
						if (!isNil "_vehLocation" && count _vehLocation > 0) then {
							_veh = createVehicle [_vehClass, _vehLocation, [], 0, "NONE"];
							_veh respawnVehicle	[-1, 0];							
							_rolesFilled = _rolesFilled + _vehRoles;
						};
					_whileAttempts = _whileAttempts + 1;
					if (_whileAttempts >= 8) exitWith {
						diag_log "DRO: spawning insert vehicle while attempts exceeded";
					};
				};
				
				_boxLocation = _randomStartingLocation findEmptyPosition [0, 20, "B_supplyCrate_F"];
				if (count _boxLocation > 0) then {
					_box = createVehicle ["B_supplyCrate_F", _boxLocation, [], 0, "NONE"];
					clearWeaponCargoGlobal _box;
					clearMagazineCargoGlobal _box;
					clearItemCargoGlobal _box;

					_box addMagazineCargoGlobal ["SatchelCharge_Remote_Mag", 2];
					_box addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 4];
					_box addItemCargoGlobal ["Medikit", 1];
					_box addItemCargoGlobal ["FirstAidKit", 10];

					{
						//_magazines = magazines _x;
						_magazines = magazinesAmmoFull _x;
						
						{
							_box addMagazineCargoGlobal [(_x select 0), 2];
						} forEach _magazines;	
					} forEach (units (group u1));
				};
				
				// Check for UAV terminals and spawn random UAV if possible
				_uavSpawned = 0;
				if (count pUAVClasses > 0) then {
					{
						_itemsPresent = assignedItems _x;
						{
							if ((["UavTerminal", _x] call BIS_fnc_inString) && (_uavSpawned == 0)) then {
								_availableUAVs = [];
								{
									if (_x isKindOf "Car" || _x isKindOf "Helicopter") then {
										_availableUAVs pushBack _x;
									};
								} forEach pUAVClasses;
								if (count _availableUAVs > 0) then {
									_uavClass = selectRandom _availableUAVs;
									_uavLocation = _randomStartingLocation findEmptyPosition [10, 30, _uavClass];
									if (count _uavLocation > 0) then {
										_uav = createVehicle [_uavClass, _uavLocation, [], 0, "NONE"];
										_uavSpawned = 1;
									};
								};								
							};
						} forEach _itemsPresent;
					} forEach (units (group u1));
				};
				
				// Camp marker
				deleteMarker "campMkr";
				_campNames = ["Mockingbird", "Bluejay", "Cormorant", "Heron", "Albatross", "Hornbill", "Osprey", "Kingfisher", "Nuthatch"];
				_campName = format ["Camp %1", selectRandom _campNames];
				missionNameSpace setVariable ["publicCampName", _campName];
				publicVariable "publicCampName";
				markerPlayerStart = createMarker ["campMkr", _randomStartingLocation];
				markerPlayerStart setMarkerShape "ICON";
				markerPlayerStart setMarkerColor markerColorPlayers;
				markerPlayerStart setMarkerType "loc_Bunker";
				markerPlayerStart setMarkerSize [3, 3];
				markerPlayerStart setMarkerText _campName;
				if ((paramsArray select 0) == 0) then {	
					respawnFOB = [missionNamespace, "campMkr", _campName] call BIS_fnc_addRespawnPosition;
				};
				
				{
					_x enableAI "MOVE";
				} forEach _playerGroup;
				
			};
			
			case "SEA": {				
				_shipClass = selectRandom _shipClasses;
				
				if (getMarkerColor "campMkr" == "") then {
					_randomStartingLocation = [(_seaSpawn select 0), (_seaSpawn select 1), 0];
				} else {
					_randomStartingLocation = getMarkerPos "campMkr";					
				};
									
				// Spawn vehicles until there are enough slots for players
				_vehiclePool = [];
				_rolesFilled = 0;
				while {((_rolesFilled < (count(units(group u1)))) || (_rolesFilled <= 8))} do {
				
					_shipClass = selectRandom _shipClasses;
					_vehRoles = (count([_shipClass] call BIS_fnc_vehicleRoles));
					
					_boatLoc = _randomStartingLocation findEmptyPosition [0, 10, _shipClass];
					
					_boat = createVehicle [_shipClass, _boatLoc, [], 0, "NONE"];
					
					[
						_boat,
						[
							"Nudge",  
							{  
								_dir = [(_this select 1), (_this select 0)] call BIS_fnc_dirTo;  
								_nudgePos = [(getPos (_this select 0)), 2, _dir] call dro_extendPos;  
								(_this select 0) setVelocity [(sin _dir)*3, (cos _dir)*3, 0.5];	
							},  
							nil,  
							6,  
							false,  
							false,  
							"",  
							"(_this distance _target < 8) && (vehicle _this == _this)"
						]
					] remoteExec ["addAction", 0, true];
					
					_rolesFilled = _rolesFilled + _vehRoles;
					
					_vehiclePool pushBack _boat;
					
				};	
				
				if (count _vehiclePool > 0) then {
					
					_playersLeft = (units(group u1));
					diag_log format ["_playersLeft = %1", _playersLeft];
					{
						if ((count _playersLeft) > 0) then {
							_thisBoat = _x;
							diag_log format ["_thisBoat = %1", _thisBoat];
							_vehRoles = (count([_thisBoat] call BIS_fnc_vehicleRoles));
							diag_log format ["_vehRoles = %1", _vehRoles];
							_playersToAssign = [];
							if (_vehRoles > (count _playersLeft)) then {_vehRoles = (count _playersLeft)};
							for "_i" from 0 to (_vehRoles - 1) do {	
								diag_log format ["_i = %1", _i];
								diag_log format ["(_playersLeft select _i) = %1", (_playersLeft select _i)];
								_thisUnit = (_playersLeft select _i);
								_playersToAssign pushBack _thisUnit;							
							};
							_playersLeft = _playersLeft - _playersToAssign;
							diag_log format ["_playersLeft = %1", _playersLeft];
							diag_log format ["_playersToAssign = %1", _playersToAssign];
							if ((count _playersToAssign) > 0) then {
								[_playersToAssign, _thisBoat] spawn sun_groupToVehicle;
							};
						};						
					} forEach _vehiclePool;
					diag_log format ["(units(group u1)) = %1", (units(group u1))];					
					deleteMarker "campMkr";
					missionNameSpace setVariable ["publicCampName", "Altis Ocean Territory"];
					publicVariable "publicCampName";
					markerPlayerStart = createMarker ["campMkr", _randomStartingLocation];
					markerPlayerStart setMarkerShape "ICON";
					markerPlayerStart setMarkerColor markerColorPlayers;
					markerPlayerStart setMarkerType "mil_start";
					markerPlayerStart setMarkerText "Sea Insert";
					
					{
						_x addMagazineCargoGlobal ["SatchelCharge_Remote_Mag", 2];
						_x addMagazineCargoGlobal ["DemoCharge_Remote_Mag", 4];
						_x addItemCargoGlobal ["Medikit", 1];
						_x addItemCargoGlobal ["FirstAidKit", 10];
					} forEach _vehiclePool;
					
					
					//[_insertShip, ["Arsenal", "['Open', true] call BIS_fnc_arsenal", nil, 6]] remoteExec ["addAction", 0];
					
				};				
			};
		};		
						
		// Blacklist marker
		_markerBL = createMarker ["blacklistMkr", _randomStartingLocation];
		_markerBL setMarkerShape "ELLIPSE";
		_markerBL setMarkerSize [500, 500];
		_markerBL setMarkerAlpha 0;
		blackList = blackList + [_markerBL];
			
	};
	case 2: {
		// HALO INSERTION		
		// Generate drop position
				
		// If no insert position selected then generate a random one
		if (count _randomStartingLocation == 0) then {		
			_randomStartingLocation = [_center,(aoSize/1.8),(aoSize/1.6),0,1,1,0, [trgAOC], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
			if (_randomStartingLocation isEqualTo [0,0,0]) then {
				_randomStartingLocation = [_center,(aoSize/1.8),(aoSize/1.6),0,0,1,0] call BIS_fnc_findSafePos;
			};			
		};
				
		_randomStartingLocation = [(_randomStartingLocation select 0), (_randomStartingLocation select 1), 0];		
		_startHeight = (getTerrainHeightASL _randomStartingLocation) + 2000;
		_planeStartPos = [(_randomStartingLocation select 0), (_randomStartingLocation select 1), 2100];
		_airStartPos = [(_randomStartingLocation select 0), (_randomStartingLocation select 1), 2000];
		
		// Draw drop marker
		deleteMarker "campMkr";
		markerPlayerStart = createMarker ["campMkr", _randomStartingLocation];
		markerPlayerStart setMarkerShape "ICON";
		markerPlayerStart setMarkerColor markerColorPlayers;
		markerPlayerStart setMarkerType "mil_end";
		markerPlayerStart setMarkerText "Drop point";		
		
		// Spawn heli and begin insertion
		if (count pPlaneClasses > 0) then {
			_planeClass = selectRandom pPlaneClasses;			
			_planeStartPos set [2, 3050];
			_insertPlane = createVehicle [_planeClass, _planeStartPos, [], 0, "FLY"];
			createVehicleCrew _insertPlane;
			_insertPlane setPos _planeStartPos;
			_insertPlane setDir ([_planeStartPos, _center] call BIS_fnc_dirTo);
			_insertPlane move [0,0,0];
			_insertPlane flyInHeight 3000;
			_insertPlane setBehaviour "CARELESS";			
			[_insertPlane] spawn {
				waitUntil {(_this select 0) distance [0,0,0] < 1000};
				{deleteVehicle _x} forEach (crew (_this select 0));
				deleteVehicle (_this select 0);
			};			
		};
		
		_lastPos = _airStartPos;
		{
			_thisPos = [_lastPos, 20, ([_airStartPos, _center] call BIS_fnc_dirTo)] call dro_extendPos;
			_x setPos [(_thisPos select 0) + (random 10), (_thisPos select 1) + (random 10), (3000 + (random 20))];
			
			
			_lastPos = _thisPos;
		} forEach _playerGroup;
				
		[_playerGroup] execVM 'sunday_system\callParadrop.sqf';
		
		// Set wind
		0 setGusts 0;
		setWind [0, 0, true];
		
		
		
		
		diag_log "DRO: Air insert called";
		sleep 2;
		
		
		// Blacklist marker
		_markerBL = createMarker ["blacklistMkr", _randomStartingLocation];
		_markerBL setMarkerShape "ELLIPSE";
		_markerBL setMarkerSize [500, 500];
		_markerBL setMarkerAlpha 0;
		blackList = blackList + [_markerBL];
				
		
		//waitUntil {player in _insertHeli};		
		
		missionNameSpace setVariable ["publicCampName", format ["%1 Airspace", worldName]];
		publicVariable "publicCampName";
		
		
		/*
		{	
			[[_x], "sunday_system\paraBackpack.sqf"] remoteExec ["execVM", _x, false];			
		} forEach _playerGroup;
		*/
	};
	
};

// Add supports
[] execVM "sunday_system\addSupports.sqf";
groupLeader createDiarySubject ["reset", "Reset AI units"];
_resetStrings = [];
{
	[_x, "MOVE"] remoteExec ["enableAI", (owner _x), false];
	//_x enableAI "MOVE";
	_x enableGunLights "forceon";

	if (!isPlayer _x) then {
		_id = [_x] call sun_getUnitPositionId;
		_str = format ["Unit %2: %1 - <execute expression='[%2] execVM ""sunday_system\resetAI.sqf""'>Reset</execute><br />", (name _x), _id];		
		_resetStrings pushBack _str;
	};
} forEach _playerGroup;


_resetStringFull = _resetStrings joinString "";
groupLeader createDiaryRecord ["reset", ["Reset AI units", (format ["<br /><font size='20' face='PuristaBold'>Reset AI Units</font><br /><br />Use these options when AI get stuck or stop responding to commands.
Reset will create a new identical unit and place them in a valid location as close to their current position as possible or near the team leader if no valid location is found.<br /><br />%1", _resetStringFull])]];

missionNameSpace setVariable ["startPos", _randomStartingLocation];
publicVariable "startPos";

playerGroup = _playerGroup;

if (isMultiplayer) then {
	// If respawn is enabled add the dynamic team respawn position
	if ((paramsArray select 0) == 0) then {	
		[] execVM 'sunday_system\teamRespawnPos.sqf';
	};
	{
		if (!isPlayer _x) then {		
			// Add eventhandlers to govern respawning AI in MP games
			//_x setVariable ["respawnLoadout", (getUnitLoadout _x), true];			
			if ((paramsArray select 0) == 1) then {
				[_x, ["respawn", {
					_unit = (_this select 0);				
					deleteVehicle _unit
				}]] remoteExec ["addEventHandler", _x, true];
			} else {
				[_x, ["killed", {[(_this select 0)] execVM "sunday_system\fakeRespawn.sqf"}]] remoteExec ["addEventHandler", _x, true];
				[_x, ["respawn", {
					_unit = (_this select 0);				
					deleteVehicle _unit
				}]] remoteExec ["addEventHandler", _x, true];				
			};			
		};
		// Add player's side to spectator whitelist
		_x setVariable ["WhitelistedSides", [playersSideCfgGroups], true];
		
	} forEach (units (group u1));
};

// Remove arsenal backdrop objects
sleep 2;
_backdropList = (getPos logicStartPos) nearObjects 20;
_backdropList = _backdropList - (units(group u1));
{
	deleteVehicle _x;	
} forEach _backdropList;

if (reviveDisabled < 3) then {
	diag_log "DRO: Revive enabled";
	[units (grpNetId call BIS_fnc_groupFromNetId)] execVM "sunday_revive\initRevive.sqf";
};

missionNameSpace setVariable ["playersReady", 1];
publicVariable "playersReady";



