// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedMicroInsurance {

    struct Pool {
        uint256 id;
        address creator;
        string description;
        uint256 premium;
        uint256 payout;
        uint256 totalContributions;
        uint256 totalClaims;
        bool isActive;
        address[] participants;
    }

    mapping(uint256 => Pool) public pools;
    uint256 public poolCounter;
    
    event PoolCreated(uint256 poolId, address creator, string description);
    event ParticipantJoined(uint256 poolId, address participant);
    event ClaimMade(uint256 poolId, address claimant, uint256 amount);
    event PayoutProcessed(uint256 poolId, address recipient, uint256 amount);

    modifier onlyPoolCreator(uint256 _poolId) {
        require(msg.sender == pools[_poolId].creator, "Only the pool creator can perform this action");
        _;
    }

    modifier poolExists(uint256 _poolId) {
        require(pools[_poolId].id != 0, "Pool does not exist");
        _;
    }

    modifier poolIsActive(uint256 _poolId) {
        require(pools[_poolId].isActive, "Pool is not active");
        _;
    }

    // Create a new pool
    function createPool(string memory _description, uint256 _premium, uint256 _payout) external {
        poolCounter++;
        Pool storage newPool = pools[poolCounter];
        newPool.id = poolCounter;
        newPool.creator = msg.sender;
        newPool.description = _description;
        newPool.premium = _premium;
        newPool.payout = _payout;
        newPool.isActive = true;
        
        emit PoolCreated(poolCounter, msg.sender, _description);
    }

    // Join a pool by contributing premium
    function joinPool(uint256 _poolId) external payable poolExists(_poolId) poolIsActive(_poolId) {
        require(msg.value == pools[_poolId].premium, "Incorrect premium amount");

        Pool storage pool = pools[_poolId];
        pool.totalContributions += msg.value;
        pool.participants.push(msg.sender);
        
        emit ParticipantJoined(_poolId, msg.sender);
    }

    // Make a claim on the pool
    function makeClaim(uint256 _poolId, uint256 _amount) external poolExists(_poolId) poolIsActive(_poolId) {
        Pool storage pool = pools[_poolId];
        require(_amount <= pool.totalContributions, "Claim exceeds total contributions");
        
        pool.totalClaims += _amount;
        payable(msg.sender).transfer(_amount);
        
        emit ClaimMade(_poolId, msg.sender, _amount);
    }

    // Process a payout (only pool creator can trigger this)
    function processPayout(uint256 _poolId, address payable _recipient, uint256 _amount) external onlyPoolCreator(_poolId) poolExists(_poolId) poolIsActive(_poolId) {
        Pool storage pool = pools[_poolId];
        require(_amount <= pool.totalClaims, "Amount exceeds available claim funds");
        
        pool.totalClaims -= _amount;
        _recipient.transfer(_amount);
        
        emit PayoutProcessed(_poolId, _recipient, _amount);
    }

    // Close the pool
    function closePool(uint256 _poolId) external onlyPoolCreator(_poolId) poolExists(_poolId) {
        Pool storage pool = pools[_poolId];
        pool.isActive = false;
    }

    // View pool details
    function getPoolDetails(uint256 _poolId) external view returns (Pool memory) {
        return pools[_poolId];
    }
}
