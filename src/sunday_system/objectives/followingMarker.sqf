private ["_object", "_task"];
_object = (_this select 0);
_task = (_this select 1);

_followMarkerName = format["followMkr%1", floor(random 10000)];		
_followMarker = createMarker [_followMarkerName, (getPos _object)];
_followMarker setMarkerShape "ELLIPSE";		
_followMarker setMarkerBrush "Solid";
_followMarker setMarkerSize [200, 200];
_followMarker setMarkerAlpha 0.5;
_followMarker setMarkerColor markerColorEnemy;

while {true} do {
	sleep 30;
	_alpha = markerAlpha _followMarker;
	for "_i" from 1 to 20 do {
		sleep 0.1;
		_alpha = _alpha - 0.025;
		_followMarker setMarkerAlpha _alpha;
	};
	_followMarker setMarkerAlpha 0;
	_extendPos = [(getPos _object), (random 200), (random 360)] call dro_extendPos;
	_followMarker setMarkerPos _extendPos;
	[_task, _extendPos] call BIS_fnc_taskSetDestination;
	for "_i" from 1 to 20 do {
		sleep 0.1;
		_alpha = _alpha + 0.025;
		_followMarker setMarkerAlpha _alpha;
	};
	_followMarker setMarkerAlpha 0.5;
	if (!alive _object) exitWith {
		_followMarker setMarkerAlpha 0;
	};
};