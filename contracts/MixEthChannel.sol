pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {EC} from "./utils/EC.sol";
import {ChaumPedersenVerifier} from "./ChaumPedersenVerifier.sol";
import {ECDSAGeneralized} from "./utils/ECDSAGeneralized.sol";
import "./ERC223ReceivingContract.sol";
import {Transfer} from "./Transfer.sol";

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

    function shuffleOfRound(uint256[] shuffles, uint256 pointsInRound, uint256 round) private pure returns(uint256[]) {
        uint256[] memory shuffleRound = new uint256[](pointsInRound * 2);

        // 2 points per key, round is zero indexed
        for(uint256 i = round * 2 * pointsInRound; i < 2 * pointsInRound; i++) {
            shuffleRound[i] = shuffles[i];
        }

        return shuffleRound;
    }

    function shufflePointExistsInRound(uint256[] shuffles, uint256 point, uint256 pointsInRound, uint256 round) private pure returns(bool) {
        uint256[] memory shuffleRound = shuffleOfRound(shuffles, pointsInRound, round);
        return existsInArray(shuffleRound, point);
    }

    function existsInArray(uint256[] pointArray, uint256 point) private pure returns(bool) {
        // 2 points per key
        for(uint256 i = 0; i < pointArray.length; i++) {
            if(pointArray[i] == point) return true;
        }

        return false;
    }

    function accumulatorOfRound(uint256[] accumulatedConstants, uint256 round) private pure returns(uint256[]) {
        uint256[] memory accumulatorRound = new uint256[](2);

        // 2 accumulator points per round
        for(uint256 i = (round - 1) * 2; i < round * 2; i++) {
            accumulatorRound[i] = accumulatedConstants[i];
        }

        return accumulatorRound;
    }

    struct AppState {
        // the accumulated shuffles
        // this would be much much better modeled, and be more efficient, as a mapping 
        // but currently structs passed in to public functions cannot contain complex types
        uint256[] shuffles;
        uint256[] shufflingAccumulatedConstants; 
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
        // A list of the keys that have already been withdrawn
        uint256[] withdrawnKeys;
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
        uint256[] newShuffle;
        uint256[] newAccumulatedConstant;
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

        if(action.actionType == ActionType.DEPOSIT) {
            require(state.phase == ActionType.DEPOSIT, "Only DEPOSIT actions are currently valid.");
            require(!shufflePointExistsInRound(state.shuffles, action.initPubKeyX, state.keyCount, 0) && !shufflePointExistsInRound(state.shuffles, action.initPubKeyY, state.keyCount, 0), "This public key was already added to the shuffle");
            require(EC.onCurve([action.initPubKeyX, action.initPubKeyY]), "Invalid public key!");
            // add to the first shuffle round
            state.shuffles[state.turn * 2] = action.initPubKeyX;
            state.shuffles[(state.turn * 2) + 1] = action.initPubKeyY;
        }
        else if(action.actionType == ActionType.SHUFFLE) {
            require(state.phase == ActionType.SHUFFLE, "Only SHUFFLE actions are currently valid.");
            // we add one to the round because the 0 shuffle not a shuffle, it's just the initialised values
            uint256 shuffleRound = (state.turn % state.keyCount) + 1;

            state.shufflingAccumulatedConstants[2 * (state.turn % state.keyCount)] = action.newAccumulatedConstant[0];
            state.shufflingAccumulatedConstants[2 * (state.turn % state.keyCount) + 1] = action.newAccumulatedConstant[1];

            //upload new shuffle
            for(uint256 i = 0; i < action.newShuffle.length; i++) {
                require(!shufflePointExistsInRound(state.shuffles, action.newShuffle[i], state.keyCount, shuffleRound), "Public keys can be added only once to the shuffle!");
                state.shuffles[(shuffleRound * state.keyCount) + i] = action.newShuffle[i];
            }
        }
        else if(action.actionType == ActionType.NO_FRAUD) {
            // during the FRAUD phase both FRAUD and NO_FRAUD actions are accepted
            require(state.phase == ActionType.FRAUD, "Only FRAUD or NO_FRAUD actions are currently valid.");
            // dont do anything here - just progress the state
        }
        else if(action.actionType == ActionType.FRAUD) {
            // during the FRAUD phase both FRAUD and NO_FRAUD actions are accepted
            require(state.phase == ActionType.FRAUD, "Only FRAUD or NO_FRAUD actions are currently valid.");

            //uint256[] memory previousRound = shuffleOfRound(state.shuffles, state.keyCount, action.fraudRound - 1);
            uint256[] memory previousRoundAccumulatedConstant = accumulatorOfRound(state.shufflingAccumulatedConstants, action.fraudRound - 1);

            // check that the proof references the previous round
            require(action.proofTranscript[0] == previousRoundAccumulatedConstant[0]
                && action.proofTranscript[1] == previousRoundAccumulatedConstant[1], "Wrong shuffling accumulated constant for previous round "); //checking correctness of C*_{i-1}
            require(shufflePointExistsInRound(state.shuffles, action.proofTranscript[2], state.keyCount, action.fraudRound - 1)
                && shufflePointExistsInRound(state.shuffles, action.proofTranscript[3], state.keyCount, action.fraudRound - 1), "Shuffled key is not included in previous round"); //checking that shuffled key is indeed included in previous shuffle

            uint256[] memory fraudRoundAccumulatedConstant = accumulatorOfRound(state.shufflingAccumulatedConstants, action.fraudRound);

            // check that the proof references the fraud round
            require(action.proofTranscript[4] == fraudRoundAccumulatedConstant[0]
                 && action.proofTranscript[5] == fraudRoundAccumulatedConstant[1], "Wrong current shuffling accumulated constant"); //checking correctness of C*_{i}
            require(!shufflePointExistsInRound(state.shuffles, action.proofTranscript[6], state.keyCount, action.fraudRound) 
                    || !shufflePointExistsInRound(state.shuffles, action.proofTranscript[7], state.keyCount, action.fraudRound) , "Final public key is indeed included in current shuffle");
            
            // is the fraud proof valid
            require(ChaumPedersenVerifier.verifyChaumPedersen(action.proofTranscript), "Chaum-Pedersen Proof not verified");
            
            // find the index of the person who commited fraud
            state.fraudIndex = action.fraudRound - 1 + state.keyCount;
            state.fraud = true;

        } else if(action.actionType == ActionType.WITHDRAW) {
            require(state.phase == ActionType.WITHDRAW, "Only WITHDRAW actions are currently valid.");
            // the round is the final round
            uint256 withdrawRoundNumber = state.keyCount;
            uint256[] memory finalAccumulator = accumulatorOfRound(state.shufflingAccumulatedConstants, withdrawRoundNumber);
            
            require(shufflePointExistsInRound(state.shuffles, action.sig[2], state.keyCount, withdrawRoundNumber) 
                && shufflePointExistsInRound(state.shuffles, action.sig[3], state.keyCount, withdrawRoundNumber), "Your public key is not included in the final shuffle!"); //public key is included in Shuffled
            // but has it already been withdrawn?
            require(!existsInArray(state.withdrawnKeys, action.sig[2]) 
                && !existsInArray(state.withdrawnKeys, action.sig[3]), "Public key has already been withdrawn");
                // record this withdrawal
            state.withdrawnKeys[2 * (state.turn % state.keyCount)] = action.sig[2];
            state.withdrawnKeys[2 * (state.turn % state.keyCount) + 1] = action.sig[3];
            
            // check the accumulator
            require(action.sig[0] == finalAccumulator[0]
                && action.sig[1] == finalAccumulator[1], "Your signature is using a wrong generator!"); //shuffling accumulated constant is correct
            // who is taking the current turn? they need to provide a relevant sig
            address turnTaker = state.allParticipants[getTurnTaker(state)];
            require(action.sig[4] == uint(keccak256(abi.encodePacked(turnTaker, action.sig[2], action.sig[3]))), "Signed an invalid message!"); //this check is needed to deter front-running attacks
            
            require(ECDSAGeneralized.verify(action.sig), "Your signature is not verified!");
        }
        else {
            // other actions are not accepted
            require(false, "The supplied action type was invalid.");
        }

        // increment the turn
        state.turn = state.turn + 1;

        // move to the next phase if necessary
        if(state.turn % state.keyCount == 0) {
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

    function resolve(AppState state, Transfer.Terms terms) public pure returns(Transfer.Transaction) {
        address[] memory to = new address[](state.keyCount);
        bytes[] memory data = new bytes[](state.keyCount);
        uint256[] memory amounts = new uint256[](state.keyCount);

        if(state.turn == state.keyCount * 4) {
            // all turns have been taken, send out the proper resolution
            
            // return deposits to shufflers and withdrawers
            // and also send to withdrawers
            for(uint256 participant = 0; participant < state.allParticipants.length; participant++) {   
                if(participant >= state.keyCount && participant < 2 * state.keyCount) {
                    to[participant] = state.allParticipants[participant];
                    amounts[participant] = state.amount;
                }
                else if(participant >= 2 * state.keyCount) {
                    to[participant] = state.allParticipants[participant];
                    amounts[participant] = 2 * state.amount;
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
                punished = getTurnTaker(state);
            }

            for(uint256 i = 0; i < state.allParticipants.length; i++) {   
                if(i != punished) {
                    to[i] = state.allParticipants[i];
                    amounts[i] = state.amount;
                }
            }
        }

        // distribute to all
        return Transfer.Transaction(terms.assetType, terms.token, to, amounts, data);
    }
}
