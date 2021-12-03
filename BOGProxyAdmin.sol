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

import "./BoggedFinanceProxy.sol";

contract BOGProxyAdmin {
    address public owner;
    BoggedFinanceProxy proxy;
    
    uint256 public delay = 12 hours;
    mapping (bytes32 => uint256) public timestamp;
    
    constructor (BoggedFinanceProxy _proxy) {
        owner = msg.sender;
        proxy = _proxy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BOGProxyAdmin: ONLY_OWNER"); _;
    }
    
    function schedule(address target, bytes memory data, uint256 nonce) external onlyOwner {
        bytes32 hash = getOperationHash(target, data, nonce);
        require(timestamp[hash] == 0, "BOGProxyAdmin: DUPLICATE_OPERATION");
        timestamp[hash] = block.timestamp;
        emit ScheduledCall(target, data, nonce);
    }
    
    function execute(address target, bytes memory data, uint256 nonce) external onlyOwner {
        bytes32 hash = getOperationHash(target, data, nonce);
        require(!isPending(hash), "BOGProxyAdmin: NOT_PENDING");
        require(isReady(hash), "BOGProxyAdmin: NOT_READY");
        (bool success, ) = target.call(data);
        require(success, "BOGProxyAdmin: CALL_FAILED");
        timestamp[hash] = 0;
        emit ExecutedCall(target, data, nonce);
    }
    
    function cancel(address target, bytes memory data, uint256 nonce) external onlyOwner {
        bytes32 hash = getOperationHash(target, data, nonce);
        require(isPending(hash), "BOGProxyAdmin: !EXISTING_OPERATION");
        timestamp[hash] = 0;
        emit CancelledCall(target, data, nonce);
    }
    
    function getOperationHash(address target, bytes memory data, uint256 nonce) public pure returns (bytes32) {
        return bytes32(keccak256(abi.encode(target, data, nonce)));
    }
    
    function isPending(bytes32 hash) public view returns (bool) {
        return timestamp[hash] > 0;
    }
    
    function isReady(bytes32 hash) public view returns (bool) {
        return isPending(hash) && timestamp[hash] + delay <= block.timestamp;
    }
    
    function pauseProxy() external onlyOwner {
        proxy.pause();
    }
    
    function unpauseProxy() external onlyOwner {
        proxy.unpause();
    }
    
    function setDelay(uint256 _delay) external {
        require(msg.sender == address(this), "BOGProxyAdmin: TIMELOCKED_FUNCTION");
        delay = _delay;
        emit DelayUpdated(delay);
    }
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == address(this), "BOGProxyAdmin: TIMELOCKED_FUNCTION");
        owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    event ScheduledCall(address target, bytes data, uint256 nonce);
    event ExecutedCall(address target, bytes data, uint256 nonce);
    event CancelledCall(address target, bytes data, uint256 nonce);
    event DelayUpdated(uint256 delay);
    event OwnershipTransferred(address newOwner);
}
