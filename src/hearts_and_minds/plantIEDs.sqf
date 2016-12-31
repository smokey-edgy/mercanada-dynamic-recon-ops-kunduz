params ["_position"];
private ["_randomNearbyPoint"];

HM_fnc_pointInCircle = {
  params ["_originX", "_originY", "_radius"];
  private ["_angle", "_r", "_x", "_y", "_z"];

  _angle = (random 1) * 360;
  _r = (sqrt (random 1)) * _radius;
  _x = _originX + _r * (cos _angle);
  _y = _originY + _r * (sin _angle);
  _z = 0;
  [_x, _y, _z]
};

HM_fnc_randomPointAroundPositionWithinRadius = {
  params ["_pos", "_radius"];
  private ["_x", "_y"];

  _x = _pos select 0;
  _y = _pos select 1;
  ([_x, _y, _radius] call HM_fnc_pointInCircle)
};

HM_fnc_plantIED = {
  params ["_pos"];
  private ["_ied", "_trigger"];

  _ied = "IEDLandSmall_Remote_Ammo" createVehicle _pos;

  _trigger = createTrigger ["EmptyDetector", _pos];
  _trigger setTriggerArea  [1, 1, 0, false];
  _trigger setTriggerActivation ["ANY", "PRESENT", true];
  _trigger setTriggerStatements ["count thisList > 0;", "_ied = (nearestObject [thisTrigger, ""IEDLandSmall_Remote_Ammo""]);
                                          _ied setDamage 1;
                                          ",
                                          ""];
};

for [{_i=0}, {_i<1000}, {_i=_i+1}] do
{
  _randomNearbyPoint = ([_position, 2000] call HM_fnc_randomPointAroundPositionWithinRadius);
  ([_randomNearbyPoint] call HM_fnc_plantIED);
};
