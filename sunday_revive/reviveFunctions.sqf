rev_addReviveToUnit = {
	params ["_unit", "_unitOld"];
	_unit setVariable ["rev_beingAssisted", false, true];		
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_revivingUnit", false, true];
	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_dragged", false, true];		
	
	if (isMultiplayer) then {
		if (local _unit) then {
			_handlerDamage = _unit addEventHandler ["HandleDamage", rev_handleDamage];
			_handlerKilled = _unit addEventHandler ["Killed", rev_handleKilled];
			_handlerRespawn = _unit addEventHandler ["Respawn", {
				(_this select 0) addEventHandler ["HandleDamage", rev_handleDamage];
				(_this select 0) addEventHandler ["Killed", rev_handleKilled];
				(_this select 0) setCaptive false;
				reviveUnits = reviveUnits - [(_this select 1)];
				reviveUnits pushBack (_this select 0);
				publicVariable 'reviveUnits';
			}];
		} else {
			_handlerDamage = [_unit, ["HandleDamage", rev_handleDamage]] remoteExec ["addEventHandler", _x, true];	
			_handlerKilled = [_unit, ["Killed", rev_handleKilled]] remoteExec ["addEventHandler", _x, true];
			_handlerRespawn = [_unit, ["Respawn", {
				_handlerDamage = (_this select 0) addEventHandler ["HandleDamage", rev_handleDamage];
				_handlerKilled = (_this select 0) addEventHandler ["Killed", rev_handleKilled];
				(_this select 0) setCaptive false;
				reviveUnits = reviveUnits - [(_this select 1)];
				reviveUnits pushBack (_this select 0);
				publicVariable 'reviveUnits';
			}]] remoteExec ["addEventHandler", _x, true];							
		};
		
	} else {
		_handlerDamage = _unit addEventHandler ["HandleDamage", rev_handleDamage];
		_handlerKilled = _unit addEventHandler ["Killed", rev_handleKilled];		
	};	
	if (!isNil "_unitOld") then {			
		reviveUnits = reviveUnits - [_unitOld];			
	};
	_unit setCaptive false;
	reviveUnits pushBack _unit;
	publicVariable 'reviveUnits';
};

rev_reviveUnit = {
	private ["_unit", "_medic"];
	_unit = _this select 0;
	_medic = _this select 1;

	diag_log format ["DRO: Unit %1 is revived by medic %2", _unit, _medic];
	
	if (isPlayer _unit) then {
		diag_log format ["DRO: Resetting camera for unit %1", _unit];
		[] remoteExec ["rev_resetCamera", _unit];	
	};	
	
	if (typeName (_unit getVariable 'rev_holdActionID') == "SCALAR") then {
		diag_log format ["DRO: Removing revive action ID: %1", (_unit getVariable 'rev_holdActionID')];
		[_unit, (_unit getVariable 'rev_holdActionID')] remoteExec ["BIS_fnc_holdActionRemove", 0, true];
		[_unit, (_unit getVariable 'rev_holdActionID')] call BIS_fnc_holdActionRemove;	
	};
	
	if (isPlayer _unit) then {
		diag_log format ["DRO: Revive of %1 processed as a player unit", _unit]; 
		[_unit, false] remoteExec ["setUnconscious", _unit];
		[_unit, true] remoteExec ["allowDamage", _unit];
		[_unit, false] remoteExec ["setCaptive", _unit];
	} else {
		if (local _unit) then {
			diag_log format ["DRO: Revive of %1 processed as a local AI unit", _unit]; 
			_unit setUnconscious false;
			_unit allowDamage true;
			_unit setCaptive false;
		} else {
			diag_log format ["DRO: Revive of %1 processed as a non-local AI unit", _unit]; 
			[_unit, false] remoteExec ["setUnconscious", _unit];
			[_unit, true] remoteExec ["allowDamage", _unit];
			[_unit, false] remoteExec ["setCaptive", _unit];
		};
	};

	if ("Medikit" in (items _medic)) then {
		_unit setDamage 0;	
	} else {
		if ("FirstAidKit" in (items _medic)) then {
			_medic removeItem "FirstAidKit";
			if !(isClass(configFile >> "CfgPatches" >> "ace_medical")) then {_unit setDamage 0.4};					
		} else {
			if !(isClass(configFile >> "CfgPatches" >> "ace_medical")) then {_unit setDamage 0.75};			
		};
	};

	if !("FirstAidKit" in (items _medic) OR "Medikit" in (items _medic)) then {
		diag_log format ["Revive: %1 is out of medical supplies", _medic];
		_string = selectRandom ["I'm out of medical supples.", "That was my last first aid kit.", "Going to need more medical supplies."];
		[_medic, _string] remoteExec ["groupChat", 0];
		
	};

	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_beingAssisted", false, true];
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_dragged", false, true];
	[_unit] remoteExec ["rev_dragActionRemove", 0, true];
			
};

