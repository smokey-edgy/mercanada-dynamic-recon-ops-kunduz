SE_fnc_nearestRoad = {
  params ["_xPos", "_yPos"];
  private ["_distances", "_nearestRoad"];

  _distances = [5, 10, 100, 500, 1000, 2000, 5000, 10000, 50000];

  {
    scopeName "findingNearestRoad";

    _nearestRoad = [_xPos, _yPos] nearRoads _x select 0;
    if (!isNil "_nearestRoad") then {
      breakOut "findingNearestRoad";
    };
  } forEach _distances;

  _nearestRoad
};

HM_fnc_spawnAnaSquad = {
  params ["_xPos", "_yPos"];
  private ["_patrolGroup", "_leader", "_nearestRoad", "_nearestCity", "_wp", "_combatPosition"];

  _nearestRoad = ([_xPos, _yPos] call SE_fnc_nearestRoad);

  _patrolGroup = [position _nearestRoad, playerSide, 13] call BIS_fnc_spawnGroup;
  _patrolGroup setFormation "FILE";
  _patrolGroup setCombatMode "YELLOW";
  _leader = leader _patrolGroup;
  _leader switchMove "";

  _nearestCity = (nearestLocations [[_xPos, _yPos], ["NameLocal","NameVillage","NameCity","NameCityCapital"], 5000]) select 0;

  _combatPosition = [];
  _combatPosition pushBack (position _nearestCity select 0) - 50;
  _combatPosition pushBack (position _nearestCity select 1) - 50;
  _combatPosition pushBack (position _nearestCity select 2);

  _wp = _patrolGroup addWaypoint [_combatPosition, 0];
  _wp setWaypointSpeed "LIMITED";
  _wp setWaypointBehaviour "CARELESS";
  _wp setWaypointType "MOVE";

  _wp = _patrolGroup addWaypoint [position _nearestCity, 0];
  _wp setWaypointSpeed "LIMITED";
  _wp setWaypointBehaviour "COMBAT";
  _wp setWaypointType "SAD";
};

HM_fnc_spawnOpforInCompounds = {
  params ["_xPos", "_yPos"];
  private ["_opFor", "_nearestCity", "_wp", "_nearestCompounds", "_compound", "_opForPos", "_buildingPositions"];

  _nearestCity = (nearestLocations [[_xPos, _yPos], ["NameLocal","NameVillage","NameCity","NameCityCapital"], 5000]) select 0;
  _bestCompounds = selectBestPlaces [position _nearestCity, 500, "houses", 1, 10];

  {
    _spawnPos = _x select 0;
    _compound = nearestBuilding _spawnPos;
    _buildingPositions = (_compound buildingPos -1) select [0, 2];
    {
      systemChat format ["pos %1", _x];
      _opFor = [_x, opfor, 2] call BIS_fnc_spawnGroup;
    } forEach _buildingPositions;
  } forEach _bestCompounds;
};

_xPos = position player select 0;
_yPos = position player select 1;

([_xPos, _yPos] call HM_fnc_spawnAnaSquad);
([_xPos, _yPos] call HM_fnc_spawnOpforInCompounds);
