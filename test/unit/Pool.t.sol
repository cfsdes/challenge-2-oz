// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestPool is Test {
    Pool public pool;
    MockToken public token;

    function setUp() public {
        token = new MockToken();
        pool = new Pool(token);

        resetReserves();
    }

    function test_getReserves() public {
        (uint256 x, uint256 y) = pool.getReserves();
        assertEq(x, 10000);
        assertEq(y, 50000);
    }

    function test_getEthPrice() public {
        uint256 _price = pool.getETHPriceInToken();
        assertEq(_price, 10);
    }

    function test_swapEthForToken() public {
        address alice = makeAddr("alice");
        uint _amount = 1000;
        vm.deal(alice, _amount);
        
        // Calculate expected amount of tokens to receive
        (uint256 x, uint256 y) = pool.getReserves();
        uint256 beta = _amount * y / (x + _amount);

        // SWAP
        vm.prank(alice);
        pool.swapEthForToken{value: _amount}();
        assertEq(token.balanceOf(alice), beta, "Wrong amount received");
    }

    function test_swapTokenForEth() public {
        uint _amount = 1000;

        address alice = makeAddr("alice");
        deal(address(token), alice, _amount);
        vm.startPrank(alice);

        // Calculate expected amount of ETH to receive
        (uint256 x, uint256 y) = pool.getReserves();
        uint256 alpha = _amount * x / (y + _amount);

        // transfer without allowance
        vm.expectRevert("ERC20: insufficient allowance");
        pool.swapTokenForEth(_amount);

        // transfer with allowance
        token.approve(address(pool), _amount);
        pool.swapTokenForEth(_amount);
        assertEq(alice.balance, alpha, "ETH not received");
    }


    /**
     * Performs 4 SWAPS using different amounts for the same pool and compare the results.
     * 
     * SWAP: ETH for Token
     *  1. The first action swaps ETH for token
     *  2. The second action performs the same swap of step 1, but using 100 assets more.
     * 
     * SWAP: Token for ETH
     *  1. The first action swaps Token for ETH
     *  2. The second action performs the same swap of step 1, but using 100 assets more.
     * 
     *  The results of the SWAPS should be different. The second swap must be greater than the first.
     * 
     * @param _amount the amount of token/ETH used for SWAPs
     */
    function test_compareTwoSwaps(uint _amount) external {
        _amount = bound(_amount, 20, 500);
        token.approve(address(pool), 1e18);

        // SWAP ETH for Token
        deal(address(token), address(this), 0);
        pool.swapEthForToken{value: _amount}();
        uint old_token_balance = token.balanceOf(address(this));

        // Reset pool and check using greater values
        resetReserves();
        deal(address(token), address(this), 0);
        pool.swapEthForToken{value: _amount + 100}();
        assertGt(token.balanceOf(address(this)), old_token_balance, "Swap Broken");

        // SWAP Token for ETH
        resetReserves();
        deal(address(token), address(this), _amount);
        vm.deal(address(this), 0);
        pool.swapTokenForEth(_amount);
        uint old_eth_balance = address(this).balance;

        // Reset pool and check using greater values
        resetReserves();
        deal(address(token), address(this), _amount + 100);
        vm.deal(address(this), 0);
        pool.swapTokenForEth(_amount + 100);
        assertGt(address(this).balance, old_eth_balance, "Swap Broken");
    }


    // initialize Pool
    function resetReserves() internal {
        vm.deal(address(pool), 10000); // ETH - 10000
        deal(address(token), address(pool), 50000); // Token - 50000
    }

    receive() external payable {}
}

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 18 ** decimals());
    }
}