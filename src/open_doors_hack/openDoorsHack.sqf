MC_fnc_nearestBuilding = {
  private ["_nearestBuildings"];
  _nearestBuildings = nearestObjects [position player, ["building"], 10];
  _nearestBuildings select 0;
};

MC_fnc_doorsInBuilding = {
  params ["_building"];
  animationNames _building;
};

player addAction ["***Open doorz***", {
  private ["_nearestBuilding"];

  _nearestBuilding = (call MC_fnc_nearestBuilding);
  {
    _nearestBuilding animate [_x, 1, 0.7];
  } forEach ([_nearestBuilding] call MC_fnc_doorsInBuilding);
}];

player addAction ["***Close doorz***", {
  private ["_nearestBuilding"];

  _nearestBuilding = (call MC_fnc_nearestBuilding);
  {
    _nearestBuilding animate [_x, 0, 0.7];
  } forEach ([_nearestBuilding] call MC_fnc_doorsInBuilding);
}];
