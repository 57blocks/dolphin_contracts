import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DefaultPriceModule = buildModule("DefaultPriceModel", (m) => {
  const dp = m.contract("DefaultPriceModel");
  return { dp };
});

export default DefaultPriceModule;
