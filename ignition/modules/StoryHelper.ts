import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StoryHelperModule = buildModule("StoryHelper", (m) => {
  const sh = m.contract("StoryHelper");
  return { sh };
});

export default StoryHelperModule;
