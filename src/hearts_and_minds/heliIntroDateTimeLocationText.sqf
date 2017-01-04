[["", "BLACK FADED"], "cutText", true] call BIS_fnc_MP;

sleep 3;

[["", "BLACK IN", 5], "titleCut", true] call BIS_fnc_MP;

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

[parseText format [ "<t font='EtelkaMonospaceProBold' color='#ffffff' size = '1.7'>%1  %2</t>", str(date select 1) + "." + str(date select 2) + "." + str(date select 0), _hours + _minutes + " HOURS<br/>KUNDUZ PROVINCE<br/>AFGHANISTAN"], true, nil, 15, 0.7, 0] spawn BIS_fnc_textTiles;
