pragma solidity 0.5.0;

import './aave/FlashLoanReceiverBase.sol';
import './aave/ILendingPoolAddressesProvider.sol';
import './aave/ILendingPool.sol';
import './comp/comp.sol';
import './comp/borrow.sol';
import './erc20/IERC20.sol';
//import './IKyberNetworkProxy.sol';


interface IKyberNetworkProxy {

    event ExecuteTrade(
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
    function tradeWithHint(
        ERC20 src,
        uint256 srcAmount,
        ERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    ) external payable returns (uint256);

    function tradeWithHintAndFee(
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

    function trade(
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
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 worstRate);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
}

contract FlashBorrow is FlashLoanReceiverBase, Borrow, Comp{

    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address payable cETH = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    address comptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
// change the address below
    address payable accountsContract = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    IKyberNetworkProxy kyberProxy;
    address kyber = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
///  APPROVE the erc20 token to swap 
//    IERC20 iERC20;

    constructor(address _addressProvider, address payable _accountsContract) 
                FlashLoanReceiverBase(_addressProvider) public {
        address payable accountsContract = accountsContract;
//        kyberProxy = kyberProxy(kyber);
    }

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
    function executeOperation(address _reserve, uint256 _amount, uint _fee, bytes calldata _params,
                              uint amountToBorrow)external payable {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        uint amountToBorrow = percent(75, _amount, 3);
        supplyErc20ToCompound(DAI, cDAI, address(this).balance);
//        borrowEth(cETH, comptroller, cDAI,
//                  DAI, _amount, amountToBorrow);
//        uint256 expectedRate =  kyberProxy.getExpectedRateAfterFee(IERC20, amountToBorrow, IERC20 ,
//            0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee, // ETH token address
//         //   DAI, // DAI token address
//            10000000, // 1 WBTC
//            25, // 0.25%
//            DAI
//           // '' // empty hint);
//            );
//        uint actualDestAmount = kyberProxy.tradeWithHintAndFee(IERC20, 
        //    0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee, // ETH address
//            1000000000000000000, // 1 ETH
//            IERC20,
//            address(this), // destAddress
//        //    DAI, // DAI address
//            9999999999999999999999999999999, // maxDestAmount: arbitarily large to swap full amount
//            expectedRate, // minConversionRate: value from getExpectedRate call
//            0x56178a0d5f301baf6cf3e1cd53d9863437345bf9, // platform wallet
//            25, // 0.25%
//            '').value(msg.value)();
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
 // commented out to compile
 //       accountsContract;
        }
    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset, uint amount) public {
        bytes memory data = '';
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }
}
