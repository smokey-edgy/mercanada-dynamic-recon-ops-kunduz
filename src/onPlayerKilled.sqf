if (isMultiplayer) then {
	player setVariable ["respawnLoadout", (getUnitLoadout player)];
	if ((paramsArray select 0) == 1) then {
		[player, -2000, true] call BIS_fnc_respawnTickets;
		diag_log ([player, 0, true] call BIS_fnc_respawnTickets);
		[missionNamespace, -2000] call BIS_fnc_respawnTickets;
		//setPlayerRespawnTime 0;
	};

	[] execVM "open_doors_hack\openDoorsHack.sqf";
};
