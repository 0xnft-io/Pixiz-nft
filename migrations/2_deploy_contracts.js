const Pixiz = artifacts.require("./Pixiz.sol");

module.exports = async (deployer, network, addresses) => {
  // OpenSea proxy registry addresses for rinkeby and mainnet.
  let proxyRegistryAddress = "";
  if (network === 'mainnet') {
    proxyRegistryAddress = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
  } else {
    proxyRegistryAddress = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
  }

  const baseURI = 'https://pixiz.xzy/api/';
  await deployer.deploy(Pixiz, baseURI, proxyRegistryAddress, {gas: 6700000});
};
