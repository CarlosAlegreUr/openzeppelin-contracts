// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";
import {SafeCast} from "./math/SafeCast.sol";
import {IERC6372} from "../interfaces/IERC6372.sol";

uint8 constant PAUSED = 1;
uint8 constant UNPAUSED = 0;

uint8 constant PAUSE_DEADLINE_OFFSET = 8;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * Stops can be of undefined duration or for a certain amount of time.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be `Pausable` by
 * simply including this module, only once the modifiers are put in place
 * and calls to the internal `_pause()`, `_unpause()`, `_pauseFor()` functions
 * are coded.
 */
abstract contract Pausable is IERC6372, Context {
    /**
     * @dev Storage slot is structured like so:
     *
     * - Least significant 8 bits: signal pause state.
     *   1 for paused, 0 for unpaused.
     *
     * - After, the following 48 bits: signal timestamp at which the contract
     *   will be automatically unpaused if the pause had a duration set.
     */
    uint256 private _pausedInfo;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Emitted when the a pause with a certain `duration` is triggered by `account`.
     */
    event PausedFor(address account, uint32 duration, uint48 endTime);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _pausedInfo = UNPAUSED;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Clock is used here for time checkings on pauses with defined end-date.
     *
     * @dev IERC6372 implementation of a clock() based on native `block.timestamp`.
     *
     * Override this function to implement a different clock, if so must be done following {IERC6372} specification.
     * `Pausable` has been designed to work properly when return value of `clock()` is in seconds.
     */
    function clock() public view virtual override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /**
     * @dev IERC6372 implementation of a CLOCK_MODE() based on timestamp.
     *
     * Override this function to implement a different clock mode, if so must be done following {IERC6372} specification.
     */
    function CLOCK_MODE() public view virtual override returns (string memory) {
        return "mode=timestamp";
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     *
     * A contract is paused (returns true) if:
     *
     * - It was paused by `_pause()`
     * - Or if it was paused by `_pauseFor(uint256 time)` and `time` seconds have not passed.
     */
    function paused() public view virtual returns (bool) {
        uint48 unpauseDeadline = _unpauseDeadline();
        return uint8(_pausedInfo) == PAUSED || (unpauseDeadline != 0 && clock() < unpauseDeadline);
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Returns the timestamp at which the contract can be unpaused by {_unpauseAfterPausedFor}.
     *
     * If returned 0, the contract might or might not be paused.
     *
     * This function must not be used for checking paused state.
     */
    function _unpauseDeadline() internal view virtual returns (uint48) {
        return uint48(_pausedInfo >> PAUSE_DEADLINE_OFFSET);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _pausedInfo = PAUSED;
        emit Paused(_msgSender());
    }

    /**
     * @dev Triggers stopped state for at most `time` seconds.
     *
     * This function should be used to prevent eternally pausing contracts in complex permissioned systems.
     * 
     * @dev 32 bits for duraions and 48 for deadlines have been set as per ERC6372 recommendations.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - `time` must be greater than 0.
     * - `clock()` return value and `time` must be in the same time units. (seonds on default Pausable implementation)
     */
    function _pauseFor(uint32 time) internal virtual whenNotPaused {
        if (time != 0) {
            uint48 deadline = SafeCast.toUint48(clock() + time);
            _pausedInfo = uint256(deadline) << PAUSE_DEADLINE_OFFSET | PAUSED;
            emit PausedFor(_msgSender(), time, deadline);
        }
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _pausedInfo = UNPAUSED;
        emit Unpaused(_msgSender());
    }
}
