#include "..\script_component.hpp"
/*
 * Author: commy2
 * PFH for carrying an object.
 *
 * Arguments:
 * 0: Arguments <ARRAY>
 * - 0: Unit <OBJECT>
 * - 1: Target <OBJECT>
 * - 2: Start time <NUMBER>
 * 1: PFEH Id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[player, cursorTarget, CBA_missionTime], _idPFH] call ace_dragging_fnc_carryObjectPFH;
 *
 * Public: No
 */

#ifdef DEBUG_ENABLED_DRAGGING
    systemChat format ["%1 carryObjectPFH running", CBA_missionTime];
#endif

params ["_args", "_idPFH"];
_args params ["_unit", "_target", "_startTime"];

if !(_unit getVariable [QGVAR(isCarrying), false]) exitWith {
    TRACE_2("carry false",_unit,_target);

    _unit setVariable [QGVAR(hint), nil];
    call EFUNC(interaction,hideMouseHint);

    _idPFH call CBA_fnc_removePerFrameHandler;
};

// Drop if the crate is destroyed OR target moved away from carrier (weapon disassembled) OR carrier starts limping
if !(alive _target && {_unit distance _target <= 10} && {_unit getHitPointDamage "HitLegs" < 0.5}) exitWith {
    TRACE_2("dead/distance",_unit,_target);

    if ((_unit distance _target > 10) && {(CBA_missionTime - _startTime) < 1}) exitWith {
        // attachTo seems to have some kind of network delay and target can return an odd position during the first few frames,
        // So wait a full second to exit if out of range (this is critical as we would otherwise detach and set it's pos to weird pos)
        TRACE_3("ignoring bad distance at start",_unit distance _target,_startTime,CBA_missionTime);
    };

    [_unit, _target] call FUNC(dropObject_carry);

    _unit setVariable [QGVAR(hint), nil];
    call EFUNC(interaction,hideMouseHint);

    _idPFH call CBA_fnc_removePerFrameHandler;
};

private _previousHint = _unit getVariable [QGVAR(hint), []];

// If paused, don't show mouse button hints
if (_previousHint isEqualType "") exitWith {};

// Mouse hint
private _hintLMB = LLSTRING(Drop);
getCursorObjectParams params ["_cursorObject", "", "_distance"];

if (
    !isNull _cursorObject &&
    {_distance < MAX_LOAD_DISTANCE} &&
    {[_unit, _cursorObject, ["isNotCarrying"]] call EFUNC(common,canInteractWith)} &&
    {
        if (_target isKindOf "CAManBase") then {
            [_cursorObject, 0, true] call EFUNC(common,nearestVehiclesFreeSeat) isNotEqualTo []
        } else {
            ["ace_cargo"] call EFUNC(common,isModLoaded) &&
            {[_target, _cursorObject] call EFUNC(cargo,canLoadItemIn)}
        }
    }
) then {
    _hintLMB = LELSTRING(common,loadObject);
};

private _hintMMB = LLSTRING(RaiseLowerRotate);

if (_target isKindOf "CAManBase") then {
    _hintMMB = "";
};

private _hint = [_hintLMB, "", _hintMMB];

if (_hint isNotEqualTo _previousHint) then {
    _unit setVariable [QGVAR(hint), _hint];
    _hint call EFUNC(interaction,showMouseHint);
};
