pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title Pool
 * @notice This contract implements a automated market making pool that contains two tokens:
 *   x = ETH
 *   y = ERC-20 token
 * The pool follows the constant-product invariant: x*y = k that must hold under swaps.
 */
contract Pool is ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Swap(address indexed sender, uint256 xIn, uint256 yIn, uint256 xOut, uint256 yOut);

    // The ERC-20 token
    // @audit-issue State variables that are not updated following deployment should be declared immutable to save gas.
    IERC20 public token; 

    // @audit-issue missing TODO description
    /**
     * TODO
     * @param _token The ERC20 token
     */
    constructor(IERC20 _token) {
        token = _token;
    }

    //@audit-issue comments are inconsistents. X is ether and Y is the token.
    /**
     * This function gets the current reserves of the tokens held by the contract.
     * @return x is the amount of the ERC-20 token and y is the amount of ETH.
     */
    function getReserves() public view returns (uint256 x, uint256 y) {
        //@audit-ok
        x = address(this).balance;
        y = token.balanceOf(address(this));
    }

    // @audit-issue missing return description
    /**
     * Get the price of ETH in the token.
     */
    function getETHPriceInToken() external view returns (uint256 price) {
        (uint256 x, uint256 y) = getReserves();
        //@audit-ok conta está correta
        price = y / x;
    }

    /**
     * Swap ETH for token
     */
    function swapEthForToken() external payable nonReentrant {
        (uint256 x, uint256 y) = getReserves();
        require(x > 0 && y > 0, "Insufficient pool liquidity");

        // Amount of the ERC-20 token to transfer to msg.sender
        // @audit-issue There is a problem in this formula that causes the user to lose money. X must be address(this).balance - msg.value.
        uint256 beta = msg.value * y / (x + msg.value);
        require(y > beta, "You can't drain the pool of the ERC-20 token");
        require(beta != 0, "Insufficient swap amount");

        token.safeTransfer(msg.sender, beta);

        //@audit-issue wrong usage of Swap event.
        // Swap(sender, xIn, yIn, xOut, yOut);
        // Swap(msg.sender, msg.value, 0, 0, beta);
        emit Swap(msg.sender, 0, msg.value, beta, 0);
    }

    /**
     * Swap token for ETH
     * @param _amount The amount of the ERC-20 token to swap.
     */
    function swapTokenForEth(uint256 _amount) external nonReentrant {
        (uint256 x, uint256 y) = getReserves();
        require(x > 0 && y > 0, "Insufficient pool liquidity");

        // Amount of the ETH to send to msg.sender
        // @audit-ok formula OK. Alpha are the amount of ETH that will be transfered.
        uint256 alpha = _amount * x / (y + _amount);
        require(x > alpha, "You can't drain the pool of ETH");
        require(alpha != 0, "Insufficient swap amount");

        (bool sent,) = msg.sender.call{value: alpha}("");
        require(sent, "Failed to send Ether");

        // Transfer the ERC-20 token from msg.sender
        // @audit-issue state is modified after the external call. read-only reentrancy
        token.safeTransferFrom(msg.sender, address(this), _amount);

        //@audit-issue wrong usage of Swap event.
        // Swap(sender, xIn, yIn, xOut, yOut);
        // Swap(msg.sender, 0, _amount, alpha, 0);
        emit Swap(msg.sender, _amount, 0, 0, alpha);
    }

    /*
     * Additional functions that implement functionality for adding and withdrawing liquidity.
     * Assume all additional functions are properly implemented and bug-free.
     */
}