private ["_objData", "_taskName", "_taskDesc", "_taskTitle", "_markerName", "_taskType", "_taskPos", "_reconComplete"];

_objData = _this select 0;
_taskName = _objData select 0;
_taskDesc = _objData select 1;
_taskTitle = _objData select 2;
_markerName = _objData select 3;
_taskType = _objData select 4;
_taskPos = _objData select 5;

_taskPosFakeTemp = getMarkerPos _markerName;
_taskPosFake = [(_taskPosFakeTemp select 0), (_taskPosFakeTemp select 1), 0];

_reconTaskName = format ["task%1", floor(random 100000)];
_reconTaskDesc = format ["Recon the area at grid %1 from a safe observation distance.", (mapGridPosition _taskPosFake)];
_reconTaskTitle = "Observe";		

_reconMarkerName = format["reconMkr%1", floor(random 100000)];		
_reconMarker = createMarker [_reconMarkerName, _taskPosFake];
_reconMarker setMarkerShape "ICON";
_reconMarker setMarkerAlpha 0;
_reconMarkerPos = [(_taskPosFake select 0), (_taskPosFake select 1), 0];

//[(group u1), _reconTaskName, [_reconTaskDesc, _reconTaskTitle, _reconMarkerName], _reconMarkerPos, "CREATED", 1, false, "scout", false] call BIS_fnc_taskCreate;
_id = [_reconTaskName, true, [_reconTaskDesc, _reconTaskTitle, _reconMarkerName], _reconMarkerPos, "CREATED", 1, false, true, "scout", true] call BIS_fnc_setTask;
taskIDs pushBack _id;
diag_log format ["DRO: taskIDs is now: %1", taskIDs];
allObjectives pushBack _reconTaskName;
[_reconMarkerPos, _reconTaskName] execVM "sunday_system\objectives\addTaskExtras.sqf";

_reconComplete = false;

missionNamespace setVariable [_taskName, 0, true];

while {!_reconComplete} do {
	sleep 5;
	{		
		_unit = _x;
		if (isPlayer _unit) then {			
			[_taskName, _reconMarkerPos] remoteExec ["dro_detectPosMP", _unit, false];			
		};
	} forEach (units DROgroupPlayers);
	
	if ((missionNamespace getVariable _taskName) >= 2) then {
		_reconComplete = true;		
		_createType = "CREATED";		
		_completed = (missionNamespace getVariable [(format ["%1Completed", _taskName]), 0]);
		if (_completed == 1) then {
			_createType = "SUCCEEDED";
		};
		//[(group u1), _taskName, [_taskDesc, _taskTitle, _markerName], _taskPos, _createType, 1, true, _taskType, false] call BIS_fnc_taskCreate;
		_id = [_taskName, true, [_taskDesc, _taskTitle, _markerName], _taskPos, _createType, 1, false, true, _taskType, true] call BIS_fnc_setTask;
		taskIDs pushBack _id;
		diag_log format ["DRO: taskIDs is now: %1", taskIDs];
		[_taskPos, _taskName] execVM "sunday_system\objectives\addTaskExtras.sqf";
		
		if (markerShape _markerName == "ICON") then {
			_markerName setMarkerAlpha 0;
		} else {
			_markerName setMarkerAlpha 0.5;
		};
		
		[_reconTaskName, "SUCCEEDED", true] spawn BIS_fnc_taskSetState;
	};
	
};
