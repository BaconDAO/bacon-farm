const { expect } = require('chai');

const {
  takeSnapshot,
  revertToSnapshot,
  setNextBlockTimestamp,
} = require('./utils/utils.js');
const { BigNumber } = ethers;

describe('Staking contract', function () {

  // reward period duration is 14 days = 1210000 seconds
  // reward amount divided by duration in seconds equals rewardRate
  // This should give us a reward rate of 1000 tokens per second
  const SECONDS_IN_DURATION = BigNumber.from(1210000)
  const ONE_THOUSAND_PER_SECOND = SECONDS_IN_DURATION.mul(1000);

  beforeEach(async function () {
    [signer1, signer2, signer3] = await ethers.getSigners();

    snapshotId = await takeSnapshot();

    const { memberToken, memberNFT, staking } = await deploy();

    // set signer1 as the rewardDistributionManager, who can add additional rewards
    await staking.setRewardDistribution(signer1.address);

    await expect(memberToken.approve(staking.address, ONE_THOUSAND_PER_SECOND))
      .to.emit(memberToken, 'Approval')
      .withArgs(signer1.address, staking.address, ONE_THOUSAND_PER_SECOND);
  });

  afterEach(async () => {
    await revertToSnapshot(snapshotId);
  });

  describe('setMemberNFT()', async function () {
    it(`can set MemberNFT contract address`, async function () {
      await staking.setMemberNFT(memberNFT.address);
      expect(await staking.memberNFT()).to.equal(memberNFT.address);
    });
  });

  describe('notifyRewardAmount()', async function () {
    it(`can start first reward`, async function () {
      expect(await memberToken.transfer(staking.address, ONE_THOUSAND_PER_SECOND));
      expect(await staking.notifyRewardAmount(ONE_THOUSAND_PER_SECOND));
      expect(await staking.rewardRate()).to.equal(1000);
    });
  });

  // tested upto here
});
