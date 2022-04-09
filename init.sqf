/////////////////////////////////////
// Function file for Armed Assault //
//    Created by: DreadedEntity    //
/////////////////////////////////////

diag_log text "------------------------------ MISSION CODE BEGINS ------------------------------";

sleep 0.01;

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
lootBody = {
	params ["_unit", "_body"];
	private ["_currentWeapons", "_heldWeapons", "_holder"];
	_currentWeapons = _body getVariable ["DE_HELD_WEAPONS", []];
	_heldWeapons = weaponsItems _body;
	_heldWeapons apply { _body removeWeaponGlobal (_x # 0); };
	_holder = _unit getVariable "DE_WEAPONHOLDER";
	if (isNil "_holder") then {
		_holder = nearestObject [getPosATL _body, "WeaponHolderSimulated"];
	};
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
		//systemChat "unitHasLoot: Unit already has loot";
	};
	_output;
};
unitHasNoLoot = { !(_this call unitHasLoot); };
isTargetLiving = {
	private "_output";
	_output = true;
	if (alive _this) then {
		//systemChat "isTargetLiving: Alive target will not let you loot them";
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
	//_unit setPosATL _pos;
	waitUntil {moveToCompleted _unit};
	_unit setFormDir (_unit getDir _body);
	doStop _unit; //stop here prevents unit from making radio messages after doMove
	_unit playMove "AinvPknlMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon_medic";
	sleep 1;
	[_unit, _body] call lootBody;
	_body setVariable ["DE_IS_LOOTED", true];
	_leader = leader _unit;
	_unit setFormDir (_unit getDir _leader);
	_unit doFollow _leader;
};
unitDropOffLoot = {
	params ["_unit", "_vehicle"];
	private ["_result", "_output", "_leader", "_full"];
	_leader = leader _unit;
	if (isNil "_vehicle")  exitWith {false};
	if (_leader getVariable ["DE_FULL_VEHICLE", false]) exitWith {false};
	_unit doMove (getPosATL _vehicle);
	//_unit setPosATL (getPosATL _vehicle);
	waitUntil {moveToCompleted _unit || (_leader getVariable ["DE_FULL_VEHICLE", false])};
	doStop _unit; //stop here prevents unit from making radio messages after doMove
	if (_leader getVariable ["DE_FULL_VEHICLE", false]) exitWith {false};
	_unit playMove "AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon";
	sleep 1;
	if (_leader getVariable ["DE_FULL_VEHICLE", false]) exitWith {false};
	_result = [_unit getVariable ["DE_HELD_WEAPONS", []], _vehicle] call addWeaponsToCargo;
	_unit setVariable ["DE_HELD_WEAPONS", _result];
	_output = count _result == 0;
	if (!_output) then {
		_unit groupRadio "SentSupportNotAvailable";
		_leader setVariable ["DE_FULL_VEHICLE", true];
	};
	_output;
};
unitLoot = {
	//attempts to loot a unit
	params ["_unit", "_body"];
	private "_successful";
	_successful = true;
	_unit setVariable ["DE_IS_LOOTING", true];
	diag_log formatText ["Set DE_IS_LOOTING true on unit: %1", _unit];
	if (_unit call unitHasLoot) then {
		diag_log formatText ["%1 attempting to drop off previously held loot", _unit];
		_sucessful = [_unit, (leader _unit) getVariable "DE_VEHICLE"] call unitDropOffLoot;
		diag_log formatText ["%1 tried to drop off prevously held loot, result: %2", _unit, _successful];
	} else {
		if (_successful) then {
			diag_log formatText ["Enter unitLootBody with unit: %1", _unit];
			[_unit, _body] call unitLootBody;
			diag_log formatText ["Exit unitLootBody with unit: %1", _unit];
			diag_log formatText ["Enter unitDropOffLoot with unit: %1", _unit];
			[_unit, (leader _unit) getVariable "DE_VEHICLE"] call unitDropOffLoot;
			diag_log formatText ["Enter unitDropOffLoot with unit: %1", _unit];
		};
	};
	_unit setVariable ["DE_IS_LOOTING", false];
	diag_log formatText ["Set DE_IS_LOOTING false on unit: %1", _unit];
};
orderLooting = {
	params ["_units", "_bodies"];
	private ["_leader", "_bodyAssigned", "_next"];
	_leader = _units deleteAt 0;
	[_leader, 500] call checkLeaderVehicle;
	_bodyCount = (count _bodies) - 1;
	for "_i" from 0 to _bodyCount do {
		_next = _bodies deleteAt 0;
		diag_log formatText ["Next body to assign: %1", _next];
		_bodyAssigned = false;
		if (!(_leader getVariable ["DE_FULL_VEHICLE", false])) then {
			while {!_bodyAssigned} do {
				{
					if (!_bodyAssigned) then {
						if (!(_x getVariable ["DE_IS_LOOTING", false])) then {
							diag_log formatText ["Assigned %1 to be looted by %2", _next, _x];
							_bodyAssigned = true;
							diag_log formatText ["Enter unitLoot with unit: %1", _x];
							[_x, _next] spawn unitLoot;
							diag_log formatText ["Exit unitLoot with unit: %1", _x];
							sleep 0.05;
							break;
						};
					};
				} forEach _units;
				if (!_bodyAssigned) then {
					sleep 1;
				};
			};
		} else {
			diag_log formatText ["Could not assign %1 to unit because vehicle was full", _next];
			break;
		};
	};
	diag_log text "There are no more units to loot";
	systemChat "Looting done";
};
removeUnfitObjects = {
	_this call removeAliveObjects;
	_this call removeLootedObjects;
	_this;
};
removeAliveObjects = {
	private ["_index", "_removed"];
	_index = 0;
	for "_i" from 0 to (count _this) do {
		if (alive (_this # _index)) then {
			_removed = _this deleteAt _index;
			diag_log formatText ["Removed living unit: %1", _removed];
		} else {
			_index = _index + 1;
		};
	};
};
removeLootedObjects = {
	private ["_index", "_removed"];
	_index = 0;
	for "_i" from 0 to (count _this) do {
		if ((_this # _index) getVariable ["DE_IS_LOOTED", false]) then {
			_removed = _this deleteAt _index;
			diag_log formatText ["Removed looted unit: %1", _removed];
		} else {
			_index = _index + 1;
		};
	};
};
checkLeaderVehicle = {
	params ["_leader", "_distance"];
	private "_vehicle";
	_vehicle = _leader getVariable "DE_VEHICLE";
	if (!(isNil "_vehicle")) then {
		if (!alive _vehicle || (_leader distance2D _vehicle) > _distance) then {
			_leader setVariable ["DE_VEHICLE", nil];
		};
	};
};
getLoad = {
	systemChat format ["Load: %1\nLoadABS: %2", load _this, loadAbs _this];
};
initialize = {
	[] spawn {
		diag_log text "Looting script initialization started";
		player addAction ["<t color='#FFFF00' shadow='2' underline='1'>Squad loot</t>", {
			diag_log text "Looting action used";
			_toLoot = (entities [["Man"], [], true, false]) call removeUnfitObjects;
			diag_log text "Begin orderLooting";
			[units player, _toLoot] call orderLooting;
			diag_log text "Exit orderLooting";
		}, nil, 1, false, true];
		diag_log text "Loot action added";
		
		player addEventHandler ["GetInMan", {
			params ["_unit", "_role", "_vehicle", "_turret"];
			_unit setVariable ["DE_VEHICLE", _vehicle];	
		}];
		diag_log text "Player event handler added";
		
		diag_log text "Unit PUT event handler loop beginning";
		while {true} do {
			allUnits apply {
				if (!(_x getVariable ["DE_PUT_EH_SET", false])) then {
					_x addEventHandler ["Put", {
						params ["_unit", "_container", "_item"];
						if (typeOf _container == "WeaponHolderSimulated" && {_item isKindof ["Rifle", configFile >> "CfgWeapons"]}) then {
							_unit setVariable ["DE_WEAPONHOLDER", _container];
							systemChat "Event handler ran";
						};
					}];
					_x setVariable ["DE_PUT_EH_SET", true];
				};
			};
			sleep 1;
		};
	};
};

call initialize;
player addRating 99999999;