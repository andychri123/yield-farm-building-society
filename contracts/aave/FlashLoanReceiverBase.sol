pragma solidity 0.5.0;

import "../utils/SafeMath.sol";
import "../erc20/IERC20.sol";
import "../erc20/SafeERC20.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";
import "../utils/Withdrawable.sol";

contract FlashLoanReceiverBase is IFlashLoanReceiver, Withdrawable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    ILendingPoolAddressesProvider public addressesProvider;

    constructor(address _addressProvider) public {
        addressesProvider = ILendingPoolAddressesProvider(_addressProvider);
    }

    function receive() payable external {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount) internal {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(address payable _destination, address _reserve, uint256 _amount) internal {
        if(_reserve == ethAddress) {
//            bool success = _destination.transfer(_amount);
//            (bool success, ) = _destination.call({value: _amount});
//            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_reserve).safeTransfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve) internal view returns(uint256) {
        if(_reserve == ethAddress) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}
