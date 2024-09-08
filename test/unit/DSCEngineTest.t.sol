// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address wethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 constant STATING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (wethUsdPriceFeed, wbtcUsdPriceFeed, weth, , ) = config
            .activeNetworkConfig();

        ERC20Mock(weth).mint(USER, AMOUNT_COLLATERAL);
    }

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    // Constructor Tests
    function testRevertsIfTokenLeghtnDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(wethUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);
        vm.expectRevert(
            DSCEngine
                .DSCEngine__TokenAddressesAndPriceFeedAdressesMustBeSameLength
                .selector
        );
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    // Price Tests
    function testGetUsdValue() public {
        // how much 15 ETH would be worth $
        uint256 ethAmount = 15e18;
        // 15e18 * 2000/ETH = 30 000e18
        uint256 expectedUsdValue = 30000e18;
        uint256 actualUsdValue = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsdValue, actualUsdValue);
    }

    function testGetTokenAmountFromUsd() public {
        // how much ETH would be worth $4000
        uint256 usdAmount = 4000e18;
        uint256 expectedValue = 2 ether;
        uint256 actualValue = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedValue, actualValue);
    }

    // depositCollateral Tests
    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock unApprovedToken = new ERC20Mock(
            "UnApprovedToken",
            "UAT",
            USER,
            AMOUNT_COLLATERAL
        );
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(unApprovedToken), AMOUNT_COLLATERAL);
    }

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralWithoutMinting() public depositCollateral {
        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, 0);
    }

    function testCanDepositCollateralAndGetAccountInformation()
        public
        depositCollateral
    {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine
            .getAccountInformation(USER);

        uint256 expectedDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(
            weth,
            collateralValueInUsd
        );

        assertEq(totalDscMinted, expectedDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }
}
