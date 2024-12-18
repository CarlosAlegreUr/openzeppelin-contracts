// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Pausable} from "../utils/Pausable.sol";

contract PausableMock is Pausable {
    bool public drasticMeasureTaken;
    uint256 public count;

    constructor() {
        drasticMeasureTaken = false;
        count = 0;
    }

    function normalProcess() external whenNotPaused {
        count++;
    }

    function drasticMeasure() external whenPaused {
        drasticMeasureTaken = true;
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }

    function pauseFor(uint256 duration) external {
        _pauseFor(uint32(duration));
    }

    function getPausedForDeadline() external view returns (uint256) {
        return _unpauseDeadline();
    }

    function getPausedForDeadlineAndTimestamp() external view returns (uint256, uint256) {
        return (_unpauseDeadline(), clock());
    }
}
