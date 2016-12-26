_loadout = player getVariable "respawnLoadout";
player setUnitLoadout _loadout;
if (count (player getVariable "respawnPWeapon") > 0) then {
	if (count (primaryWeapon player) == 0) then {		
		player addWeapon ((player getVariable "respawnPWeapon") select 0);
		{
			[player, _x] call addWeaponItemEverywhere;
		} forEach ((player getVariable "respawnPWeapon") select 1);		
	};
};

player enableFatigue false;
	
player addAction ["***Open doorz***", {
  _nearestBuildings = nearestObjects [position player, ["building"], 10];
  _nearest = (_nearestBuildings select 0);
  _names = animationNames _nearest;

  {
    _nearest animate [_x, 1, 0.7];
  } forEach _names;
}];

player addAction ["***Close doorz***", {
  _nearestBuildings = nearestObjects [position player, ["building"], 10];
  _nearest = (_nearestBuildings select 0);
  _names = animationNames _nearest;

  {
    _nearest animate [_x, 0, 0.7];
  } forEach _names;
}];

//_handler = (_this select 0) addEventHandler ["HandleDamage", rev_handleDamage];
