removeRangefinderArray = {
	private "_remove";
	_remove = _this findIf { (_x # 0) == "Rangefinder" };
	if (_remove > -1) then {
		_this deleteAt _remove;
	};
};
addWeaponsToArray = {
	params ["_obj", "_weapons"];
	{ _weapons pushBack _x } forEach (weaponsItems _obj);
	clearWeaponCargoGlobal _obj;
};
addWeaponsToCargo = {
	params ["_weapons", "_vehicle"];
	private ["_snapshot", "_output", "_return", "_remove"];
	_remove = [];
	{
		_output = [_x, _vehicle] call addWeaponToCargoWithOutput;
		if (_output) then {
			_remove pushBack _x;
		};
	} forEach _weapons;
	{
		_weapons deleteAt (_weapons find _x);
	} forEach _remove;
	_weapons;
};
addWeaponToCargoWithOutput = {
	params ["_weapon", "_vehicle"];
	private ["_vehicleMaxLoad", "_vehicleCurrentLoad", "_weaponLoad", "_output"];
	_vehicleMaxLoad = getNumber(configFile >> "CfgVehicles" >> typeOf _vehicle >> "maximumLoad" );
	_vehicleCurrentLoad = loadAbs _vehicle;
	_weaponLoad = getNumber(configFile >> "CfgWeapons" >> _weapon # 0 >> "WeaponsSlotsInfo" >> "mass");
	_weaponLoad = _weapon call getWeaponLoad;
	_output = (_vehicleMaxLoad - _vehicleCurrentLoad) > _weaponLoad;
	if (_output) then {
		_vehicle addWeaponWithAttachmentsCargoGlobal [_weapon, 1];
	} else {
		_vehicle setVariable ["DE_FULL_VEHICLE", true];
	};
	_output;
};

getWeaponLoadArray = {
	//TODO: clean this garbage up
	params ["_weapon", "_muzzle", "_acc", "_optic", "_ammo", "_ammo2", "_bipod"];
	private ["_weaponLoad", "_muzzleLoad", "_accLoad", "_opticLoad", "_ammoLoad", "_ammo2Load", "_bipodLoad"];
	//for weapon is CfgVehicles >> weapon >> WeaponSlotsInfo >> mass
	//for attachment is CfgVehicles >> attachment >> ItemInfo >> mass
	//for ammo is CfgMagazines >> magazine >> mass
	_weaponLoad = getNumber (configFile >> "CfgWeapons" >> _weapon >> "WeaponSlotsInfo" >> "mass");
	if (_muzzle isEqualTo "") then {
		_muzzleLoad = 0;
	} else {
		_muzzleLoad = getNumber (configFile >> "CfgWeapons" >> _muzzle >> "ItemInfo" >> "mass");
	};
	if (_acc isEqualTo "") then {
		_accLoad = 0;
	} else {
		_accLoad = getNumber (configFile >> "CfgWeapons" >> _acc >> "ItemInfo" >> "mass");
	};
	if (_optic isEqualTo "") then {
		_opticLoad = 0;
	} else {
		_opticLoad = getNumber (configFile >> "CfgWeapons" >> _optic >> "ItemInfo" >> "mass");
	};
	if (_ammo isEqualTo []) then {
		_ammoLoad = 0;
	} else {
		_ammoLoad = getNumber (configFile >> "CfgMagazines" >> _ammo # 0 >> "mass");
	};
	if (_ammo2 isEqualTo []) then {
		_ammo2Load = 0;
	} else {
		_ammo2Load = getNumber (configFile >> "CfgMagazines" >> _ammo2 # 0 >> "mass");
	};
	if (_bipod isEqualTo "") then {
		_bipodLoad = 0;
	} else {
		_bipodLoad = getNumber (configFile >> "CfgWeapons" >> _bipod >> "ItemInfo" >> "mass");
	};
	[_weaponLoad, _muzzleLoad, _accLoad, _opticLoad, _ammoLoad, _ammo2Load, _bipodLoad];
};
getWeaponLoad = {
	private "_output";
	_output = _this call getWeaponLoadArray;
	_output call summateArray;
};
summateArray = {
	private "_output";
	_output = 0;
	{
		_output = _output + _x;
	} forEach _this;
	_output;
};
//popFront = {
//	_this deleteAt 0;
//};
lootBody = {
	params ["_unit", "_body"];
	private ["_currentWeapons", "_heldWeapons", "_holder"];
	_currentWeapons = _body getVariable ["DE_HELD_WEAPONS", []];
	_heldWeapons = weaponsItems _body;
	_heldWeapons apply { _unit removeWeaponGlobal (_x # 0); };
	_holder = nearestObject [getPosATL _body, "WeaponHolderSimulated"];
	if (!(isNull _holder)) then {
		[_holder, _heldWeapons] call addWeaponsToArray;
	};
	_currentWeapons append _heldWeapons;
	_unit setVariable ["DE_HELD_WEAPONS", _currentWeapons];
};
canLootBody = {
	params ["_unit", "_body"];
	private "_output";
	_output = false;
	if (!alive _body) then {
		if (_unit getVariable ["DE_HELD_WEAPONS", []] isEqualTo []) then {
			_output = true;
		} else {
			systemChat "Unit aleady has loot from another body";
		};
	} else {
		systemChat "Alive man will not let you loot him";
	};
	_output;
};
unitHasLoot = {
	private "_output";
	_output = true;
	if (_this getVariable ["DE_HELD_WEAPONS", []] isEqualTo []) then {
		_output = false;
	} else {
		systemChat "unitHasLoot: Unit already has loot";
	};
	_output;
};
unitHasNoLoot = { !(_this call unitHasLoot); };
isTargetLiving = {
	private "_output";
	_output = true;
	if (alive _this) then {
		systemChat "isTargetLiving: Alive target will not let you loot them";
	} else {
		_output = false;
	};
	_output;
};
isTargetDead = { !(_this call isTargetLiving); };
unitLootBody = {
	params ["_unit", "_body"];
	private ["_relativeDir", "_pos", "_leader"];
	_relativeDir = _body getDir _unit;
	_pos = _body getPos [1, _relativeDir];
	_unit doMove _pos;
	waitUntil {moveToCompleted _unit};
	_unit setFormDir (_unit getDir _body);
	doStop _unit; //stop here prevents unit from making radio messages after doMove
	_unit playMove "AinvPknlMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon_medic";
	sleep 1;
	[_unit, _body] call lootBody;
	_leader = leader _unit;
	_unit setFormDir (_unit getDir _leader);
	_unit doFollow _leader;
};
unitDropOffLoot = {
	params ["_unit", "_vehicle"];
	private "_result";
	_unit doMove (getPosATL _vehicle);
	waitUntil {moveToCompleted _unit};
	doStop _unit; //stop here prevents unit from making radio messages after doMove
	_unit playMove "AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon";
	sleep 1;
	_result = [_unit getVariable ["DE_HELD_WEAPONS", []], _vehicle] call addWeaponsToCargo;
	if (count _result > 0) then {
		_unit groupRadio "SentSupportNotAvailable";
	};
	_unit setVariable ["DE_HELD_WEAPONS", _result];
};

player addAction ["Loot all bodies", {
	_unit = units player # 1;
	_vehicle = vehicle player;
	//unit does not act realistically in some situations, depending on how the bodies are arranged relative to the start position
	//simply runs to the closest body in-order from the time the action is used. Results in it sometimes running back and forth to loot rather than going from body-to-body
	//still fun as hell to watch though
	//recalculate list every iteration?? seems costly - look for alternative
	_list = (entities [["Man"], [], true, false]) apply { [_unit distance _x, _x] };
	_list sort true;
	{
		if (!alive (_x # 1)) then { //out of concern and should be handled in a higher scope
			if (!(weaponsItems _unit isEqualTo []) || {!(_unit getVariable ["DE_HELD_WEAPONS", []] isEqualTo [])}) then { //out of concern and should be handled in a higher scope
				if (!(_vehicle getVariable ["DE_FULL_VEHICLE", false])) then {
					[_unit, _x # 1] call unitLootBody;
					[_unit, _vehicle] call unitDropOffLoot;
				};
			};
		};
	} forEach _list;
}, nil, 1, false, true];

getLoad = {
	systemChat format ["Load: %1\nLoadABS: %2", load _this, loadAbs _this];
};
/*
[] spawn {
	_vehicle = vehicle player;
	while {true} do {
		hint format ["Load: %1\nLoadABS: %2", load _vehicle, loadAbs _vehicle];
	};
};
*/

sleep 0.01;