pragma solidity 0.5.0;

import './aave/FlashLoanReceiverBase.sol';
import './aave/ILendingPoolAddressesProvider.sol';
import './aave/ILendingPool.sol';
import './comp/comp.sol';
import './comp/borrow.sol';
import './IKyberNetworkProxy.sol';

contract IKyberNetworkProxyyy {

    event ExecuteTradeyy(
        address indexed trader,
        IERC20 src,
        IERC20 dest,
        address destAddress,
        uint256 actualSrcAmount,
        uint256 actualDestAmount,
        address platformWallet,
        uint256 platformFeeBps
    );

    /// @notice backward compatible
    function tradeWithHintyy(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function tradeWithHintAndFeeyy(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function tradeyy(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet
    ) external payable returns (uint256);

    /// @notice backward compatible
    /// @notice Rate units (10 ** 18) => destQty (twei) / srcQty (twei) * 10 ** 18
    function getExpectedRateyy(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFeeyy(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

contract FlashRelease is FlashLoanReceiverBase, Borrow, Comp{

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address payable cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address comptroller = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
// change the address below
    address payable accountsContract = 0x4DDC2d193948926d02F9b1fE9e1Daa07182709d5;
    IKyberNetworkProxyyy kyberProxy;

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}

// set precisioin to 3
    function percent(uint numerator, uint denominator, uint precision) public pure returns(uint quotient) {
// caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
// with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params
                             )external {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        supplyErc20ToCompound(DAI, cDAI, address(this).balance);
        uint amountToBorrow = percent(75, _amount, 3);
//        borrowEth(cETH, comptroller, cDAI,
//                 DAI, _amount, amountToBorrow);
        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 1 ether;

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }
}
