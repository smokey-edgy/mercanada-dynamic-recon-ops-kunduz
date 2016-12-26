if (!isNil "camLobby") then {
	camLobby cameraEffect ["terminate","back"];
	camDestroy camLobby;
};

_playerPos = [((getPos player) select 0), ((getPos player) select 1), (((getPos player) select 2)+1.2)];
_camLobbyStartPos = [(getPos player), 5, (getDir player)-35] call Zen_ExtendPosition;
_camLobbyStartPos = [(_camLobbyStartPos select 0), (_camLobbyStartPos select 1), (_camLobbyStartPos select 2)+1];
/*
if (!isNil "camLobbyPos") then {
	_camLobbyStartPos = camLobbyPos;
};
_timeRemaining = 0;
if (!isNil "camLobbyTimePaused") then {
	if (!isNil "camLobbyTimeCreated") then {
		_timeRemaining = camLobbyTimePaused - camLobbyTimeCreated;
	};
};
*/
//camLobbyTimeCreated = time;
camLobby = "camera" camCreate _camLobbyStartPos;
camLobby cameraEffect ["internal", "BACK"];
camLobby camSetPos _camLobbyStartPos;
camLobby camSetTarget _playerPos;
camLobby camCommit 0;
cameraEffectEnableHUD false;
_camLobbyEndPos = [(getPos player), 5, (getDir player)+35] call Zen_ExtendPosition;
_camLobbyEndPos = [(_camLobbyEndPos select 0), (_camLobbyEndPos select 1), (_camLobbyEndPos select 2)+1];
camLobby camPreparePos _camLobbyEndPos;
camLobby camPrepareTarget _playerPos;
camLobby camCommitPrepared 120;