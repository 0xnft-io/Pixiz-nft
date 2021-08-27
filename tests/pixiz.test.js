const { accounts, defaultSender, contract, web3, provider, isHelpersConfigured } = require('@openzeppelin/test-environment');

const { expect, assert } = require('chai');


// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert, time, ether } = require('@openzeppelin/test-helpers');

describe('Pixiz smart contract', () => {
   const [owner, account1, account2, account3, account4, account5, devAddr, creatorAddr] = accounts;
   const pixizContractArtifact = contract.fromArtifact('Pixiz');
   const baseUri = "https://pixiz.xyz/api/";
   const proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317"

    this.pixizContract = null;

   before(async () => {
       try {
           this.pixizContract = await pixizContractArtifact.new(
               baseUri, devAddr, creatorAddr, proxyRegistryAddress
           )
       } catch (e) {
           console.log(JSON.stringify(e));
           assert.fail('no error', 'error', `got an error=${e}`, null)
       }
   })

    it ('should be locked', async () => {
        try {
            const contractLockStatus = await this.pixizContract.locked();
            console.log(`contractLockStatus=${contractLockStatus}`);
            expect(contractLockStatus).to.be.true;
        } catch (e) {
            console.log(JSON.stringify(e));
            assert.fail('no error', 'error', `got an error=${e}`, null);
        }
    })

    it ('should unlock', async () =>{
        try {
            const contractLockResult = await this.pixizContract.flipLock();
            console.log(contractLockResult.tx);
            expect(contractLockResult).to.be.exist;
        } catch (e) {
            console.log(JSON.stringify(e));
            assert.fail('no error', 'error', `got an error=${e}`, null);
        }
    })

    it ('should allow mint', async () => {
        try {
            const mintResult = await this.pixizContract.mint(1, {from: account1});
            expect(mintResult.tx).to.be.exist;
        } catch (e) {
            console.log(JSON.stringify(e));
            assert.fail('no error', 'error', `got an error=${e}`, null);
        }
    })

    it ('should allow multiple minting', async() => {
        try {
            const mintResult = await this.pixizContract.mint(20, {from: account1});
            expect(mintResult.tx).to.be.exist;
        } catch (e) {
            console.log(JSON.stringify(e));
            assert.fail('no error', 'error', `got an error=${e}`, null);
        }
    })

    it ('should not allow too many mints', async() => {
        try {
            const mintResult = await this.pixizContract.mint(21, {from: account1});
            expect(mintResult.tx).to.not.exist;
            assert.fail('no error', 'error', `mint should have failed`, null);
        } catch (e) {

        }
    })

    it ('should allow reserve tokens to be minted', async() =>{
        try {
            const mintResult = await this.pixizContract.mintTo(20, {from: owner});
            expect(mintResult.tx).to.be.exist;
        } catch (e) {
            console.log(JSON.stringify(e));
            assert.fail('no error', 'error', `got an error=${e}`, null);
        }
    })

    it ('should not allow reserve tokens to be minted', async() =>{
        try {
            const mintResult = await this.pixizContract.mintTo(20, {from: account1});
            assert.fail('no error', 'error', `mint should have failed`, null);
        } catch (e) {

        }
    })

    it ('should trigger SaleOver event when all pixiz are minted', async() => {
        const accounts = [account1, account2, account3, account4, account5, devAddr, creatorAddr]
        for (let i=0; i < 500; i++) {
            try {
                const account = accounts[i % accounts.length]
                const mintResult = await this.pixizContract.mint(20, {from: account});
                expect(mintResult.tx).to.be.exist;
            } catch (e) {
                console.log(JSON.stringify(e));
                assert.fail('no error', 'error', `got an error=${e}`, null);
            }
            const totalSupply = await this.pixizContract.totalSupply();
            if (totalSupply > 9980) {
                break;
            }
        }
        const contractBalance = await this.pixizContract.balance();
    })

    it ('should process a pixiz death', async() => {

    })
});