rev_suicideActionAdd = {
	private ["_id"];
	_id = [
		(_this select 0),
		"Suicide",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d50_ca.paa",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d100_ca.paa",
		"alive _target",
		"alive _target",
		{},
		{},
		{			
			(_this select 0) setDamage 1;
			[(_this select 0), (_this select 2)] remoteExec ["bis_fnc_holdActionRemove", 0, true];			
		},
		{},
		[],
		3,
		1000,
		true,
		true
	] call BIS_fnc_holdActionAdd;
	_id
};

rev_reviveActionAdd = {
	private ["_id"];
	_id = [
		(_this select 0),
		"Revive",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u100_ca.paa",
		"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\r100_ca.paa",
		"((_this distance _target) < 3) && (alive _target)",
		"((_this distance _target) < 3) && (alive _target)",
		{(_this select 0) setVariable ["rev_beingRevived", true, true]},
		{},
		{			
			[(_this select 0), (_this select 1)] remoteExec ["rev_reviveUnit", (_this select 1)];
			[(_this select 0), (_this select 2)] remoteExec ["bis_fnc_holdActionRemove", 0, true];			
		},
		{(_this select 0) setVariable ["rev_beingRevived", false, true]},
		[],
		reviveTime,
		1000,
		true,
		false
	] call BIS_fnc_holdActionAdd;
	
	(_this select 0) setVariable ["rev_holdActionID", _id, true];
};

rev_handleDamage = {
	params ["_unit", "_selection", "_damage","_source","","_index"];
	
	if(alive _unit && _selection == "" && _damage >= 0.9 && lifeState _unit != "INCAPACITATED") then {
		_unit setVariable ["rev_beingRevived", false, true];
		_unit allowDamage false;
		_unit setDamage 0.95;
		_unit setCaptive true;
		
		if(vehicle _unit != _unit) then {moveOut _unit};
		
		_unit setUnconscious true;
		
		if (_unit == player) then {
			VAR_CAMERA_VIEW = cameraView;
			
			bis_revive_ppColor = ppEffectCreate ["ColorCorrections", 1632];
			bis_revive_ppVig = ppEffectCreate ["ColorCorrections", 1633];
			bis_revive_ppBlur = ppEffectCreate ["DynamicBlur", 525];

			bis_revive_ppColor ppEffectAdjust [1,1,0.15,[0.3,0.3,0.3,0],[0.3,0.3,0.3,0.3],[1,1,1,1]];
			bis_revive_ppVig ppEffectAdjust [1,1,0,[0.15,0,0,1],[1.0,0.5,0.5,1],[0.587,0.199,0.114,0],[1,1,0,0,0,0.2,1]];
			bis_revive_ppBlur ppEffectAdjust [0];
			{_x ppEffectCommit 0; _x ppEffectEnable true; _x ppEffectForceInNVG true} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			
			[] spawn {
				if (cameraView != "EXTERNAL") then
				{
					titleCut ["","BLACK OUT",0.5];
					sleep 0.5;
					player switchCamera "EXTERNAL";
					titleCut ["","BLACK IN",0.5];
					sleep 0.5;
				};
			};			
		};
		_damage = 0;
		
		if (isMultiplayer) then {								
			if (isPlayer _unit) then {
				_unitID = clientOwner;
				diag_log -_unitID;
				[(_this select 0)] remoteExec ["rev_reviveActionAdd", -_unitID, true];
				[(_this select 0)] remoteExec ["rev_dragActionAdd", -_unitID, true];
			} else {
				[(_this select 0)] remoteExec ["rev_reviveActionAdd", 0, true];	
				[(_this select 0)] remoteExec ["rev_dragActionAdd", 0, true];	
			};			
		} else {
			if (_unit != player) then {
				[(_this select 0)] call rev_reviveActionAdd;
				[(_this select 0)] call rev_dragActionAdd;
			};
		};
		
		_string = selectRandom ["I'm hit!", "Need medical attention!", "I'm down!"];
		//directories[] = {"\A3\Dubbing_Radio_F\data\ENG\Male01ENG\","\A3\Dubbing_Radio_F\data\ENG\Male01ENG\"};		
		[_unit, _string] remoteExec ["groupChat", 0];		
		
		_unit setVariable ["rev_downed", true, true];
		[_unit] execVM "sunday_revive\bleedout.sqf";		
	};
	
	if(_damage >= 1) then {_damage = 0.85};	
	_damage
};

