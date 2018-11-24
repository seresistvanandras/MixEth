pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {EC} from "./utils/EC.sol";
import {ChaumPedersenVerifier} from "./ChaumPedersenVerifier.sol";
import {ECDSAGeneralized} from "./utils/ECDSAGeneralized.sol";
import "./ERC223ReceivingContract.sol";

/**
* This version of MixEth is designed to run inside of a Counterfactual state channel and such follows these guidelines:
* https://specs.counterfactual.com/02-state-machines#appdefinitions
* Unlike the original MixEth it requires a fixed set of participants, subdivided into 3 groups each of size n: Senders, shufflers and withdrawers
* These must occupy the first n, 2nd n and 3rd n slots in the allParticipants array.
* MixEthChannel also has a different challenge flow, challenges are not made after each shuffle rather all shuffles are made then 
* each shuffler is then given the chance to challenge any shuffle or declare that they see no fraud. If fraud occurs the balance 
* of the shuffler is slashed and particpants will be required to restart the whole process.
*/
contract MixEthChannel {
    using SafeMath for uint;

    /*
    describes a shuffle: contains the shuffled pubKeys and shuffling accumulated constant
    */
    struct Shuffle {
        mapping(uint256 => bool) shuffle; //whether a particular point is present in the shuffle or not
        uint256[2] shufflingAccumulatedConstant; //C^*, the new generator curve point
    }

    struct AppState {
        // a shuffle for each round. At the 0th index are the initial keys
        mapping(uint256 => Shuffle) Shuffles; 
        // allParticpants includes n senders, n receivers/shufflers and n withdrawers
        address[] allParticipants;
        // n: the number of participants in each group
        uint256 keyCount;
        // incremented every time an action is take
        uint256 turn;
        // whether fraud has been committed
        bool fraud;
        // the index, in allParticipants, of the frauder
        uint256 fraudIndex;
        // to ensure that only the valid actions can be taken, we store the current phase in the state
        ActionType phase;
        // the amount of the given token/ether being mixed
        uint256 amount;
    }

    // types of the possible actions that can be taken
    enum ActionType {
        DEPOSIT,
        SHUFFLE,
        NO_FRAUD,
        FRAUD,
        WITHDRAW
    }

    struct Action {
        ActionType actionType;
        // for deposit
        uint256 initPubKeyX;
        uint256 initPubKeyY;
        // for shuffle
        Shuffle newShuffle;
        // for challenge
        uint256[22] proofTranscript;
        uint256 fraudRound;
        // for deposit
        uint256[12] sig;
    }

    function () public {
        revert();
    }

    function applyAction(AppState state, Action action) public pure returns(bytes) {
        // there is a prerequisite that all participants have suppled the same amount of value
        // in the counterfactual framework this would be a condition of the app installation, and is injected as middleware during the install phase

        // there are only 4n turns, and the protocol stops after registering fraud
        require(!state.fraud, "Cannot progress state after fraud.");
        require(state.turn < 4 * state.keyCount, "All turns have been taken."); 

        if(action.ActionType == ActionType.DEPOSIT) {
            require(state.phase == ActionType.DEPOSIT, "Only DEPOSIT actions are currently valid.");
            require(!state.Shuffles[0].shuffle[initPubKeyX] && state.Shuffles[0].shuffle[action.initPubKeyY], "This public key was already added to the shuffle");
            require(EC.onCurve([initPubKeyX, initPubKeyY]), "Invalid public key!");
            // add to the first shuffle round
            state.Shuffles[0].shuffle[action.initPubKeyX] = true;
            state.Shuffles[0].shuffle[action.initPubKeyY] = true;
        }
        else if(action.ActionType == ActionType.SHUFFLE) {
            require(state.phase == ActionType.SHUFFLE, "Only SHUFFLE actions are currently valid.");
            // we add one to the round because the 0 shuffle not a shuffle, it's just the initialised values
            uint256 round = (state.turn % state.keyCount) + 1;

            state.Shuffles[round].shufflingAccumulatedConstant[0] = action.newShuffle.shufflingAccumulatedConstant[0];
            state.Shuffles[round].shufflingAccumulatedConstant[1] = action.newShuffle.shufflingAccumulatedConstant[1];

            //upload new shuffle
            for(i = 0; i < action.newShuffle.shuffle.length; i++) {
                require(!state.Shuffles[round].shuffle[action.newShuffle.shuffle[i]], "Public keys can be added only once to the shuffle!");
                state.Shuffles[round].shuffle[action.newShuffle.shuffle[i]] = true;
            }
        }
        else if(action.ActionType == ActionType.NO_FRAUD) {
            // during the FRAUD phase both FRAUD and NO_FRAUD actions are accepted
            require(state.phase == ActionType.FRAUD, "Only FRAUD or NO_FRAUD actions are currently valid.");
            // dont do anything here - just progress the state
        }
        else if(action.ActionType == ActionType.FRAUD) {
            // during the FRAUD phase both FRAUD and NO_FRAUD actions are accepted
            require(state.phase == ActionType.FRAUD, "Only FRAUD or NO_FRAUD actions are currently valid.");

            // check that the proof references the previous round
            require(action.proofTranscript[0] == state.Shuffles[action.fraudRound - 1].shufflingAccumulatedConstant[0]
                && action.proofTranscript[1] == state.Shuffles[action.fraudRound - 1].shufflingAccumulatedConstant[1], "Wrong shuffling accumulated constant for previous round "); //checking correctness of C*_{i-1}
            require(state.Shuffles[action.fraudRound - 1].shuffle[action.proofTranscript[2]] && state.Shuffles[action.fraudRound - 1].shuffle[action.proofTranscript[3]], "Shuffled key is not included in previous round"); //checking that shuffled key is indeed included in previous shuffle

            // check that the proof references the current round
            require(action.proofTranscript[4] == state.Shuffles[action.fraudRound].shufflingAccumulatedConstant[0]
                 && action.proofTranscript[5] == state.Shuffles[action.fraudRound].shufflingAccumulatedConstant[1], "Wrong current shuffling accumulated constant"); //checking correctness of C*_{i}
            require(!state.Shuffles[action.fraudRound].shuffle[action.proofTranscript[6]] || !state.Shuffles[action.fraudRound].shuffle[action.proofTranscript[7]], "Final public key is indeed included in current shuffle");
            
            // is the fraud proof valid
            require(ChaumPedersenVerifier.verifyChaumPedersen(action.proofTranscript), "Chaum-Pedersen Proof not verified");
            
            // find the index of the person who commited fraud
            state.fraudIndex = action.fraudRound - 1 + state.keyCount;
            state.fraud = true;

        } else if(action.ActionType == ActionType.WITHDRAW) {
            require(state.phase == ActionType.WITHDRAW, "Only WITHDRAW actions are currently valid.");
            // the round is the final round
            uint256 round = state.keyCount;

            require(state.Shuffles[round].shuffle[sig[2]] && state.Shuffles[round].shuffle[sig[3]], "Your public key is not included in the final shuffle!"); //public key is included in Shuffled
            require(sig[0] == state,Shuffles[round].shufflingAccumulatedConstant[0]
                && sig[1] == state.Shuffles[round].shufflingAccumulatedConstant[1], "Your signature is using a wrong generator!"); //shuffling accumulated constant is correct
            // who is taking the current turn? they need to provide a relevant sig
            address turnTaker = state.allParticipants[getTurnTaker(state)];
            require(sig[4] == uint(sha3(turnTaker, sig[2], sig[3])), "Signed an invalid message!"); //this check is needed to deter front-running attacks
            require(ECDSAGeneralized.verify(sig), "Your signature is not verified!");

            // remove the keys from the final shuffle - this is to prevent replay attacks
            state.Shuffles[round].shuffle[sig[2]] = false;
            state.Shuffles[round].shuffle[sig[3]] = false;
        }
        else {
            // other actions are not accepted
            require(true, false, "The supplied action type was invalid.");
        }

        // increment the turn
        state.turn = state.turn + 1;

        // move to the next phase if necessary
        if(state.turn % state.keyCount) {
            if(state.phase == ActionType.DEPOSIT) state.phase = ActionType.SHUFFLE;
            if(state.phase == ActionType.SHUFFLE) state.phase = ActionType.FRAUD;
            if(state.phase == ActionType.FRAUD) state.phase = ActionType.WITHDRAW;
        }


        return abi.encode(state);
    }


    function getTurnTaker(AppState state) public pure returns (uint256) {
        // signingKeys = [ depositor 1..n ] [ shuffler n+1...2n] [ withdrawer 2n+1...3n]
        // turns:
        //      each depositor deposits
        //      each shuffler shufflers
        //      each shuffler challenges
        //      each withdrawer withdraws
        // turn < keyCount = deposit
        // turn >= keyCount && turn < 2 * keyCount = shuffle
        // turn >= 2 * keyCount && turn < 3 * keyCount = challenge
        // turn >= 3 * keyCount = withdraw

        if(state.turn < state.keyCount) return state.turn;
        if(state.turn >= state.keyCount && state.turn < 2 * state.keyCount) return state.turn;
        if(state.turn >= 2 * state.keyCount && state.turn < 3 * state.keyCount) return state.turn - state.keyCount;
        if(state.turn >= 3 * state.keyCount) return state.turn - state.keyCount;
        else return state.turn;
    }    

    function isTerminalState(AppState state) public pure returns(bool) {
        return state.fraud || state.turn == 4 * state.keyCount;
    }

    function resolve(AppState state, Transfer.Terms terms) public pure {
        address[] memory to = new address[];
        bytes[] memory data = new bytes[];
        uint256[] memory amounts = new uint256[];

        if(state.turn == state.keyCount * 4) {
            // all turns have been taken, send out the proper resolution
            
            // return deposits to shufflers and withdrawers
            // and also send to withdrawers
            for(uint256 i = 0; i < state.allParticipants.length; i++) {   
                if(i >= state.keyCount < 2 * state.keyCount) {
                    to.push(allParticipants[i]);
                    amounts.push(state.amount);
                }
                else if(i >= 2 * state.keyCount) {
                    to.push(allParticipants[i]);
                    amounts.push(2 * state.amount);
                }
            }
        }
        else {
            // either fraud state, or no turn taken
            // punish this person by not returning their deposit
            uint256 punished;
            if(state.fraud) {
                punished = state.fraudIndex;
            }
            else {
                punished = getTurnTaker(appState);
            }

            for(uint256 i = 0; i < state.allParticipants.length; i++) {   
                // all participants had a 1 ether deposit which we refund
                if(i != punished) {
                    to.push(allParticipants[i]);
                    amounts.push(state.amount);
                }
            }
        }

        // distribute to all
        return Transfer.Transaction(terms.assetType, terms.token, to, amounts, data);
    }
}
