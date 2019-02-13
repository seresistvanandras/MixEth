let MinimumViableMultiSig = artifacts.require("./MinimumViableMultisig");
let LibSignature = artifacts.require("./LibSignature");
let MultiSend = artifacts.require("./MultiSend");

let Web3latest = require("web3");
let web3latest = new Web3latest(new Web3latest.providers.HttpProvider("http://localhost:8545"));
let MinimumViableMultiSigContract = new web3latest.eth.Contract(MinimumViableMultiSig.abi);
let LibSignatureContract = new web3latest.eth.Contract(LibSignature.abi);
let MultiSendContract = new web3latest.eth.Contract(MultiSend.abi);

const sign = async (hash, address, web3) => {
    const sig = await web3.eth.sign(hash, address);
    const v = (parseInt(sig.substring(sig.length - 2)) + 27).toString(16);
    const rest = sig.substring(0, sig.length - 2);
    const addedSig = rest + v;
    return addedSig.substring(2);
};

contract("Gas tests for multisig and multisend", function(accounts) {
    it("MultiSig", async () => {
        // init
        const from = accounts[0];
        const multiSigSigners = accounts.sort((a, b) => a > b);
        const to = accounts[1];
        const sendValue = 2000000;

        const multiSig = await MinimumViableMultiSigContract.deploy({ data: MinimumViableMultiSig.bytecode }).send({
            from,
            gas: 1500000
        });

        // setup
        const setup = await multiSig.methods.setup(multiSigSigners).send({ from, gas: 6000000 });
        const deposit = await web3latest.eth.sendTransaction({ from, to: multiSig.options.address, value: 10000000 });

        // prepare tx
        const calculateHash = await multiSig.methods.getTransactionHash(to, sendValue, "0x", 0).call();
        let sig = "0x";
        for (let i = 0; i < multiSigSigners.length; i++) {
            sig += await sign(calculateHash, multiSigSigners[i], web3latest);
        }

        // exec tx
        const execTransactionResult = await multiSig.methods
            .execTransaction(to, sendValue, "0x", 0, sig)
            .send({ from, gas: 6000000 });
        console.log(`Exec transaction for ${multiSigSigners.length} person`, execTransactionResult.gasUsed);
    });

    it("MultiSend", async () => {
        // init
        const from = accounts[0];
        const multiSigSigners = accounts.sort((a, b) => a > b);
        const to = accounts[1];
        const sendValue = 2000000;

        // now multisend, deploy
        const multiSend = await MultiSendContract.deploy({ data: MultiSend.bytecode }).send({
            from,
            gas: 1500000
        });

        // multiSend - for n parties
        let multiSendParameters = "0x";
        for (let i = 0; i < multiSigSigners.length; i++) {
            multiSendParameters += web3.eth.abi
                .encodeParameters(["uint256", "address", "uint256", "bytes"], [1, multiSigSigners[i], sendValue, "0x"])
                .substring(2);
        }
        const multiSendResult = await multiSend.methods.multiSend(multiSendParameters).send({ from, gas: 6000000 });
        console.log(`Multi send for ${multiSigSigners.length} person`, multiSendResult.gasUsed);
    });

    it("MultiSig & MultiSend", async () => {
        // init
        const from = accounts[0];
        const multiSigSigners = accounts.splice(0).sort((a, b) => a > b);
        const to = accounts[1];
        const depositValue = 1000000;
        // send it all
        const sendValue = depositValue;

        // 69994 / 1
        // 90753 / 2
        // 111257 / 3
        // 131955 / 4
        // 152426 / 5
        // 172971 / 6
        // 193418 / 7
        // 213993 / 8
        // 234506 / 9
        // 255341 / 10

        // setup multisig
        const multiSig = await MinimumViableMultiSigContract.deploy({ data: MinimumViableMultiSig.bytecode }).send({
            from,
            gas: 1500000
        });

        // setup
        const setup = await multiSig.methods.setup(multiSigSigners).send({ from, gas: 6000000 });
        const deposit = await web3latest.eth.sendTransaction({ from, to: multiSig.options.address, value: 10000000 });

        // setup multisend
        // now multisend, deploy
        const multiSend = await MultiSendContract.deploy({ data: MultiSend.bytecode }).send({
            from,
            gas: 1500000
        });

        // create multisend data
        let multiSendParameters = "0x";
        for (let i = 0; i < multiSigSigners.length; i++) {
            // devide the send value between the receivers
            multiSendParameters += web3.eth.abi
                .encodeParameters(["uint256", "address", "uint256", "bytes"], [0, multiSigSigners[i], 10, "0x"])
                .substring(2);
        }

         // call the multisig
        // exec tx        
        const multiSendCall = web3latest.eth.abi.encodeFunctionCall(
            {
                name: "multiSend",
                type: "function",
                inputs: [{ type: "bytes", name: "transactions" }]
            },
            [multiSendParameters]
        );
        

        // create call data for multisig exec transaction
        const calculateHash = await multiSig.methods
            .getTransactionHash(multiSend.options.address, 0, multiSendCall, 1)
            .call();


        let sig = "0x";
        for (let i = 0; i < multiSigSigners.length; i++) {
            sig += await sign(calculateHash, multiSigSigners[i], web3latest);
        }

        const execTransactionResult = await multiSig.methods
            .execTransaction(multiSend.options.address, 0, multiSendCall, 1, sig)
            .send({ from, gas: 6000000 });
        console.log(`Exec multisig/multisend for ${multiSigSigners.length} person`, execTransactionResult.gasUsed);
    });
});
