private ["_objectivePos", "_thisTask"];

_objectivePos = _this select 0;
_thisTask = _this select 1;

// Set reinforcements on task completion
_reinfChance = (random 100);
if (_reinfChance > 30) then {
	_trgReinforce = createTrigger ["EmptyDetector", _objectivePos, true];
	_trgReinforce setTriggerArea [300, 300, 0, false];
	_trgReinforce setTriggerActivation ["ANY", "PRESENT", false];
	_trgReinforce setTriggerStatements [
		"
			[(thisTrigger getVariable 'thisTask')] call BIS_fnc_taskCompleted
		",
		"	
			diag_log 'Reinforcing due to task completion';
			_enemyArray = [];
			[(thisTrigger getVariable 'pos'), [1,2]] execVM 'sunday_system\reinforce.sqf';
			{ if (side _x == (thisTrigger getVariable 'side')) then {_enemyArray = _enemyArray + [_x]} } forEach thisList;
			{[group _x, (thisTrigger getVariable 'pos')] call BIS_fnc_taskAttack} forEach _enemyArray;
		", 
		""];
	_trgReinforce setVariable ["thisTask", _thisTask];
	_trgReinforce setVariable ["pos", _objectivePos];
	_trgReinforce setVariable ["side", enemySide];
};

// Add cancel button to task
_taskData = [_thisTask] call BIS_fnc_taskDescription;
_taskDesc = (_taskData select 0) select 0;
_taskTitle = _taskData select 1;
_taskMarker = _taskData select 2;
_taskDescNew = format ["%1<br /><br /><execute expression='[""%2"", ""CANCELED"", true] spawn BIS_fnc_taskSetState;'>Cancel task</execute>", _taskDesc, _thisTask];

[_thisTask, [_taskDescNew, _taskTitle, _taskMarker]] call BIS_fnc_taskSetDescription;