pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import {EC} from './utils/EC.sol';
import {ChaumPedersenVerifier} from './ChaumPedersenVerifier.sol';
import {ECDSAGeneralized} from './utils/ECDSAGeneralized.sol';
import './ERC223ReceivingContract.sol';

/*
 * Declare the ERC20Compatible interface in order to handle ERC20 tokens transfers
 * to and from the Mixer. Note that we only declare the functions we are interested in,
 * namely, transferFrom() (used to do a Deposit), and transfer() (used to do a withdrawal)
**/
contract ERC20Compatible {
  function transferFrom(address from, address to, uint256 value) public;
  function transfer(address to, uint256 value) public;
}

contract MixEth is ERC223ReceivingContract {
  using SafeMath for uint;

  uint256 public amt = 1000000000000000000; //1 ether in wei, the amount of ether to be mixed;
  uint256 public shufflingDeposit = 1000000000000000000; // 1 ether, TBD
  mapping(address => bool) public shuffleRound; //token address to the parity of the round. we only store the parity of the shuffle round! false -> 0, true -> 1
  mapping(address => Status) public shufflers; //shuffler address to their state
  mapping(address => mapping(bool => Shuffle)) public Shuffles; //token address to round to shuffle

  /*
  describes a shuffle: contains the shuffled pubKeys and shuffling accumulated constant
  */
  struct Shuffle {
    mapping(uint256 => bool) shuffle; //whether a particular point is present in the shuffle or not
    uint256[2] shufflingAccumulatedConstant; //C^*, the new generator curve point
    address shuffler;
    uint256 noOfPoints; //note that one of these points is always the shuffling accumulated constant
    uint256 blockNo;
  }

  struct Status {
    bool alreadyShuffled;
    bool slashed;
  }

  event newDeposit(address indexed token, bool actualRound, uint256[2] newPubKey);
  event newShuffle(address indexed token, bool actualRound, address shuffler, uint256[] shuffle, uint256[2] shufflingAccumulatedConstant);
  event successfulChallenge(address indexed token, bool actualRound, address shuffler);
  event successfulWithdraw(address indexed token, bool actualRound, uint256[2] withdrawnPubKey);

  function () public {
    revert();
  }

  function depositEther(uint256 initPubKeyX, uint256 initPubKeyY) public payable onlyInWithdrawalDepositPeriod(0x0) {
    require(msg.value == amt, "Ether denomination is not correct!");
    require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
    require(!Shuffles[0x0][shuffleRound[0x0]].shuffle[initPubKeyX] &&
      !Shuffles[0x0][shuffleRound[0x0]].shuffle[initPubKeyY], "This public key was already added to the shuffle");
    Shuffles[0x0][shuffleRound[0x0]].shuffle[initPubKeyX] = true;
    Shuffles[0x0][shuffleRound[0x0]].shuffle[initPubKeyY] = true;
    Shuffles[0x0][shuffleRound[0x0]].noOfPoints = Shuffles[0x0][shuffleRound[0x0]].noOfPoints.add(1);

    emit newDeposit(0x0, shuffleRound[0x0], [initPubKeyX, initPubKeyY]);
  }

  /*
     * Deposit a specific denomination of ERC20 compatible tokens which can only be withdrawn
     * by providing a modified ECDSA sig by one of the public keys.
    **/
  function depositERC20Compatible(address token, uint256 initPubKeyX, uint256 initPubKeyY) public onlyInWithdrawalDepositPeriod(token) {
    uint256 codeLength;
    assembly {
        codeLength := extcodesize(token)
    }
    require(token != 0 && codeLength > 0);
    require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
    require(!Shuffles[token][shuffleRound[token]].shuffle[initPubKeyX] &&
      !Shuffles[token][shuffleRound[token]].shuffle[initPubKeyY], "This public key was already added to the shuffle");
    Shuffles[token][shuffleRound[token]].shuffle[initPubKeyX] = true;
    Shuffles[token][shuffleRound[token]].shuffle[initPubKeyY] = true;
    Shuffles[token][shuffleRound[token]].noOfPoints = Shuffles[token][shuffleRound[token]].noOfPoints.add(1);

    ERC20Compatible untrustedErc20Token = ERC20Compatible(token);
    untrustedErc20Token.transferFrom(msg.sender, this, 100);

    emit newDeposit(token, shuffleRound[token], [initPubKeyX, initPubKeyY]);
  }

  /*
    @param address token: refers to the token address shuffler wants to shuffle
    @param uint256[] _oldShuffle: refers to the last but one to-be-deleted shuffle
    @param uint256[] _shuffle: the new to-be-uploaded shuffle
  */
  function uploadShuffle(address token, uint256[] _oldShuffle, uint256[] _shuffle, uint256[2] _newShufflingConstant) public onlyInShufflingPeriod(token) payable {
    require(msg.value == shufflingDeposit+(_shuffle.length/2-Shuffles[token][shuffleRound[token]].noOfPoints)*1 ether, "Invalid shuffler deposit amount!"); //shuffler can also deposit new pubkeys
    require(!shufflers[msg.sender].alreadyShuffled, "Shuffler is not allowed to shuffle more than once!");
    require(_oldShuffle.length/2 == Shuffles[token][!shuffleRound[token]].noOfPoints, "Incorrectly referenced the last but one shuffle");
    // remove the last but one shuffler
    for(uint256 i = 0; i < _oldShuffle.length; i++) {
      require(Shuffles[token][!shuffleRound[token]].shuffle[_oldShuffle[i]],"A public key was added twice to the shuffle");
      Shuffles[token][!shuffleRound[token]].shuffle[_oldShuffle[i]] = false;
    }
    Shuffles[token][!shuffleRound[token]].shufflingAccumulatedConstant[0] = _newShufflingConstant[0];
    Shuffles[token][!shuffleRound[token]].shufflingAccumulatedConstant[1] = _newShufflingConstant[1];
    //upload new shuffle
    for(i = 0; i < _shuffle.length; i++) {
      require(!Shuffles[token][!shuffleRound[token]].shuffle[_shuffle[i]], "Public keys can be added only once to the shuffle!");
      Shuffles[token][!shuffleRound[token]].shuffle[_shuffle[i]] = true;
    }
    Shuffles[token][!shuffleRound[token]].shuffler = msg.sender;
    Shuffles[token][!shuffleRound[token]].noOfPoints = (_shuffle.length)/2;
    Shuffles[token][!shuffleRound[token]].blockNo = block.number;
    shuffleRound[token] = !shuffleRound[token];
    shufflers[msg.sender].alreadyShuffled = true; // a receiver can only shuffle once

    emit newShuffle(token, !shuffleRound[token], msg.sender, _shuffle, _newShufflingConstant);
  }

  /*
    MixEth checks the correctness of the round-th shuffle
    which is stored at Shuffles[round].
    If challenge accepted malicious shuffler's deposit is slashed.
  */
  function challengeShuffle(uint256[22] proofTranscript, address token) public onlyInChallengingPeriod(token) {
    bool round = shuffleRound[token]; //only current shuffles can be challenged
    require(proofTranscript[0] == Shuffles[token][!round].shufflingAccumulatedConstant[0]
      && proofTranscript[1] == Shuffles[token][!round].shufflingAccumulatedConstant[1], "Wrong shuffling accumulated constant for previous round "); //checking correctness of C*_{i-1}
    require(Shuffles[token][!round].shuffle[proofTranscript[2]] && Shuffles[token][!round].shuffle[proofTranscript[3]], "Shuffled key is not included in previous round"); //checking that shuffled key is indeed included in previous shuffle
    require(proofTranscript[4] == Shuffles[token][round].shufflingAccumulatedConstant[0]
      && proofTranscript[5] == Shuffles[token][round].shufflingAccumulatedConstant[1], "Wrong current shuffling accumulated constant"); //checking correctness of C*_{i}
    require(!Shuffles[token][round].shuffle[proofTranscript[6]] || !Shuffles[token][round].shuffle[proofTranscript[7]], "Final public key is indeed included in current shuffle");
    require(ChaumPedersenVerifier.verifyChaumPedersen(proofTranscript), "Chaum-Pedersen Proof not verified");
    shufflers[Shuffles[token][round].shuffler].slashed = true;
    shuffleRound[token] = !shuffleRound[token];

    emit successfulChallenge(token, round, Shuffles[token][round].shuffler);
  }

  //receivers can withdraw funds at most once
  function withdrawAmt(uint256[12] sig) public {
    withdrawChecks(sig, 0x0);

    msg.sender.transfer(amt);
  }

  function withdrawERC20Compatible(uint256[12] sig, address token) public {
    withdrawChecks(sig, token);

    ERC20Compatible untrustedErc20Token = ERC20Compatible(token);
    untrustedErc20Token.transfer(msg.sender, 100); //to-be-overwritten TODO:
   }

   function withdrawChecks(uint256[12] sig, address token) internal onlyInWithdrawalDepositPeriod(token) {
     require(Shuffles[token][shuffleRound[token]].shuffle[sig[2]] && Shuffles[token][shuffleRound[token]].shuffle[sig[3]], "Your public key is not included in the final shuffle!"); //public key is included in Shuffled
     require(sig[0] == Shuffles[token][shuffleRound[token]].shufflingAccumulatedConstant[0]
       && sig[1] == Shuffles[token][shuffleRound[token]].shufflingAccumulatedConstant[1], "Your signature is using a wrong generator!"); //shuffling accumulated constant is correct
     require(sig[4] == uint(sha3(msg.sender, sig[2], sig[3])), "Signed an invalid message!"); //this check is needed to deter front-running attacks
     require(ECDSAGeneralized.verify(sig), "Your signature is not verified!");
     Shuffles[token][shuffleRound[token]].shuffle[sig[2]] = false;
     Shuffles[token][shuffleRound[token]].shuffle[sig[3]] = false;
     Shuffles[token][shuffleRound[token]].noOfPoints = Shuffles[token][shuffleRound[token]].noOfPoints.sub(1);

     emit successfulWithdraw(token, shuffleRound[token], [sig[2], sig[3]]);
   }

  function withdrawDeposit() public onlyShuffler onlyHonestShuffler {
    shufflers[msg.sender].slashed = true; //we only allow to withdraw shuffler deposits once
    msg.sender.transfer(shufflingDeposit);
  }

  //maybe these time parameters needs to be changed, but might be enough
  modifier onlyInChallengingPeriod(address token) {
    require(block.number <= Shuffles[token][shuffleRound[token]].blockNo + 10, "You can not challenge this shuffle right now!");
    _;
  }

  modifier onlyInWithdrawalDepositPeriod(address token) {
    require(Shuffles[token][shuffleRound[token]].blockNo + 10 < block.number, "You can not withdraw/deposit right now!");
    _;
  }

  modifier onlyInShufflingPeriod(address token) {
    require(Shuffles[token][shuffleRound[token]].blockNo + 20 < block.number, "You can not shuffle right now!");
    _;
  }

  modifier onlyShuffler() {
    require(shufflers[msg.sender].alreadyShuffled, "You have not shuffled!");
    _;
  }

  modifier onlyHonestShuffler() {
    require(!shufflers[msg.sender].slashed, "Your shuffling deposit has been slashed!");
    _;
  }

}
