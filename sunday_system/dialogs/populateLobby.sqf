//disableUserInput false;
//[] execVM "sunday_system\dialogs\positionLobbyControls.sqf";

//[] execVM "sunday_system\dialogs\initLobbyCam.sqf";
//[] call dro_initLobbyCam;

disableSerialization;
/*
{
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlSetFade 1;
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlCommit 0;
} forEach (allControls findDisplay 626262);
*/
{
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlSetFade 0;
	((findDisplay 626262) displayCtrl (ctrlIDC _x)) ctrlCommit 0.3;
} forEach (allControls findDisplay 626262);

if (isMultiplayer) then {
	((findDisplay 626262) displayCtrl 6051)  ctrlSetText "Caution: Starting the mission as team lead will end the loadout phase for all players.";
};

{
	_thisUnit = _x;
	if ((player == _thisUnit) OR ((player == u1) && (!isPlayer _thisUnit))) then {
		// Populate unit classes
		
		// Get listbox for this unit, make sure it's clear and add all class options to it
		_thisLB = (_thisUnit getVariable "unitLoadoutIDC");
		diag_log _thisLB;
		lbClear _thisLB;
		{		
			_index = lbAdd [_thisLB, (_x select 1)];			
			lbSetData [_thisLB, _index, (_x select 0)];
		} forEach unitList;	
			
		if (typeName (_thisUnit getVariable "unitChoice") == "STRING") then {		
			if ((_thisUnit getVariable "unitChoice") == "CUSTOM") then {
				_index = lbAdd [_thisLB, "Custom Loadout"];
				lbSetData [_thisLB, _index, "CUSTOM"];
				lbSetCurSel [_thisLB, _index];
			} else {		
				for "_i" from 1 to (lbSize _thisLB) do {
					_className = lbData [_thisLB, (_i - 1)];
					if ((_thisUnit getVariable "unitChoice") == _className) then {
						lbSetCurSel [_thisLB, (_i - 1)];
						diag_log "selected using switchLoadout value";
					};
				};
			};		
		};
	} else {
		//[((findDisplay 626262) displayCtrl (_thisUnit getVariable "unitLoadoutIDC"))] remoteExec ["ctrlDelete", player, false];
		ctrlDelete ((findDisplay 626262) displayCtrl (_thisUnit getVariable "unitLoadoutIDC"));
	};
	
	// Disable delete button for players
	if (isPlayer _thisUnit) then {
		ctrlEnable [(_thisUnit getVariable "unitDeleteIDC"), false];
	};
	
} forEach playerGroup;

lbAdd [6009, "Random"];
lbAdd [6009, "Ground"];
lbAdd [6009, "Air"];
//lbAdd [6009, "HALO"];
if (player == u1) then {
	lbSetCurSel [6009, insertType];
};

// Insert vehicle options
_index = lbAdd [6013, "Random"];
lbSetData [6013, _index, ""];
_validVehicles = [];
{
	if (count ([_x] call BIS_fnc_vehicleRoles) > 2) then {
		_validVehicles pushBack _x;
	};
} forEach pHeliClasses;
{
	_validVehicles pushBack _x;
} forEach pCarClasses;

{
	_index = lbAdd [6013, ((configfile >> "CfgVehicles" >> _x >> "displayName") call BIS_fnc_getCfgData)];
	lbSetPicture [6013, _index, ((configfile >> "CfgVehicles" >> _x >> "icon") call BIS_fnc_getCfgData)];	
	lbSetPictureColor [6013, _index, [1, 1, 1, 1]];
	lbSetData [6013, _index, _x];
} forEach _validVehicles;

if (player == u1) then {
	lbSetCurSel [6013, (startVehicle select 0)];
};

// Support options
lbAdd [6010, "Random"];
lbAdd [6010, "Custom"];
if (player == u1) then {
	lbSetCurSel [6010, randomSupports];
};


// If player is not u1 then disable all other controls
if (player != u1) then {
	{
		if (_x != player) then {			
			ctrlEnable [(_x getVariable "unitArsenalIDC"), false];			
			ctrlEnable [(_x getVariable "unitDeleteIDC"), false];
		}
	} forEach playerGroup;
	ctrlEnable [6004, false];
	ctrlEnable [6005, false];
	ctrlEnable [6009, false];
	ctrlEnable [6010, false];
	ctrlEnable [6011, false];
	ctrlEnable [6013, false];
	ctrlEnable [6050, false];
};

// Remove controls for AI no longer in group
{
	if (isObjectHidden _x) then {		
		ctrlEnable [(_x getVariable "unitLoadoutIDC"), false];
		ctrlEnable [(_x getVariable "unitArsenalIDC"), false];		
		ctrlEnable [(_x getVariable "unitDeleteIDC"), true];
		((findDisplay 626262) displayCtrl (_x getVariable "unitDeleteIDC")) ctrlSetChecked true;		
	};	
} forEach playerGroup;

// Change name texts
{
	if (isPlayer _x) then {		
		((findDisplay 626262) displayCtrl ((_x getVariable "unitLoadoutIDC")-1)) ctrlSetText (format ["%1:", (name _x)]);
	} else {
		((findDisplay 626262) displayCtrl ((_x getVariable "unitLoadoutIDC")-1)) ctrlSetText (format ["%1 (AI):", (name _x)]);
	};	
} forEach playerGroup;

if (!isNil "firstLobbyOpen") then {
	if (firstLobbyOpen && (player == u1)) then {
		{
			if (!isPlayer _x) then {
				[_x, true] remoteExec ["hideObject", 0, true];
				//_x hideObjectGlobal true;
				[_x] joinSilent grpNull;
				
				ctrlEnable [(_x getVariable "unitLoadoutIDC"), false];
				ctrlEnable [(_x getVariable "unitArsenalIDC"), false];
				ctrlEnable [(_x getVariable "unitReadyIDC"), false];	
				
				diag_log format ["DRO: Removed unit %1", _x];
				((findDisplay 626262) displayCtrl (_x getVariable "unitDeleteIDC")) ctrlSetChecked true;
			};			
		} forEach [u5, u6, u7, u8];
	}; 

	firstLobbyOpen = false;
};
/*
while {(!isNull (uiNamespace getVariable [ "BIS_fnc_arsenal_cam", objNull])) || (!visibleMap)} do {
	if ((missionNameSpace getVariable "lobbyComplete") == 1) exitWith {	};	
	if ((!dialog) && (isNull (uiNamespace getVariable [ "BIS_fnc_arsenal_cam", objNull])) && (!visibleMap)) exitWith {
		//camLobbyPos = getPos camLobby;
		//camLobbyTimePaused = time;
		_handle = CreateDialog "DRO_lobbyDialog";
		[] execVM "sunday_system\dialogs\populateLobby.sqf";
	};	
};
*/