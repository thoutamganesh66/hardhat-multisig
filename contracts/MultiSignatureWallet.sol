//SPDX-License-Identifier:MIT
pragma solidity ^0.5.0;
 
contract MultiSignatureWallet {
 
  //enum test{Accepted,Rejected,Pending} 
    struct Transaction {
      bool executed;
      bool accepted;
      address destination;
      uint value;
      bytes data;
      mapping(address => bool) testing;
    }
 
    event Deposit(address indexed sender, uint value);
    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
 
    /// @dev Fallback function allows to deposit ether.
    function()
    	external
        payable
        
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
	    }
    }
 
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.  
 
    address[] public owners;
    uint public required;
    mapping (address => bool) public isOwner;
 
    uint public transactionCount;
    mapping (uint => Transaction) public transactions;
 
    mapping (uint => mapping (address => bool)) public confirmations;
 
    mapping (uint => mapping (address => bool)) public acceptance;
    //temp
 
 
 
    constructor(address[] memory _owners, uint _required) public payable
        validRequirement(_owners.length,_required) {
        for (uint i=0; i<_owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }
 
    modifier validRequirement(uint ownerCount, uint _required) {
        if (_required > ownerCount || _required == 0 || ownerCount == 0)
            revert();
        _;
    }  
 
    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    //function submitTransaction(address destination, uint value, bytes memory data) public returns (uint transactionId) {}
 
    function submitTransaction(address destination, uint value, bytes memory data) 
        public payable
        returns (uint transactionId) 
    {
        require(isOwner[msg.sender]);
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }
 
    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
    {
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination != address(0));
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] = true;
        // Transaction.testing[msg.sender] = true;
        acceptance[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }
 
function confirmTransactionReject(uint transactionId)
        public
    {
        require(isOwner[msg.sender]);
        require(transactions[transactionId].destination != address(0));
        require(confirmations[transactionId][msg.sender] == false);
        confirmations[transactionId][msg.sender] = true;
        // Transaction.testing[msg.sender] = true;
        acceptance[transactionId][msg.sender] = false;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }
 
    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {}
 
    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
    {
        require(transactions[transactionId].executed == false);
        if (isConfirmed(transactionId)) {
            uint flag=0;
            for(uint i=0;i<required;i++)
            {
                if(acceptance[transactionId][owners[i]] == false)
                    flag=1;
            }           
 
            Transaction storage t = transactions[transactionId];
            if(flag==0)
                t.accepted = true;
            t.executed = true;
 
            (bool success, bytes memory rdata) = t.destination.call.value(t.value)(t.data);
            if (success)
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
            }
        }
    }
		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        view
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }
 
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            accepted:false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
}