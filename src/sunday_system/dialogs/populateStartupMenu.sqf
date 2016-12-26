
disableSerialization;
/*
{
	((findDisplay 52525) displayCtrl (ctrlIDC _x)) ctrlSetFade 1;
	((findDisplay 52525) displayCtrl (ctrlIDC _x)) ctrlCommit 0;	
} forEach (allControls findDisplay 52525);
*/
{	
	((findDisplay 52525) displayCtrl (ctrlIDC _x)) ctrlSetFade 0;
	if (ctrlIDC _x < 3000) then {
		((findDisplay 52525) displayCtrl (ctrlIDC _x)) ctrlCommit 0.3;
	}; 		
} forEach (allControls findDisplay 52525);

_index = lbAdd [2103, "Random"];
_index = lbAdd [2103, "Dawn"];
_index = lbAdd [2103, "Day"];
_index = lbAdd [2103, "Dusk"];
_index = lbAdd [2103, "Night"];

_index = lbAdd [2105, "Action - Normal"];
_index = lbAdd [2105, "Action - Hard"];
_index = lbAdd [2105, "Realism"];

_index = lbAdd [2106, "Random"];
_index = lbAdd [2106, "1"];
_index = lbAdd [2106, "2"];
_index = lbAdd [2106, "3"];

_index = lbAdd [2107, "Random"];
_index = lbAdd [2107, "Small"];
_index = lbAdd [2107, "Medium"];
_index = lbAdd [2107, "Large"];

_index = lbAdd [2108, "Enabled - 300 seconds"];
_index = lbAdd [2108, "Enabled - 120 seconds"];
_index = lbAdd [2108, "Enabled - 60 seconds"];
_index = lbAdd [2108, "Disabled"];

lbSetCurSel [2103, timeOfDay];
lbSetCurSel [2105, aiSkill];
lbSetCurSel [2106, numObjectives];
lbSetCurSel [2107, aoOptionSelect];
lbSetCurSel [2108, reviveDisabled];

if (!isNil "aoName") then {
	ctrlSetText [2202, format ["AO location: %1", aoName]];
};

{
	_indexP = lbAdd [_x, "NONE"];					
	lbSetData [_x, _indexP, ""];
	lbSetColor [_x, _indexP, [1, 1, 1, 1]];	
} forEach [3800, 3801, 3802, 3803, 3804, 3805];	

{	
	_thisFaction = (_x select 0);
	_thisFactionName = (_x select 1);
	_thisFactionFlag = (_x select 2);
	_thisSideNum = (_x select 3);
	// Add factions to combo boxes
	_color = "";
	switch (_thisSideNum) do {
		case 1: {
			_color = [0, 0.3, 0.6, 1];
		};
		case 0: {
			_color = [0.5, 0, 0, 1];
		};
		case 2: {
			_color = [0, 0.5, 0, 1];
		};
		case 3: {
			_color = [1, 1, 1, 1];
		};						
	};				
	if (_thisSideNum == 3) then {
		_indexC = lbAdd [2102, _thisFactionName];					
		lbSetData [2102, _indexC, _thisFaction];
		lbSetColor [2102, _indexC, _color];
		if (!isNil "_thisFactionFlag") then {
			if (count _thisFactionFlag > 0) then {
				lbSetPicture [2102, _indexC, _thisFactionFlag];
				lbSetPictureColor [2102, _indexC, [1, 1, 1, 1]];
				lbSetPictureColorSelected [2102, _indexC, [1, 1, 1, 1]];
			};
		};
	} else {
		{
			_indexP = lbAdd [_x, _thisFactionName];					
			lbSetData [_x, _indexP, _thisFaction];
			lbSetColor [_x, _indexP, _color];
			if (!isNil "_thisFactionFlag") then {
				if (count _thisFactionFlag > 0) then {
					lbSetPicture [_x, _indexP, _thisFactionFlag];
					lbSetPictureColor [_x, _indexP, [1, 1, 1, 1]];
					lbSetPictureColorSelected [_x, _indexP, [1, 1, 1, 1]];
				};
			};
		} forEach [2100, 3800, 3801, 3802];	
		
		{
			_indexE = lbAdd [_x, _thisFactionName];					
			lbSetData [_x, _indexE, _thisFaction];
			lbSetColor [_x, _indexE, _color];
			if (!isNil "_thisFactionFlag") then {
				if (count _thisFactionFlag > 0) then {
					lbSetPicture [_x, _indexE, _thisFactionFlag];
					lbSetPictureColor [_x, _indexE, [1, 1, 1, 1]];
					lbSetPictureColorSelected [_x, _indexE, [1, 1, 1, 1]];
				};
			};
		} forEach [2101, 3803, 3804, 3805];		
		
	};				
} forEach availableFactionsData;

lbSetCurSel [2100, pFactionIndex];
lbSetCurSel [2101, eFactionIndex];
lbSetCurSel [2102, cFactionIndex];

lbSetCurSel [3800, (playersFactionAdv select 0)];
lbSetCurSel [3801, (playersFactionAdv select 1)];
lbSetCurSel [3802, (playersFactionAdv select 2)];
lbSetCurSel [3803, (enemyFactionAdv select 0)];
lbSetCurSel [3804, (enemyFactionAdv select 1)];
lbSetCurSel [3805, (enemyFactionAdv select 2)];
