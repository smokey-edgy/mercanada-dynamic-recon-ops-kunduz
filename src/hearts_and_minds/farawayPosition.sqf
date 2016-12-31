params ["_position"];
private ["_xPos", "_yPos", "_farawayX", "_farawayY", "_size", "_worldCenter", "_scale"];

_scale = 0.66;

_xPos = (_position select 0) * _scale;
_yPos = (_position select 1) * _scale;

_size = worldSize * _scale;
diag_log format ["_worldSize is %1, scaling it by %2 to _size", worldSize, _scale, _size];

_worldCenter = (_size/2);

if(_xPos < _worldCenter) then {
  diag_log format ["HM_fnc_farawayPosition: [%1, %2] means your faraway X is to the rightmost edge of the map", _xPos, _yPos];
  _farawayX = _size;
};

if(_xPos > _worldCenter) then {
  diag_log format ["HM_fnc_farawayPosition: [%1, %2] means your faraway X is to the leftmost edge of the map", _xPos, _yPos];
  _farawayX = 0;
};

if(_yPos < _worldCenter) then {
  diag_log format ["HM_fnc_farawayPosition: [%1, %2] means your faraway Y is at the bottom of the map", _xPos, _yPos];
  _farawayY = 0;
};

if(_yPos > _worldCenter) then {  
  diag_log format ["HM_fnc_farawayPosition: [%1, %2] means your faraway Y is at the top of the map", _xPos, _yPos];
  _farawayY = _size;
};

[_farawayX, _farawayY];
