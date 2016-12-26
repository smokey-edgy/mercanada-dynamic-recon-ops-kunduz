#include "reviveFunctions.sqf";

reviveUnits = (_this select 0);
reviveTime = 20;
bleedTime = switch (reviveDisabled) do {
	case 0: {300};
	case 1: {120};
	case 2: {60};
	default {300};
};
publicVariable "reviveTime";
publicVariable "bleedTime";


{	
	_x setVariable ["rev_beingAssisted", false, true];		
	_x setVariable ["rev_beingRevived", false, true];
	_x setVariable ["rev_revivingUnit", false, true];
	_x setVariable ["rev_downed", false, true];
	_x setVariable ["rev_dragged", false, true];		
	
	if (isMultiplayer) then {
		if (local _x) then {
			_handlerDamage = _x addEventHandler ["HandleDamage", rev_handleDamage];
			_handlerKilled = _x addEventHandler ["Killed", rev_handleKilled];
			_handlerRespawn = _x addEventHandler ["Respawn", {
				(_this select 0) addEventHandler ["HandleDamage", rev_handleDamage];
				(_this select 0) addEventHandler ["Killed", rev_handleKilled];
				(_this select 0) setCaptive false;
				reviveUnits = reviveUnits - [(_this select 1)];
				reviveUnits pushBack (_this select 0);
				publicVariable 'reviveUnits';
			}];
		} else {
			_handlerDamage = [_x, ["HandleDamage", rev_handleDamage]] remoteExec ["addEventHandler", _x, true];	
			_handlerKilled = [_x, ["Killed", rev_handleKilled]] remoteExec ["addEventHandler", _x, true];
			_handlerRespawn = [_x, ["Respawn", {
				_handlerDamage = (_this select 0) addEventHandler ["HandleDamage", rev_handleDamage];
				_handlerKilled = (_this select 0) addEventHandler ["Killed", rev_handleKilled];
				(_this select 0) setCaptive false;
				reviveUnits = reviveUnits - [(_this select 1)];
				reviveUnits pushBack (_this select 0);
				publicVariable 'reviveUnits';
			}]] remoteExec ["addEventHandler", _x, true];
							
		};
	} else {
		_handlerDamage = _x addEventHandler ["HandleDamage", rev_handleDamage];
		_handlerKilled = _x addEventHandler ["Killed", rev_handleKilled];		
	};	
} forEach reviveUnits;

[] execVM "sunday_revive\AIReviveListen.sqf";