rev_resetCamera = {
	if (!isNil "VAR_CAMERA_VIEW") then {		
		[] spawn
		{
			titleCut ["","BLACK OUT",0.5];
			sleep 0.5;
			if (cameraView != VAR_CAMERA_VIEW) then {
				player switchCamera VAR_CAMERA_VIEW;
			};
			{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			titleCut ["","BLACK IN",0.5];
		};		
	} else {
		[] spawn
			{
				titleCut ["","BLACK OUT",0.5];
				sleep 0.5;
				player switchCamera "INTERNAL";
				{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
				titleCut ["","BLACK IN",0.5];
			};
	};
};

rev_dragActionAdd = {	
	private _id = (_this select 0) addAction ["Drag", {[_this select 0] call rev_drag}, nil, 10, false, true, "", "alive _target", 3, false];
	(_this select 0) setVariable ["rev_dragActionID", _id, true];
};

rev_dragActionRemove = {
	(_this select 0) removeAction ((_this select 0) getVariable "rev_dragActionID");
};

rev_drag = {
	private ["_target"];
	_target = _this select 0;
	playerDragging = true;
	_target setVariable ["rev_dragged", true, true];
	[_target, (_target getVariable 'rev_dragActionID')] remoteExec ["removeAction", 0, true];
	player removeAction (_target getVariable 'rev_dragActionID');	
	sleep 0.5;
	player playMoveNow "AcinPknlMstpSrasWrflDnon";
	_target attachTo [player, [0, 1.18, 0.08]];
	[_target, 180] remoteExec ["setDir", 0];
	
	_target enableSimulationGlobal false;	
	
	[_target, (_target getVariable 'rev_holdActionID')] remoteExec ["BIS_fnc_holdActionRemove", 0, true];
	[_target, (_target getVariable 'rev_holdActionID')] call BIS_fnc_holdActionRemove;
	
	_dropID = player addAction ["<img image='\A3\ui_f\data\map\markers\military\end_CA.paa'/>Release", {playerDragging = false}, [], 10, true, true, "", ""];
		
	while {alive player && !(player getVariable ["rev_downed", false]) && (_target getVariable ["rev_downed", true]) && playerDragging} do {
		sleep 0.2;
	};
	
	_target enableSimulationGlobal true;
				
	if(alive player && !(player getVariable ["rev_downed", false])) then { 
		player playMove "amovpknlmstpsraswrfldnon";
	};
	
	player removeAction _dropID;
	playerDragging = false;
	
	detach _target;

	if (isMultiplayer) then {			
			
		if (isPlayer _target) then {
			_target = clientOwner;
			diag_log -_target;
			[_target] remoteExec ["rev_reviveActionAdd", -_target, true];
			[_target] remoteExec ["rev_dragActionAdd", -_target, true];
		} else {
			[_target] remoteExec ["rev_reviveActionAdd", 0, true];	
			[_target] remoteExec ["rev_dragActionAdd", 0, true];	
		};			
	} else {
		if (_target != player) then {
			[_target] call rev_reviveActionAdd;
			[_target] call rev_dragActionAdd;
		};
	};
			
	sleep 2;
	_target setVariable ["rev_dragged", false, true];	
};

rev_handleKilled = {	
	private ["_unit"];
	_unit = (_this select 0);
	_unit setVariable ["rev_beingAssisted", false, true];		
	_unit setVariable ["rev_beingRevived", false, true];
	_unit setVariable ["rev_revivingUnit", false, true];
	_unit setVariable ["rev_downed", false, true];
	_unit setVariable ["rev_dragged", false, true];
	if (_unit == player) then {
		if (!isNil "bis_revive_ppColor") then {
			{_x ppEffectCommit 0; _x ppEffectEnable false; _x ppEffectForceInNVG false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
		};
	};
};
