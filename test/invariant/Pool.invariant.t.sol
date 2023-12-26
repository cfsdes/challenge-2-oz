// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestPoolInvariant is Test {
    Pool public pool;
    MockToken public token;
    Handler public handler;

    function setUp() public {
        token = new MockToken();
        pool = new Pool(token);
        handler = new Handler(pool, token);
        targetContract(address(handler));       
    }

    /**
     * Reserve cannot be zero
     */
    function invariant_poolAlwaysHasLiquidity() external {
        (uint256 x, uint256 y) = pool.getReserves();
        assertGe(x, 0, "ETH Reserve is negative");
        assertGe(y, 0, "Token Reserve is negative");
    }

    /**
     * User cannot increase his balance with their own SWAPs operations
     */
    function invariant_increaseBalance() external {
        if (address(handler).balance > handler.initialETHBalance() && 
        token.balanceOf(address(handler)) >= handler.initialTokenBalance()) {
            revert("ETH balance increased!");
        }

        if (address(handler).balance >= handler.initialETHBalance() && 
        token.balanceOf(address(handler)) > handler.initialTokenBalance()) {
            revert("Token balance increased!");
        }
    }

    /**
     * The constant of the pool (K) cannot be smaller than the initial constant value.
     */
    function invariant_reverseConsistency() external {
        (uint256 x, uint256 y) = pool.getReserves();
        uint new_k = x * y;
        assert(new_k >= handler.k_value());
    }
}

contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000000 * 18 ** decimals());
    }
}

contract Handler is Test {
    Pool public pool; 
    MockToken public token;

    uint public k_value;
    uint public initialETHBalance;
    uint public initialTokenBalance;

    constructor(Pool _pool, MockToken _token) {
        pool = _pool;
        token = _token;

        // Set contract balance
        vm.deal(address(this), 1000000);
        deal(address(token), address(this), 1000000);

        // Set Pool Reserves
        vm.deal(address(pool), 1000); // ETH - 1000
        deal(address(token), address(pool), 10000); // Token - 10000

        // Update initial vars
        updateInitVars();
    }


    // Transfer tokens to pool interacting directly with the token contract
    function transferTokens(uint _amount) public {
        _amount = bound(_amount, 0, token.balanceOf(address(this)));
        token.transfer(address(pool), _amount);
    }


    // SWAP ETH for Token
    function swapEthForToken(uint _amount) public {
        _amount = bound(_amount, 0, address(this).balance);
        pool.swapEthForToken{value: _amount}();
    }


    /**
     * SWAP Token for ETH
     * Approves the pool before calling swapTokenForEth()
     */
    function swapTokenForEth(uint _amount) public {
        _amount = bound(_amount, 0, token.balanceOf(address(this)));
        token.approve(address(pool), _amount);
        pool.swapTokenForEth(_amount);
    }


    // Update reserve amount
    function updateReserve(uint _ether, uint _token) external {
        _ether = bound(_ether, 1, 10000);
        _token = bound(_token, 1, 10000);

        vm.deal(address(pool), _ether);
        deal(address(token), address(pool), _token);

        updateInitVars();
    }


    // Set initial K value (AMM)
    function updateInitVars() internal {
        (uint256 x, uint256 y) = pool.getReserves();
        k_value = x * y;

        initialETHBalance = address(this).balance;
        initialTokenBalance = token.balanceOf(address(this));
    }

    receive() external payable {}
}