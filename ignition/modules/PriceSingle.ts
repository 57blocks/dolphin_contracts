import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SinglePriceModule = buildModule("PriceModelSingle", (m) => {
  const dp = m.contract("PriceModelSingle");
  return { dp };
});

export default SinglePriceModule;
