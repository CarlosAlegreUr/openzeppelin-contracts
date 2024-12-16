// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";
import {SafeCast} from "./math/SafeCast.sol";

uint8 constant PAUSED = 1;
uint8 constant PAUSE_DURATION_OFFSET = 8;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * Stops can be of undefined duration or for a certain amount of time.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Storage slot is structured like so:
     *
     * - Least significant 8 bits: signal pause state.
     *   1 for paused, 0 for unpaused.
     *
     * - Most significant 248 bits: signal timestamp at which
     *   {_unpauseAfterPausedFor} can be called.
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
    event PausedFor(address account, uint256 duration);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev The operation failed because trying to unpause before `time` set on {_pauseFor} elapsed.
     */
    error PauseDurationNotElapsed();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        delete _pausedInfo;
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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return uint8(_pausedInfo) == PAUSED;
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
    function _unpauseDeadline() internal view virtual returns (uint256) {
        return _pausedInfo >> PAUSE_DURATION_OFFSET;
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
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        delete _pausedInfo;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Triggers stopped state.
     *
     * Ideally, someone with no permissions should be able to call {_unpauseAfterPausedFor}
     * after `time` seconds elapsed.
     * 
     * This function should be used to prevent eternally pausing contracts in complex permissioned systems.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - `time` must be greater than 0.
     */
    function _pauseFor(uint256 time) internal virtual whenNotPaused {
        if (time != 0) {
            _pausedInfo = SafeCast.toUint248(block.timestamp + time) << PAUSE_DURATION_OFFSET | PAUSED;
            emit PausedFor(_msgSender(), time);
        }
    }

    /**
     * @dev Returns to normal state after a pause duration tirggered by {_pauseFor}.
     * If the contract was paused without a duration using {_pause}, this function just unpauses.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - `time` amount when {_pauseFor} was called must have passed on-chain.
     */
    function _unpauseAfterPausedFor() internal virtual whenPaused {
        uint256 unpauseDeadline = _unpauseDeadline();
        if (unpauseDeadline != 0 && block.timestamp < unpauseDeadline) {
            revert PauseDurationNotElapsed();
        }
        _unpause();
    }
}
