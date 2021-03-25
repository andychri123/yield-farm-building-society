pragma solidity 0.5.0;

import './utils/Owned.sol';
import './erc20/ERC20.sol';
import './erc20/IERC20.sol';
import './FlashBorrow.sol';
import './FlashRelease.sol';
import './utils/SafeMath.sol';

//-----------------------------------------------------------------------------------------------------------
//                                 |\_______________ (_____\\______________
//     --      --          HH======#H###############H#######################        JOHN 3:16 KJV
//                                 ' ~""""""""""""""`##(_))#H\"""""Y########
//                                                   ))    \#H\       `"Y###
//                                                   "      }#H)
//-----------------------------------------------------------------------------------------------------------

contract Accounts is Owned{
    using SafeMath for uint;

	struct veriAccount{
// the users address
		address acc;
        string username;
        uint balance;
        string pubKey;
        bool activeLoan;
// account will get blacklisted if loans aren't repaid
        bool blacklisted;
        string addressLine1;
        string addressLine2;
        string city;
        string postcode;
        string country;
        uint phoneNumber;
// find a way of verifying the below docs are real and photoshopped without checking by hand
// ipfs hash
        string ID;
// ipfs hash
        string proofOfAddress;
// ipfs hash selfie of the user holding up ID and a note with todays date written on a piece of paper
        string selfie;
        uint timeOfVerification;
        deposit[] deposits;
        withdraw[] withdraws;
        loan[] activeLoans;
        guaranteedLoan[]guaranteedLoans;
// ipfs hash encrypted with the users Public Key
        string[] messages;
        uint earningsCounter;
	}

// look in to tornado cash 
	struct anonAccount{
        address acc;
        uint balance;
        string username;
        string pubKey;
        deposit[] deposits;
	}

// application for veriAccount
	struct application{
        address acc;
// gets sent back to the ethereum address application was made from if application fails
        uint balance;
        string username;
        bool applicationProcessed;
        string addressLine1;
        string addressLine2;
        string city;
        string postcode;
        string country;
        uint phoneNumber;
// find a way of verifying the below docs are real and photoshopped without checking by hand
// ipfs hash
        string ID;
// ipfs hash
        string proofOfAddress;
// ipfs hash selfie of the user holding up ID and a note with todays date written on a piece of paper
        string selfie;
        string email;
        bool emailVerified;
        uint initialDeposit;
	}

	struct deposit{
        uint amount;
        uint timeDate;
// the amount of ether that needs to be flash loaned to release funds -- See if posssible to borrow dai or 
// other stable coin..
        uint amountToRelease;
        uint monthNum;
	}

	struct withdraw{
		uint ammount;
        string timeDate;
	}

//------------------------------------------------------------------------------------------------------------
//                                              ---  LENDING POOL  ---
//------------------------------------------------------------------------------------------------------------

	struct month{
// which month.. IE month 1 is the first month after being verified
        uint monthNum;
// the total amount of ETH that was deposited
        uint depositAmount;
        uint earnings;
        uint loansMade;
	}

	struct loan{
		uint amount;
		uint issueDate;
        address acc;
		string description;
// an ipfs hash
		string image;
		bool repaid;
        uint amountRepaid;
// has the loan failed to be paid on time
		bool late;
// has the loan been forwarded to a debt collection agency or not
	    bool debtCollectionAction;
	    bool fundsReleased;
	}

    struct loanApp{
// the index in the loanApps array
        uint ID;
        uint amount;
        address applicant;
        string description;
        mapping(address => bool) voted;
        bool approved;
    }

    struct guarantor{
    	address guarantor;
    	uint interestRate;
    }

// these are the loans the user is being a guarantor for
    struct guaranteedLoan{
    	address guarantor;
    	uint amount;
    }

    struct TreeItem {
        bytes32 parent;
        NodeTypes nodeType;
    }

    ERC20 public token;
// this is tree root hash
    bytes32 public root;
    enum NodeTypes { Leaf, Node, Root }
// dont store the PGP private keys on chain or use in any functions
    string pubKey;
// this is a PGP signed bitTorrent address of the app that will get released incase the website is shut
// down  --- Do more research on this
    string appBitTorrentAddress;
// PAX G token -- Find best way to achieve
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address VotingMachine;
// total amount of comp PAX G tokens earned b the contract
    uint totalEarned;
// current balance of all deposited ETH in compound - this is updated everytime a deposit or withdrwel is made
    uint veriAccountsBalance;
    uint anonAccountsBalance;
    bool on;
// the amount of cash each member is allowed to borrow max
    uint loanAmountMax;
// the time each loan must be paid back  by or the borrow will get blacklisted
    uint deadline;
    uint interestRate;
// this is the index that the check loan status method will start indexing from
    uint loansChecked;
    uint activeLoans;
// the amount that the owner has withdrawn from the contract
    uint ownerWithdrawn;
    mapping(address => bool)verifiers;
// verified account applications
	mapping(address => application) applications;
	mapping(address => loan) loanApplications;
	mapping(address => anonAccount) anonAccounts;
	mapping(address => veriAccount) veriAccounts;
// the string is the addressLine1 and name submitted in the application -- USE this for new account applications
	mapping(string => bool) blacklistedAddress;
    mapping(address => bool) blacklisted;
    mapping (bytes32 => TreeItem) public tree;
    address[] veriAccountArray;
    month[] months;
    loanApp[] loanApps;
    loan[] loans;
    address[] lateLoans;
// the weekly merkle tree that is is added to the array -- Users can check to see if their is any fraud
    string[] weeklyLoanVotes;

//             /\                                                                     /\
//   _         )( ______________________                       ______________________ )(         _
//  (_)///////(**)______________________>  First Crypto Bank  <______________________(**)\\\\\\\(_)
//             )(                                                                     )(
//             \/                                                                     \/

	constructor(address _votingMachine) public{
		on == false;
		loanAmountMax = 0;
// find a better way to do this --- 
		deadline = 4;
		VotingMachine = _votingMachine;
	}

	modifier onlyVerifier {
        require(verifiers[msg.sender] == true);
        _;
    }

	modifier onlyVotingMachine {
        require(msg.sender == VotingMachine);
        _;
    }

    modifier onlyOn {
        require(on == true);
        _;
    }

    function turnOn() public onlyOwner{
    	on = true;
    }

    function turnOff() public onlyOwner{
         on = false;
    }

// Use sharding when it comes out 
    function setVotingMachineAddress(address vmAddress)public onlyOwner{
    	VotingMachine = vmAddress;
    }

// the PGP Public key for all encrypted ipfs hashes --- all sensitive images that are stored on chain
// are encrypted using the contracts public key
    function setPublicKey(string memory _pubKey)public onlyOwner{
    	pubKey = _pubKey;
    }

// Set a kgpg bitTorrent Address to download the app from
    function setBittorrentAddress(string memory addres)public onlyOwner{
    	appBitTorrentAddress = addres;
    }

// set precision to 3
    function percent(uint numerator, uint denominator, uint precision) public pure returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

// VVvvv  Wrong vvvVV Fix this !!!  vvvvvvvvVV
//    function getEarningsPercentage(uint userEarnings, uint totalEarnings) public view returns(uint _result){
//        uint result = userEarnings / totalEarnings * 100;
//        return result;
//    }

    function getCurrentMonth() public view returns (uint monthIndex){
    	uint monthNum = months.length;
    	return monthNum;
    }

//------------------------------------------------------------------------------------------------------------
//                                              ---  LOANS  ---
//------------------------------------------------------------------------------------------------------------

// requires an FCB Token to run this function
    function applyForLoan(uint amount, string memory description, string memory image) public onlyOn{
        require(amount <= loanAmountMax);
        veriAccount storage _applicant = veriAccounts[msg.sender];
        loan storage _loan = _applicant.activeLoans[_applicant.activeLoans.length];
        require(_loan.repaid == true  || _applicant.activeLoans.length == 0);
        uint ind = _applicant.activeLoans.length + 1;
        loanApp storage _loana = loanApps[ind];
        _loana.ID = ind;
        _loana.description = description;
        _loana.amount = amount;
// call the Voting Machine contract on side chain 
//        _loan.ID = VotingMachine.createLoanApp(description, image, amount, _applicant.acc);
    }

// run by the User after the voting deadline has finished for the application
    function finalizeLoanApplication() public onlyOn{
        veriAccount storage _applicant = veriAccounts[msg.sender];
        loan storage _loan = veriAccounts[msg.sender].activeLoans[veriAccounts[msg.sender].activeLoans.length];
        require(_loan.repaid == true
                || _applicant.activeLoans.length == 0);
        loan storage _newLoan = _applicant.activeLoans[_applicant.activeLoans.length + 1];
        require(_newLoan.amount <= loanAmountMax);
//        require(VotingMachine.loanApps[_loan.ID].approved == true);
        _newLoan.issueDate = now;
        _newLoan.repaid = false;
        _newLoan.amountRepaid = 0;
        _newLoan.late = false;
        _newLoan.debtCollectionAction = false; 
//        releaseFunds(_newLoan.amount, _newLoan.acc);
        _newLoan.fundsReleased = true;
//        _applicant.activeLoans.push(_newLoan);
        activeLoans.add(1);
    }

    function getloanWithGuarantor(address _guarantor, uint amount) public onlyOn{
        require(amount <= loanAmountMax);
        loan storage _loan = veriAccounts[msg.sender].activeLoans[veriAccounts[msg.sender].activeLoans.length];
        _loan.amount = amount;
        _loan.issueDate = now;
        _loan.repaid = false;
        _loan.amountRepaid = 0;
    }

    function repayLoan() public payable onlyOn{
    	loan storage _loan = veriAccounts[msg.sender].activeLoans[veriAccounts[msg.sender].activeLoans.length];
    	require(_loan.amountRepaid < _loan.amount);
    	require(_loan.repaid == false);
    	_loan.amountRepaid.add(msg.value);
    	if (_loan.amountRepaid >= _loan.amount){
    		_loan.repaid = true;
            uint a = activeLoans - 1;
    		activeLoans = a;
    	}
    }

// sends the PAX G to the loan reciever
    function releaseFunds(uint amount, address payable reciever) internal{

    }

    function getActiveLoan() public view returns (uint amount, uint issueDate, address acc,string memory description,
                                                  bool repaid, uint amountRepaid, bool late, 
                                                  bool debtCollectionAction){
        loan storage l = veriAccounts[msg.sender].activeLoans[veriAccounts[msg.sender].activeLoans.length];
        return (l.amount, l.issueDate, l.acc, l.description, l.repaid, l.amountRepaid, l.late, l.debtCollectionAction);
    }

//------------------------------------------------------------------------------------------------------------
//                                              ---  MONTHLY  ---
//------------------------------------------------------------------------------------------------------------

// turn off the contract temporarilrly while statuses are being checked so no new loans can be made
// when this function is running once  a month
// incur a penalty fee for a late loan
// checks all the

    function checkLoanStatuses() public onlyOwner{
    	turnOff();
        for (uint i = loansChecked; i < loans.length; i++) {
            loan storage l = loans[i];
            if (l.repaid == false){
                lateLoans.push(l.acc);
            }       
        }
        uint monthNum = months.length;
        loansChecked.add(months[monthNum].loansMade);
        month storage newMonth = months[months.length];
        newMonth.monthNum = monthNum + 1;
        newMonth.earnings = 0;
        newMonth.loansMade = 0;
        months.push(newMonth);
        uint balance = token.balanceOf(address(this));
        turnOn();
    }

// the rest is sent to the lending the pool
// Can only be run once a month
// the account only gets rewards for the first full month and there after
// the first full month of a deposit is tallied on the second iteration of distributeEarnings the 
// deposit is included in 
    function distributeEarnings() public onlyOwner{}

//------------------------------------------------------------------------------------------------------------
//                                              ---  ACCOUNTS  ---
//------------------------------------------------------------------------------------------------------------

    function makeVerifier(address verifier) public onlyOwner{
        verifiers[verifier] = true;	
    }

    function verify(address applicant, bool verdict) public onlyVerifier{
    	application storage app = applications[applicant];
    	require (app.applicationProcessed == false);
        if (verdict == true){
            veriAccounts[msg.sender].acc = app.acc;
            veriAccounts[msg.sender].username = app.username;
            veriAccounts[msg.sender].balance = app.balance;
//  fix this VVvvvVVVvv Generate public key
            veriAccounts[msg.sender].pubKey = '1';
            veriAccounts[msg.sender].blacklisted = false;
            veriAccounts[msg.sender].activeLoan = false;
            veriAccounts[msg.sender].addressLine1 = app.addressLine1;
            veriAccounts[msg.sender].addressLine2 = app.addressLine2;
            veriAccounts[msg.sender].city = app.city;
            veriAccounts[msg.sender].postcode = app.postcode;
            veriAccounts[msg.sender].country = app.country;
            veriAccounts[msg.sender].phoneNumber = app.phoneNumber;
            veriAccounts[msg.sender].ID = app.ID;
            veriAccounts[msg.sender].proofOfAddress = app.proofOfAddress;
            veriAccounts[msg.sender].selfie = app.selfie;
            veriAccounts[msg.sender].timeOfVerification = now;
            veriAccounts[msg.sender].earningsCounter = 0;
        }
        app.applicationProcessed == true;
    }

// minimum of 100 gbp initial deposit
    function creaAccountApplication(string memory addressL1, string memory addressLine2, string memory city,
    	           string memory postcode, string memory country, uint phoneNumber, string memory ID,
    	           string memory proofOfAddress, string memory selfie, string memory username) public payable{
// change msg.value to 100 gbp in wei
    	require(msg.value >= 10000000);
    	require(blacklisted[msg.sender] == false);
    	require(blacklistedAddress[addressL1] == false);
        application storage applicant = applications[msg.sender];
        applicant.addressLine1 = addressL1;
        applicant.addressLine2 = addressLine2;
        applicant.city = city;
        applicant.postcode = postcode;
        applicant.country = country;
        applicant.username = username;
        applicant.phoneNumber = phoneNumber;
// ipfs hash 
        applicant.ID = ID;
// ipfs hash 
        applicant.proofOfAddress = proofOfAddress;
        applicant.selfie = selfie;
// ipfs hash 
        applicant.initialDeposit = msg.value;
    }

//  minimum of 10 gbp initial deposit
    function createAnon() public payable returns(bool){
// find 10 gbp in wei and change 500
        require(blacklisted[msg.sender] == false);
        require(msg.value >= 500);
        anonAccounts[msg.sender];
        bool success = true;
        return success;
    }

    function getAccount() public view returns (address acc, string memory username, uint balance,
                                               string memory pubKey, bool activeLoan){
        veriAccount storage usde = veriAccounts[msg.sender];
        address acc = usde.acc;
        string memory username = usde.username;
        uint balance = usde.balance;
        string memory pubKey = usde.pubKey;
        bool activeLoan = usde.activeLoan;
        return (acc, username, balance, pubKey, activeLoan);
    }

    function getAnonAccount() public view returns (address acc, string memory username, uint balance,
                                                   string memory pubKey){
        anonAccount storage usdee = anonAccounts[msg.sender];
        address acc = usdee.acc;
        string memory username = usdee.username;
        uint balance = usdee.balance;
        string memory pubKey = usdee.pubKey;
        return (acc, username, balance, pubKey);
    }

// Deposit in ETH  
    function depositCash() public payable{
        veriAccount storage account = veriAccounts[msg.sender];
        deposit storage _deposit = account.deposits[account.deposits.length + 1];
        uint leveregedAmount = msg.value.mul(3);
// fix this so there is enough to pay for the 1% fee
        _deposit.amount = msg.value;
        _deposit.timeDate = now;
        _deposit.monthNum = months.length + 1;
        //uint amount = msg.value - flashloan fee;
        FlashBorrow(msg.value.mul(4));
        account.balance.add(msg.value);
        account.deposits.push(_deposit);
    }

// returns the deposits for an account..
    function getDeposit(uint index) public view returns(uint amount, uint timed, 
                                                        uint amountToRelease, uint monthNum){
        deposit storage m = veriAccounts[msg.sender].deposits[index];
        return (m.amount, m.timeDate, m.amountToRelease, m.monthNum);
    }

// withdraw each deposit individually uint deposit is the index in the deposits array
    function withdrawADeposit(uint index) public{
        veriAccount storage f = veriAccounts[msg.sender];
        deposit storage d = f.deposits[index];
        FlashRelease(d.amountToRelease);
        d.amount = 0;
    }

// owner doesnt have to wait 12 months to claim owners % of the rewards 
    function withdrawEarningsOwner(uint amount) public onlyOwner{
        uint maxWithdraw = percent(5,totalEarned, 3) - ownerWithdrawn;
        require(amount <= maxWithdraw);
        token.transfer(msg.sender, amount);
        ownerWithdrawn.add(amount);
    }

// first month for a deposit all rewards go to the lending pool
// withdraw all of the deposits earnings that are eligible
    function withdrawEarnings() public{
    	veriAccount storage u = veriAccounts[msg.sender]; 
        uint earnings = 0;
        uint _monthNum = months.length - 12;
        for (uint i = u.earningsCounter; i < u.deposits.length; i++){
                deposit storage d = u.deposits[i];
                month storage m = months[d.monthNum];
            if (d.monthNum < _monthNum){
                uint mearnings = percent(d.amount, m.depositAmount, 3);
                earnings + mearnings;
            }else{
                u.earningsCounter = _monthNum;
                token.transfer(msg.sender, earnings);
            }
        }
    }   

// this is the function to blacklist a house address
    function blacklistAddress(string memory addressLine1) internal{
        blacklistedAddress[addressLine1] = true;        
    }

// this function blaclists an account (an ethereum address)
    function blacklistAccount(address _account) internal{
        veriAccount storage account = veriAccounts[_account];
        account.blacklisted = true;
    }

    function getContractETHBalance() public view returns(uint balance){
    	return address(this).balance;
    }


    function getContractPAXBalance() public view returns(uint balance){
    	return address(this).balance;
    }

// returns any ERC20 Tokens that aren't PAX G
    function returnAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens)
                                 public onlyOwner returns (bool success){
        require(tokenAddress != PAX);
        return IERC20(tokenAddress).transfer(tokenOwner, tokens);
    }
