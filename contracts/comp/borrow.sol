pragma solidity 0.5.0;

//import './comp.sol';
//import './comptroller.sol';

contract Borrow {
//    event MyLog(string, uint256);

//    function borrowEth(address payable _cEtherAddress, address _comptrollerAddress, address _cDaiAddress,
//                              address _daiAddress, uint256 _daiToSupplyAsCollateral, uint numWeiToBorrow
//                             )public returns (uint) {
//        CETh c = CETh(_cEtherAddress);
//        ComptrollerInterface comptroller = ComptrollerInterface(_comptrollerAddress);
//        CERc20 cDai = CERc20(_cDaiAddress);
//        ERc20 dai = ERc20(_daiAddress);
        // Approve transfer of DAI
//        dai.approve(_cDaiAddress, _daiToSupplyAsCollateral);

        // Supply DAI as collateral, get cDAI in return
//        uint256 error = cDai.mint(_daiToSupplyAsCollateral);
//        require(error == 0, "CErc20.mint Error");

        // Enter the DAI market so you can borrow another type of asset
//        address[] memory cTokens = new address[](1);
//        cTokens[0] = _cDaiAddress;
//        uint[] memory errors = comptroller.enterMarkets(cTokens);
//        if (errors[0] != 0) {
//            revert("Comptroller.enterMarkets failed.");
//        }
        // Get my account's total liquidity value in Compound
//        (uint256 error2, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(address(this));
//        if (error2 != 0) {
//            revert("Comptroller.getAccountLiquidity failed.");
///        }
//        require(shortfall == 0, "account underwater");
//        require(liquidity > 0, "account has excess collateral");

        // Borrowing near the max amount will result
        // in your account being liquidated instantly
//        emit MyLog("Maximum ETH Borrow (borrow far less!)", liquidity);

        // Get the collateral factor for our collateral
//        (
//          bool isListed,
//          uint collateralFactorMantissa
//        ) = comptroller.markets(_cDaiAddress);
//        emit MyLog('DAI Collateral Factor', collateralFactorMantissa);

        // Get the amount of ETH added to your borrow each block
//        uint borrowRateMantissa = c.exchangeRateCurrent();
//        emit MyLog('Current ETH Borrow Rate', borrowRateMantissa);

        // Borrow a fixed amount of ETH below our maximum borrow amount
        //uint256 numWeiToBorrow = 20000000000000000; // 0.02 ETH

        // Borrow DAI, check the DAI balance for this contract's address
//        c.borrow(numWeiToBorrow);

//        uint256 borrows = c.borrowBalanceCurrent(address(this));
//        emit MyLog("Current ETH borrow amount", borrows);

//        return borrows;
//    }

}

interface ERc20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface CERc20 {
    function mint(uint256) external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);    
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
}

interface CETh {
    function mint() external payable;
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function borrowBalanceCurrent(address) external returns(uint);
    function borrow(uint)external returns (bool);
}
