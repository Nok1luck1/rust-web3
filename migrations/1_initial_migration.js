const bdrige = artifacts.require("Bridge.sol");

module.exports = async function (deployer) {
 await deployer.deploy(bdrige);
};
