markerRespawnTeam = createMarker ["respawn", (getPos groupLeader)];
markerRespawnTeam setMarkerShape "ICON";
markerRespawnTeam setMarkerColor "ColorGreen";
markerRespawnTeam setMarkerType "mil_flag";
markerRespawnTeam setMarkerAlpha 0;
respawnTeam = [missionNamespace, "respawn", "Team"] call BIS_fnc_addRespawnPosition;
_savedPositions = [];

while {true} do {
	sleep 10;
	_unitPositions = [];
	{
		if (alive _x) then {
			_unitPositions pushBack (getPos _x);
		};
	} forEach (units(DROgroupPlayers));	
	_avgPos = [];
	if (count _unitPositions > 0) then {
		_avgPos = [_unitPositions] call sun_avgPos;
		
		if (count _savedPositions > 0) then {
			if ((_avgPos distance (_savedPositions select (count _savedPositions - 1))) > 50) then {
				_savedPositions pushBack _avgPos;
			};
		} else {
			_savedPositions pushBack _avgPos;
		};
		
		if (count _savedPositions > 30) then {
			_savedPositions deleteAt 0;
		};
		/*
		_mkrPos = createMarker [(format ["mkrPos%1", random 10000]), _avgPos];
		_mkrPos setMarkerShape "ICON";
		_mkrPos setMarkerColor "ColorOrange";
		_mkrPos setMarkerType "mil_dot";	
		*/
		_usablePositions = [];
		{
			if (_x distance _avgPos > 160) then {
				_usablePositions pushBack _x;
			};
		} forEach _savedPositions;
				
		if (count _usablePositions > 0) then {
			_current = _usablePositions select 0;
			_desiredDist = 200;
			{
				_thisDistance = _avgPos distance _x;
				_selectedDistance = _current distance _avgPos;
				if (abs (_desiredDist - _thisDistance) < abs (_desiredDist - _selectedDistance)) then {
					_current = _x;
				};
			} forEach _usablePositions;
			markerRespawnTeam setMarkerPos _current;
			/*
			deleteMarker "mkrPosSelect";		
			_mkrPos2 = createMarker ["mkrPosSelect", _current];
			_mkrPos2 setMarkerShape "ICON";
			_mkrPos2 setMarkerColor "ColorGreen";
			_mkrPos2 setMarkerType "mil_circle";
			*/
		} else {
			_dir = [trgAOC, _avgPos] call BIS_fnc_dirTo;
			_spawnPos = [_avgPos, 200, _dir] call dro_extendPos;
			markerRespawnTeam setMarkerPos _spawnPos;
		};	
	} else {
		_dir = [trgAOC, (getPos groupLeader)] call BIS_fnc_dirTo;
		_spawnPos = [(getPos groupLeader), 200, _dir] call dro_extendPos;
		markerRespawnTeam setMarkerPos _spawnPos;
	};
};	