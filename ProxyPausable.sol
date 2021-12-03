//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

/**
 * $$$$$$$\                                                $$\     $$$$$$$$\ $$\                                                   
 * $$  __$$\                                               $$ |    $$  _____|\__|                                                  
 * $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$ |    $$ |      $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\  
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$ |    $$$$$\    $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\ 
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ /  $$ |$$$$$$$$ |$$ /  $$ |    $$  __|   $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |    $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ \$$$$$$$ |$$\ $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
 * \_______/  \______/  \____$$ | \____$$ | \_______| \_______|\__|\__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|
 *                     $$\   $$ |$$\   $$ |                                                                                        
 *                     \$$$$$$  |\$$$$$$  |                                                                                        
 *                      \______/  \______/
 * 
 * https://bogged.finance/
 */

import "./LibCoreStorage.sol";
import "./ProxyOwnable.sol";

abstract contract ProxyPausable is ProxyOwnable {
    modifier notPaused {
        require(!paused(), "BOGProxy: PAUSED");
        _;
    }
    
    modifier whenPaused {
        require(paused(), "BOGProxy: !PAUSED");
        _;
    }
    
    function paused() public view returns (bool) {
        return LibCoreStorage.coreStorage().paused;
    }
    
    function pause() external notPaused onlyOwner {
        LibCoreStorage.coreStorage().paused = true;
        emit Paused();
    }
    
    function unpause() external whenPaused onlyOwner {
        LibCoreStorage.coreStorage().paused = false;
        emit Unpaused();
    }
    
    event Paused();
    event Unpaused();
}
