import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MarketModule = buildModule("MarketCore", (m) => {
  const market = m.contract("MarketCore");
  return { market };
});

export default MarketModule;
