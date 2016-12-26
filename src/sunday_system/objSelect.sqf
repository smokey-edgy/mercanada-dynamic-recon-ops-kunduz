scopeName "objSelection";
fnc_selectObjects = compile preprocessFile "sunday_system\objectsLibrary.sqf";

private ["_styles", "_destroyStyles", "_reconStyles", "_hvtStyles", "_powStyles"];

diag_log "DRO: Attempting to create new task";

_prevObj= "";
_prevObj = _this select 0;
if (!isNil "_prevObj") then {
	_prevObj = "";
};
_thisTask = nil;
_objectivePos = [0,0,0];

_markerColorPlayers = "";
_markerColorEnemy = "";

switch (enemySide) do {
	case west: {
		_markerColorEnemy = "colorBLUFOR";
	};
	case east: {
		_markerColorEnemy = "colorOPFOR";
	};
	case resistance: {
		_markerColorEnemy = "colorIndependent";
	};	
};
switch (side player) do {
	case west: {
		_markerColorPlayers = "colorBLUFOR";
	};
	case east: {
		_markerColorPlayers = "colorOPFOR";
	};
	case resistance: {
		_markerColorPlayers = "colorIndependent";
	};	
};

_thisObj = nil;

_styles = [];
_reconStyles = [];
_destroyStyles = [];
_hvtStyles = [];
_powStyles = [];
_heliTransports = [];

_styles pushBack "RECON";
_reconStyles pushBack "RECONRANGE";
_reconStyles pushBack "RECONFOOT";

if (count AO_roadPosArray > 0) then {
	if (count eCarClasses > 0) then {
		_styles pushBack "VEHICLE";
	};
};

if (count AO_buildingPositions > 1) then {
	_styles pushBack "BUILDING";
	_styles pushBack "INTEL";
	_hvtStyles pushBack "INSIDE";
	_powStyles pushBack "INSIDE";
};

if (count AO_forestPositions > 0) then {
	_powStyles pushBack "OUTSIDE";
	_styles pushBackUnique "CLEARLZ";
};

if (count AO_flatPositions > 1) then {
	if (count eArtyClasses > 0) then {
		_styles pushBack "ARTY";
	};
	if (count eMortarClasses > 0) then {				
		_destroyStyles pushBack "MORTAR";
	};
	/*
	if (count eHeliClasses > 0) then {
		_styles pushBack "HELI";	
	};
	*/
	_styles pushBackUnique "CLEARLZ";	
	_styles pushBack "CLEARBASE";	
	_hvtStyles pushBack "OUTSIDE";
	_destroyStyles pushBack "POWER";
	_destroyStyles pushBack "BOX";
};

if ((count eHeliClasses > 0 && (count AO_flatPositions > 2)) OR ((count eHeliClasses > 0) && count AO_helipads > 0)) then {
	_styles pushBack "HELI";
};

_pVehicleWreckClasses = (pCarClasses + pTankClasses + pHeliClasses);
if (count _pVehicleWreckClasses > 0 && count AO_flatPositions > 2) then {
	_destroyStyles pushBack "WRECK";
};

if (count eOfficerClasses > 0 && count _hvtStyles > 0) then {
	_styles pushBack "HVT";
};

if (count _destroyStyles > 0) then {
	_styles pushBack "DESTROY";
};

if (count _powStyles > 0) then {
	_styles pushBack "POW";
};

if (count _prevObj > 0) then {
	switch (_prevObj select 0) do {
		case "POW": {
			_styles = _styles - ["CLEARLZ", "CLEARBASE", "ARTY", "HELI", "VEHICLE", "BUILDING", "HVT"];
			_destroyStyles = _destroyStyles - ["MORTAR", "BOX"];
		};
		case "CLEARLZ": {
			_styles = _styles - ["POW"];
			_styles = _styles - ["CLEARLZ"];
		};
		case "CLEARBASE": {
			_styles = _styles - ["POW"];
			_styles = _styles - ["CLEARBASE"];
		};
		case "ARTY": {
			_styles = _styles - ["POW"];
		};
		case "HELI": {
			_styles = _styles - ["POW"];
		};
		case "VEHICLE": {
			_styles = _styles - ["POW"];
		};
		case "BUILDING": {
			_styles = _styles - ["POW"];
		};
		case "HVT": {
			_styles = _styles - ["POW"];
		};
		case "DESTROY": {
			switch (_prevObj select 1) do {
				case "MORTAR": {
					_styles = _styles - ["POW"];
				};
				case "BOX": {
					_styles = _styles - ["POW"];
				};
			};
		};
	};
};


_select = selectRandom _styles;

//_select = "POW";
//_destroyStyles = ["POWER"];
//_reconStyles = ["RECONFOOT"];

diag_log format ["DRO: New task will be %1", _select];

switch (_select) do {
	case "HVT": {			
		[_hvtStyles] execVM "sunday_system\objectives\hvt.sqf";		
	};
	case "DESTROY": {
		_destroySelect = selectRandom _destroyStyles;		
		switch (_destroySelect) do {
			case "MORTAR": {
				[] execVM "sunday_system\objectives\destroyMortar.sqf";	
			};
			case "WRECK": {
				[_pVehicleWreckClasses] execVM "sunday_system\objectives\destroyWreck.sqf";					
			};
			case "BOX": {
				[] execVM "sunday_system\objectives\destroyCache.sqf";					
			};
			case "POWER": {
				[] execVM "sunday_system\objectives\destroyPower.sqf";				
			};
		};
	};	
	case "POW": {
		[_powStyles] execVM "sunday_system\objectives\pow.sqf";			
	};
	case "VEHICLE": {
		[] execVM "sunday_system\objectives\vehicle.sqf";			
	};
	case "ARTY": {
		[] execVM "sunday_system\objectives\artillery.sqf";		
	};
	case "BUILDING": {
		[] execVM "sunday_system\objectives\building.sqf";				
	};
	case "HELI": {
		[] execVM "sunday_system\objectives\heli.sqf";	
	};
	case "CLEARLZ": {
		[] execVM "sunday_system\objectives\clearArea.sqf";		
	};
	case "CLEARBASE": {
		[] execVM "sunday_system\objectives\clearBase.sqf";				
	};
	case "INTEL": {
		[] execVM "sunday_system\objectives\intel.sqf";		
	};
	case "RECON": {
		_reconSelect = selectRandom _reconStyles;
		switch (_reconSelect) do {
			case "RECONRANGE": {
				[] execVM "sunday_system\objectives\reconRange.sqf";		
			};
			case "RECONFOOT": {
				[] execVM "sunday_system\objectives\reconFoot.sqf";		
			};
		};
	};
	
};

_return = [_select, _destroyStyles];
_return