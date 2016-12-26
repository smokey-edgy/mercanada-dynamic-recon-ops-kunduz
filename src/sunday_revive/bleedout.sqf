sleep 0.05;

_unit = _this select 0;

private _time = bleedTime;
private ["_timeBefore", "_total", "_blood"];
_timeBefore = time;
_total = _time;
_blood = 1;

private _bloodLevel = 0;
private _bloodLevelPrev = 0;

private _suicideAction = nil;

// Post process effects for players
if (!isDedicated && _unit == player) then {
	[] spawn {		
		while {(player getVariable "rev_downed")} do {
			sleep 1;

			if (player getVariable "rev_downed") then {
				//grab blood level
				private _blood = player getVariable ["rev_blood", 1];

				//calculate desaturation
				private _bright = 0.2 + (0.1 * _blood);
				bis_revive_ppColor ppEffectAdjust [1,1, 0.15 * _blood,[0.3,0.3,0.3,0],[_bright,_bright,_bright,_bright],[1,1,1,1]];

				//calculate intensity of vignette
				private _intense = 0.6 + (0.4 * _blood);
				bis_revive_ppVig ppEffectAdjust [1,1,0,[0.15,0,0,1],[1.0,0.5,0.5,1],[0.587,0.199,0.114,0],[_intense,_intense,0,0,0,0.2,1]];

				//calculate intensity of blur
				private _blur = 0.7 * (1 - _blood);
				bis_revive_ppBlur ppEffectAdjust [_blur];

				//smoothly transition
				{_x ppEffectCommit 1} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
			};
		};

		bis_revive_ppColor ppEffectAdjust [1, 1, 0, [1, 1, 1, 0], [0, 0, 0, 1],[0,0,0,0]];
		bis_revive_ppVig ppEffectAdjust [1, 1, 0, [1, 1, 1, 0], [0, 0, 0, 1],[0,0,0,0]];
		bis_revive_ppBlur ppEffectAdjust [0];

		{_x ppEffectCommit 1} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
		sleep 1;
		{_x ppEffectEnable false} forEach [bis_revive_ppColor, bis_revive_ppVig, bis_revive_ppBlur];
	};
	
	//_suicideAction = player addAction ["Suicide", {(_this select 0) setDamage 1; (_this select 0) removeAction (_this select 2)}, nil, 1000, true, true, "", "alive _target", -1, true];
	_suicideAction = [player] call rev_suicideActionAdd;
	
};


waitUntil {
	sleep 0.1;

	if !(_unit getVariable "rev_beingRevived") then {
		_time = _time - (time - _timeBefore);
	};

	_timeBefore = time;		

	//calculate blood
	_blood = (_time / _total);

	//get & set bleedout state
	_bloodLevel = floor(_blood * 5); if (_bloodLevel > 3) then {_bloodLevel = 3;};

	if (_unit getVariable "rev_downed") then {
		_unit setVariable ["rev_blood", _blood];
	};	
	
	//wait for unit to bleeding out be revived
	_blood <=0 || {!alive _unit || {!(_unit getVariable "rev_downed")}}
};

if (!isNil "_suicideAction") then {
	_unit removeAction _suicideAction;
};

//kill unit if it bled out
if (alive _unit && {_blood <=0}) then {
	_unit setDamage 1;
};
