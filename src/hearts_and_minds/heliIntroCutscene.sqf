0 = [] spawn {
  _hours = "";
  if ((date select 3) < 10) then {
  	_hours = format ["0%1", (date select 3)];
  } else {
  	_hours = str (date select 3);
  };

  _minutes = "";
  if ((date select 4) < 10) then {
  	_minutes = format ["0%1", (date select 4)];
  } else {
  	_minutes = str (date select 4);
  };
  [parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1  %2</t>", str(date select 1) + "." + str(date select 2) + "." + str(date select 0), _hours + _minutes + " HOURS"], true, nil, 15, 0.7, 0] spawn BIS_fnc_textTiles;
};

_worldCenter = worldSize / 2;
_result = [[_worldCenter, _worldCenter], random 360, "B_Heli_Transport_01_F", playerSide] call BIS_fnc_spawnVehicle;
_heli = (_result select 0);

{
  _x moveInCargo _heli;
} forEach units group player;

_fobWestHelipad = [47.574, 561.639, 50];
_outsideWorld = [worldSize + 100, worldSize + 100, 500];

_wp = group _heli addWaypoint [_fobWestHelipad, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "FULL";
_wp setWaypointStatements ["true", "_heli = (vehicle this); _heli land ""LAND"";"];

waitUntil {
  _numberOfUnitsInHeli = count (units group player);
  {
    if(!(_x in _heli)) then {
      _numberOfUnitsInHeli = _numberOfUnitsInHeli - 1;
    };
  } forEach units group player;
  _numberOfUnitsInHeli == 0
};

_wp = group _heli addWaypoint [_outsideWorld, 0];
_wp setWaypointType "MOVE";
_wp setWaypointStatements ["true", "{deleteVehicle _x} forEach crew (vehicle this) + [(vehicle this)];"];
_wp setWaypointSpeed "FULL";

sleep 10;

heliIntroCutsceneDone = true;
