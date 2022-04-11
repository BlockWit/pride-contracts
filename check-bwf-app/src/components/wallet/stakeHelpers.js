import { BigNumber } from 'ethers';

export const stakePrograms = [
  {
    active: true,
    periodInDaysBN: 40,
    apyBN: 5,
    finesPeriodsCountBN: 1,
    fineDaysBSs: [40],
    finesBSs: [100]
  },
  {
    active: true,
    periodInDaysBN: 180,
    apyBN: 6,
    finesPeriodsCountBN: 3,
    fineDaysBSs: [30, 60, 90],
    finesBSs: [70, 25, 20]
  },
  {
    active: true,
    periodInDaysBN: 360,
    apyBN: 8,
    finesPeriodsCountBN: 3,
    fineDaysBSs: [60, 120, 180],
    finesBSs: [70, 25, 20]
  }
];

export const calculateDepositWithFineOrReward = (amount, stakeProgramIndex, start) => {
  const stakeProgram = stakePrograms[stakeProgramIndex];
  const now = Math.floor(Date.now() / 1000);
  if (now > start + stakeProgram.periodInDaysBN * 86400) {
    // TODO: Wrong calculation
    return amount.mul(BigNumber.from(100 + stakeProgram.apyBN)).div(BigNumber.from(100));
  }

  let takeFinePeriodIndex = stakeProgram.finesBSs.length - 1;
  for (let i = stakeProgram.fineDaysBSs.length - 1; i >= 0; i--) {
    if (now < start + stakeProgram.fineDaysBSs[i] * 86400) {
      takeFinePeriodIndex = i;
    }
  }

  return amount.mul(BigNumber.from(100 - stakeProgram.finesBSs[takeFinePeriodIndex])).div(BigNumber.from(100));
};
