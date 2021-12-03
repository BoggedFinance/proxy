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
import "./ProxyPausable.sol";
import "./ProxyReentrancyGuard.sol";

contract BoggedFinanceProxy is ProxyOwnable, ProxyPausable, ProxyReentrancyGuard {
    constructor(address initializer) {
        (bool success, ) = initializer.delegatecall(abi.encode(bytes4(keccak256("initialize()"))));
        require(success, "BOGProxy: INITIALIZATION_FAILED");
    }
    
    receive() external payable { }
    
    fallback() external payable notPaused {
        address impl = getImplementation(msg.sig);
        require(impl != address(0), "BOGProxy: INVALID_SELECTOR");
        (bool success, bytes memory data) = impl.delegatecall(msg.data);
        require(success, _getRevertMsg(data));
        assembly { return(add(data, 32), mload(data)) }
    }
    
    function getImplementation(bytes4 selector) public view returns (address) {
        return LibCoreStorage.coreStorage().implementations[selector];
    }
    
    function setImplementation(bytes4 selector, address implementation, bool initialize) external onlyOwner {
        require(implementation == address(0) || _isContract(implementation), "BOGProxy: INVALID_IMPLEMENTAION");
        LibCoreStorage.coreStorage().implementations[selector] = implementation;
        if(initialize){
            (bool success, ) = implementation.delegatecall(abi.encode(bytes4(keccak256("initialize()"))));
            require(success, "BOGProxy: INITIALIZATION_FAILED");
        }
        emit ImplementationUpdated(selector, implementation);
    }
    
    function _getRevertMsg(bytes memory data) internal pure returns (string memory reason) {
        uint l = data.length;
        if (l < 68) return "";
        uint t;
        assembly {
            data := add(data, 4)
            t := mload(data)
            mstore(data, sub (l, 4))
        }
        reason = abi.decode(data, (string));
        assembly {
            mstore(data, t)
        }
    }
    
    function _isContract(address adr) internal view returns (bool){
        uint32 size;
        assembly { size := extcodesize(adr) }
        return (size > 0);
    }

    event ImplementationUpdated(bytes4 selector, address delegate);
}
