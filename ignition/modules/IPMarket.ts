import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
const SH = "0x7cb1D6f46cb3E99D7BAf7bF9f7FA8Eb88313D8e2";
const PRICE = "0x61DDfb3713638b56aF49AfdD9a5831b07c24B458";

const MarketModule = buildModule("IPMarket", (m) => {
  const market = m.contract("IPMarket", [SH, PRICE]);
  return { market };
});

export default MarketModule;
