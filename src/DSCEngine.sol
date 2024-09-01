// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author  CryptoSxk
 * @title   DSCEngine
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == 1$ peg
 * This stablecoin has the properties:
 * - Exogenous
 * - Dollar pegged
 * - Algoritmically stable
 *
 * It is similar to DAI id DAI had no governance, no fees, and was only backed by WETH and WBTC.
 *
 * Our DSC system should always be 'overcollateralized'. At no point, should the value of all collateral <= the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the DSC system. It handles all the logic for mining and redeeming DCS, as well as depositing & withdrawing collateral.
 * @notice This contract is VERY loosely based on the MakerDAO (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    // Errors
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesAndPriceFeedAdressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    // State Variables
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;

    DecentralizedStableCoin private immutable i_dsc;

    // Emits
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    // Modifiers
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    // Functions
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddressess, address dscAddress) {
        i_dsc = DecentralizedStableCoin(dscAddress);
        // USD Price Feeds
        if (tokenAddresses.length != priceFeedAddressess.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAdressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddressess[i];
        }
    }

    // External Functions
    function depositCollateralAndMintDcs() external {}
    /**
     * @notice  Follows CEI standard
     * @param   tokenCollateralAddress  The address of the token to deposit as collateral
     * @param   amountCollateral  The amount of collateral to deposit
     */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateralForDcs() external {}
    function redeemCollateral() external {}
    function mintDsc() external {}
    function burnDcs() external {}
    function liquidate() external {}
    function getHealthFactor() external view {}
}
