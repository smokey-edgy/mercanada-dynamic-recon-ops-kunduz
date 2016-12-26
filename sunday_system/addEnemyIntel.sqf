
_leaders = [];
{
	if ((count units _x)>=2) then {
		if (side _x == enemySide) then {
			_leaders pushBack (leader _x);
		};
	};
} forEach allGroups;


{		
	[
		_x,
		"Search for Intel",
		"\A3\ui_f\data\igui\cfg\simpleTasks\types\documents_ca.paa",
		"\A3\ui_f\data\igui\cfg\simpleTasks\types\documents_ca.paa",
		"(!alive _target) && ((_this distance _target) < 3)",
		"((_this distance _target) < 3)",
		{playSound "BIS_Steerable_Parachute_Opening"},
		{
			if ((_this select 4) % 5 == 0) then {
				_object = [
					(selectRandom ["Land_Document_01_F", "Land_File1_F", "Land_FilePhotos_F", "Land_File2_F", "Land_File_research_F", "Land_Notepad_F", "Item_ItemGPS", "Land_MobilePhone_old_F", "Land_PortableLongRangeRadio_F"]),
					([(getPos (_this select 0)), 0.7, (random 360)] call dro_extendPos),
					(random 360)
				] call dro_createSimpleObject;
				(_this select 0) setVariable ["intelObjects", (((_this select 0) getVariable ["intelObjects", []]) + [_object])];
			};
		},
		{
			if ((random 1) > 0.3) then {
				[([1,3] call BIS_fnc_randomInt), true] call dro_revealMapIntel;
			};			
			{
				deleteVehicle _x;			
			} forEach ((_this select 0) getVariable ["intelObjects", []]);
		},
		{
			{
				deleteVehicle _x;
			} forEach ((_this select 0) getVariable ["intelObjects", []]);
		},
		[],
		10,
		10,
		true,
		false
	] remoteExec ["bis_fnc_holdActionAdd", 0, true];	
} forEach _leaders;
