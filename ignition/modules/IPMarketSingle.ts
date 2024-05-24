import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
const SH = "0x7cb1D6f46cb3E99D7BAf7bF9f7FA8Eb88313D8e2";
const PRICE = "0xFf4D96E62E14633C112913BA02E41e0EEB880c1C";

const SingleMarketModule = buildModule("DolphinIPMarket", (m) => {
  const market = m.contract("DolphinIPMarket", [SH, PRICE]);
  return { market };
});

export default SingleMarketModule;