// checks to see if the sending address has a verified adress or anon before making a deposit`
    function () external payable{}

//           ___                                                                  _
//          /__/|__                                                            __//|
//          |__|/_/|__                                                       _/_|_||
//          |_|___|/_/|__ ---  VOTING WITH QUORUM AND MERKLE TREE  ---    __/_|___||
//          |___|____|/_/|__                                           __/_|____|_||
//          |_|___|_____|/_/|_________________________________________/_|_____|___||
//          |___|___|__|___|/__/___/___/___/___/___/___/___/___/___/_|_____|____|_||
//          |_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___||
//          |___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|_||
//          |_|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|___|/          

// Use an oracle for voting on the loan applications
// Uses web3 to check if the current ethereum address is a verified account
// Creates array of all the address's that voted for a loan + bool true if approved
// Creates a merkle tree of all the arrays
// The Voting machine contract writes the merkle tree to the FCB Contract
// Only the Oracle's address can run the Weekly audit function
// Side Chain using Geth and PoA Consensus algorithm
// Use Js web3 - Listen for event on sidechain -- then trigger FCB function with main net account

// this function checks, if our proof is valid
// @param _proof array of hashes, from leaf to the root. This is not requirement, to check always whole branch,
// in real product you may want to have option, to validate only part of the branch, but this implementation
// requires whole path
// @return 0 when valid, integer when invalid (just for debugging purposes)
    function checkProof(bytes32[] memory _proof) public view returns (int256) {
// create memory variable, because we will be reading root more than once (saving some gas)
        bytes32 r = root;
// we need to have a tree
        if (r == bytes32(0)) return -1;
// we need to have at least one hash
            uint256 len = _proof.length;
        if (len < 1) return -2;
// because we require whole path, we can also check root, it will save us a gas in situation, when proof
// is invalid
        if (_proof[len - 1] != r) return -2;
        TreeItem memory item = tree[_proof[0]];
// this validation working on whole branch, and because we have information about the leaf,
// we will use it to validate the proof
        if (item.  nodeType != NodeTypes.Leaf) return -4;
// read whole branch up to the root, we start from 1, because leaf is already pulled and validated
        for (uint256 i = 1; i < len; i++) {
// `i-1` because our item is a previous one
            if (!validateNodeType(item.nodeType, i-1, len)) {
// this conversion would be a risk, but in this example I do not expect that many items
// also I return int only because I want to use it for debug purposes
                return int256(i);
            }
            if (item.parent != _proof[i]) {
                return int256(i*1000);
            }
// read next item from our tree
            item = tree[item.parent];
        }
// we can do one last check (just in case) and see if root item do not have parent
        return item.parent == bytes32(0) ? 0 : int256(-5);
    }

// checks if type `nt` is correct according to the level.
// nt node type
// level current level of the node
// branchNodesCount - maximum number of levels (count of all nodes in a branch)
    function validateNodeType(NodeTypes nt, uint level, uint branchNodesCount) private pure returns (bool) {
// first level is a leaf
        if (level == 0 && nt == NodeTypes.Leaf) return true;
// last level is a root
        if (level == branchNodesCount - 1 && nt == NodeTypes.Root) return true;
// all other should be nodes
        if (nt == NodeTypes.Node) return true;
        return false;
    }
}