// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// interface of ERC20 token
interface IERC20 {
    function transfer(address to, uint256 amount) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    address payable owner;
    IERC20 public token;

    uint256 public withdrawAmount = 50 * (10**18);
    uint256 public lockTime = 1 minutes;

    event Withdraw(address indexed to, uint256 indexed amount);
    event Deposit(address indexed from, uint256 indexed amount);

    mapping(address => uint256) nextAccessTime;

    constructor(address tokenAddress) payable {
        token = IERC20(tokenAddress);
        owner = payable(msg.sender);
    }

    // main function to request tokens from the Faucet
    function requestTokens() public {
        require(
            msg.sender != address(0),
            "Request must not originate from a zero account"
        );
        require(
            token.balanceOf(address(this)) >= withdrawAmount,
            "Insufficient balance in faucet for withdrawal request"
        );
        require(
            block.timestamp >= nextAccessTime[msg.sender],
            "Insufficient time elapsed since last withdrawal - try again later."
        );

        nextAccessTime[msg.sender] = block.timestamp + lockTime;

        token.transfer(msg.sender, withdrawAmount);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function setWithdrawAmount(uint256 amount) public onlyOwner {
        withdrawAmount = amount * (10**18);
    }

    function setLockTime(uint256 amount) public onlyOwner {
        lockTime = amount * 1 minutes; // the interval that is needed before requesting new tokens
    }

    function withdraw() external onlyOwner {
        emit Withdraw(msg.sender, token.balanceOf(address(this)));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
        
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

}