import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const RNFTModule = buildModule("RemixingNFT", (m) => {
  const nft = m.contract("RemixingNFT");
  return { nft };
});

export default RNFTModule;
