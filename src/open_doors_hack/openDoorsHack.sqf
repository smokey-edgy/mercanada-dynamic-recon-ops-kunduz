MC_fnc_nearestBuilding = {
  private ["_nearestBuildings", "_nearestBuilding"];
  _nearestBuildings = nearestObjects [position player, ["building"], 10];
  _nearestBuildings select 0;
};

MC_fnc_closestBuildingDoorToPlayer = {
  params ["_building"];
  private ["_door", "_doors", "_i", "_selectionPos", "_worldSpace"];

  _doors = getNumber(configFile >> "CfgVehicles" >> (typeOf _building) >> "numberOfDoors");

  for "_i" from 1 to _doors do {
  	_selectionPos = _building selectionPosition format["Door_%1",_i];
  	_worldSpace = _building modelToWorld _selectionPos;
  	if(player distance _worldSpace < 2.4) exitWith {_door = format["Door_%1", _i]};
  };

  if(!isNil "_door") then {
    _door;
  };
};

player addAction ["***Open doorz***", {
  private ["_nearestBuilding", "_nearestDoor", "_nearestDoorAnimation"];

  _nearestBuilding = (call MC_fnc_nearestBuilding);
  if(!isNil "_nearestBuilding") then {
    _nearestDoor = ([_nearestBuilding] call MC_fnc_closestBuildingDoorToPlayer);
    if(!isNil "_nearestDoor") then {
      _nearestDoorAnimation = format ["%1_rot", _nearestDoor];
      _nearestBuilding animate [_nearestDoorAnimation, 1, 0.7];
    };
  };
}];

player addAction ["***Close doorz***", {
  private ["_nearestBuilding", "_nearestDoor", "_nearestDoorAnimation"];

  _nearestBuilding = (call MC_fnc_nearestBuilding);
  if(!isNil "_nearestBuilding") then {
    _nearestDoor = ([_nearestBuilding] call MC_fnc_closestBuildingDoorToPlayer);
    if(!isNil "_nearestDoor") then {
      _nearestDoorAnimation = format ["%1_rot", _nearestDoor];
      _nearestBuilding animate [_nearestDoorAnimation, 0, 0.7];
    };
  };
}];
