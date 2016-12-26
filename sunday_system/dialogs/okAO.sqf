_playersIndex = lbCurSel 2100;
_enemyIndex = lbCurSel 2101;
_civIndex = lbCurSel 2102;
_playersFaction = lbData [2100, _playersIndex];
_enemyFaction = lbData [2101, _enemyIndex];

_playersSideNum = ((configFile >> "CfgFactionClasses" >> _playersFaction >> "side") call BIS_fnc_GetCfgData);
_enemySideNum = ((configFile >> "CfgFactionClasses" >> _enemyFaction >> "side") call BIS_fnc_GetCfgData);

_playersAdvGSide = if (count (lbData [3800, lbCurSel 3800]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3800, lbCurSel 3800]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};
_playersAdvASide = if (count (lbData [3801, lbCurSel 3801]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3801, lbCurSel 3801]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};
_playersAdvSSide = if (count (lbData [3802, lbCurSel 3802]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3802, lbCurSel 3802]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};

_enemyAdvGSide = if (count (lbData [3803, lbCurSel 3803]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3803, lbCurSel 3803]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};
_enemyAdvASide = if (count (lbData [3804, lbCurSel 3804]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3804, lbCurSel 3804]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};
_enemyAdvSSide = if (count (lbData [3805, lbCurSel 3805]) > 0) then {
	((configFile >> "CfgFactionClasses" >> (lbData [3805, lbCurSel 3805]) >> "side") call BIS_fnc_GetCfgData)
} else {
	-1
};

_continue = true;
if (_playersIndex == -1 || _enemyIndex == -1) then {
	hint "Both the player and enemy side must have a faction selected.";
	_continue = false;
} else {
	if (_playersSideNum == _enemySideNum) then {
		hint "Player and enemy factions are the same side. Please choose factions with differing sides.";
		_continue = false;
	} else {				
		
		if (_playersAdvGSide > -1 && _playersSideNum != _playersAdvGSide) then {_continue = false};
		if (_playersAdvASide > -1 && _playersSideNum != _playersAdvASide) then {_continue = false};
		if (_playersAdvSSide > -1 && _playersSideNum != _playersAdvSSide) then {_continue = false};
		
		if (_enemyAdvGSide > -1 && _enemySideNum != _enemyAdvGSide) then {_continue = false};
		if (_enemyAdvASide > -1 && _enemySideNum != _enemyAdvASide) then {_continue = false};
		if (_enemyAdvSSide > -1 && _enemySideNum != _enemyAdvSSide) then {_continue = false};
			
		if (_continue) then {
			playersFaction = lbData [2100, _playersIndex];
			publicVariable "playersFaction";		
			playersFactionAdv = [lbData [3800,  lbCurSel 3800], lbData [3801,  lbCurSel 3801], lbData [3802,  lbCurSel 3802]];
			publicVariable "playersFactionAdv";
			
			enemyFaction = lbData [2101, _enemyIndex];
			publicVariable "enemyFaction";		
			enemyFactionAdv = [lbData [3803,  lbCurSel 3803], lbData [3804,  lbCurSel 3804], lbData [3805,  lbCurSel 3805]];
			publicVariable "enemyFactionAdv";
			
			civFaction = lbData [2102, _civIndex];
			publicVariable "civFaction";		
			
			missionNameSpace setVariable ["factionsChosen", 1];
			publicVariable "factionsChosen";
			
			hintSilent  "";
			closeDialog 1;
			cutText ["Extracting faction data", "BLACK FADED"];
		} else {
			hint "One or more advanced factions have differing sides from the main faction.";
		};
		
	};
};
//hint format ["%1, %2", playersFaction, enemyFaction];

