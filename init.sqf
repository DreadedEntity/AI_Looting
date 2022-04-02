sleep 0.001;

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
	private ["_snapshot", "_countBefore", "_countAfter"];
	_snapshot = weaponsItemsCargo _vehicle;
	_countBefore = { _weapon isEqualTo _x } count _snapshot;
	_vehicle addWeaponWithAttachmentsCargoGlobal [_weapon, 1];
	_countAfter = { _weapon isEqualTo _x } count weaponsItemsCargo _vehicle;
	_countBefore != _countAfter;
};
popFront = {
	_this deleteAt 0;
};
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
	private ["_relativeDir", "_pos"];
	_relativeDir = _body getDir _unit;
	_pos = _body getPos [1, _relativeDir];
	_unit doMove _pos;
	waitUntil {moveToCompleted _unit};
	_unit setFormDir (_unit getDir _body);
	doStop _unit;
	_unit playMove "AinvPknlMstpSnonWnonDnon_AinvPknlMstpSnonWnonDnon_medic";
	sleep 1;
	[_unit, _body] call lootBody;
	_unit setFormDir (_unit getDir player);
	_unit doFollow player;
};
unitDropOffLoot = {
	params ["_unit", "_vehicle"];
	private "_result";
	_unit doMove (getPosATL _vehicle);
	waitUntil {moveToCompleted _unit};
	_unit playMove "AinvPercMstpSnonWnonDnon_Putdown_AmovPercMstpSnonWnonDnon";
	sleep 1;
	_result = [_unit getVariable ["DE_HELD_WEAPONS", []], _vehicle] call addWeaponsToCargo;
	_unit setVariable ["DE_HELD_WEAPONS", _result]; //currently uncessesary because the "add_" command ignores cargo amount and will always be able to add all weapons. eg _result is always [] afterward
	//possible workaround, use infinite "add_" command to add item to unit's backpack, then make unit "drop" action the item into the vehicle
};

player addAction ["Loot nearby dead soldiers (instant)", {
	DEBUG = 6;
	[] spawn {
	{
		if (_x distance player < 30) then {
			if (!alive _x) then {
				if (_x != player) then {
					_unit = _x;
					_currentWeapons = _unit getVariable ["DE_HELD_WEAPONS", []];
					//Get units weapons
					_heldWeapons = weaponsItems _unit;
					hint str _heldWeapons;
					//waitUntil {DEBUG == 1};
					
					//_heldWeapons call removeRangefinderArray;
					//hint str _heldWeapons;
					//waitUntil {DEBUG == 2};
					
					
					//delete weapons from unit
					_heldWeapons apply { _unit removeWeaponGlobal (_x # 0); };
					//waitUntil {DEBUG == 3};
					
					//Find closest weapon holder
					_holder = nearestObject [getPosATL _x, "WeaponHolderSimulated"];
					//if (isNull _holder) then { //doesn't work for whatever reason - maybe not necessary anyway
					//	//if no simulated (dead unit dropped), look for player dropped weapons
					//	_holder = nearestObject [getPosATL _x, "WeaponHolderSimulated"];
					//};
					
					if (!(isNull _holder)) then {
						[_holder, _heldWeapons] call addWeaponsToArray;
						hint str _heldWeapons;
						//waitUntil {DEBUG == 4};
					};
					//systemChat str _heldWeapons;
					
					//save weapons to unit object
					_currentWeapons append _heldWeapons;
					hint str _currentWeapons;
					//waitUntil {DEBUG == 5};
					_unit setVariable ["DE_HELD_WEAPONS", _currentWeapons];

					//add weapons from unit object to vehicle cargo
					_bringThemBack = _unit getVariable ["DE_HELD_WEAPONS", []];
					hint str _bringThemBack;
					waitUntil {DEBUG == 6};
					
					_result = [_bringThemBack, vehicle player] call addWeaponsToCargo;
					hint str _result;
					//waitUntil {DEBUG == 7};

					_unit setVariable ["DE_HELD_WEAPONS", _result];
				};
			};
		};
	} forEach (entities [["Man"], [], true, false]);
	systemChat "Script end";
	};
}, nil, 0, false, true, ""]; //"vehicle player != player"];

player addAction ["Loot all bodies", {
	_unit = units player # 1;
	//unit does not act realistically in some situations, depending on how the bodies are arranged relative to the start position
	//simply runs to the closest body in-order from the time the action is used. Results in it sometimes running back and forth to loot rather than going from body-to-body
	//still fun as hell to watch though
	//recalculate list every iteration?? seems costly - look for alternative
	_list = (entities [["Man"], [], true, false]) apply { [_unit distance _x, _x] };
	_list sort true;
	{
		if (!alive (_x # 1)) then {
			[_unit, _x # 1] call unitLootBody;
			[_unit, vehicle player] call unitDropOffLoot;
		};
	} forEach _list;
}, nil, 1, false, true];


[["hgun_Rook40_F","","","",["16Rnd_9x21_Mag",16],[],""],
["arifle_Katiba_ACO_pointer_F","","acc_pointer_IR","optic_ACO_grn",["30Rnd_65x39_caseless_green",30],[],""],
["arifle_Katiba_ACO_pointer_F","","acc_pointer_IR","optic_ACO_grn",["30Rnd_65x39_caseless_green",30],[],""],
["hgun_Rook40_F","","","",["16Rnd_9x21_Mag",16],[],""],
["arifle_Katiba_ACO_pointer_F","","acc_pointer_IR","optic_ACO_grn",["30Rnd_65x39_caseless_green",30],[],""],
["hgun_Rook40_F","","","",["16Rnd_9x21_Mag",16],[],""]]
