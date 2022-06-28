const { accounts, contract } = require('@openzeppelin/test-environment');
const { BN, time } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const AccessController = contract.fromArtifact('AccessController');

const [owner, whale, idoParticipant, referralParticipant, anotherAccount] = accounts;

describe('AccessController', async () => {

  let accessController;
  let stages;
  let accounts = [
    { address: whale, level: 3 },
    { address: idoParticipant, level: 2 },
    { address: referralParticipant, level: 1 },
  ]

  beforeEach(async () => {
    accessController = await AccessController.new({ from: owner });
    const start1 = (await time.latest()).add(time.duration.days(1));
    const end1 = start1.add(time.duration.hours(3));
    const start2 = end1;
    const end2 = start2.add(time.duration.hours(6));
    const start3 = end2;
    const end3 = start3.add(time.duration.hours(6));
    const start4 = end3;
    const end4 = start4.add(time.duration.hours(6));
    stages = [
      { start: start1, end: end1, level: 3 },
      { start: start2, end: end2, level: 2 },
      { start: start3, end: end3, level: 1 },
      { start: start4, end: end4, level: 0 },
    ]
  });

  describe('hasAccess', () => {
    beforeEach(async () => {
      for (const {start, end, level} of stages) {
        await accessController.setAccessLevel(level, start, end, { from: owner });
      }
      await accessController.setAccountLevels(accounts.map(a => a.address), accounts.map(a => a.level), { from: owner });
    });

    it('should return false for any account when there is no active stage', async () => {
      let result = await Promise.all(accounts.map(a => accessController.hasAccess(a.address)));
      expect(result.reduce((a, b) => a || b)).to.be.equal(false);
      await time.increaseTo(stages[3].end.add(new BN('1')));
      result = await Promise.all(accounts.map(a => accessController.hasAccess(a.address)));
      expect(result.reduce((a, b) => a || b)).to.be.equal(false);
    });

    it('should return result according to stage and account access level', async () => {
      const addresses = [...accounts.map(a => a.address), anotherAccount]
      for ({ start, end, level } of stages) {
        await time.increaseTo(start);
        const [ level3, level2, level1, level0 ] = await Promise.all(addresses.map(a => accessController.hasAccess(a)));
        if (level < 4) expect(level3).to.be.equal(true);
        if (level < 3) expect(level2).to.be.equal(true);
        if (level < 2) expect(level1).to.be.equal(true);
        if (level < 1) expect(level0).to.be.equal(true)
        if (level > 0) expect(level0).to.be.equal(false);
        if (level > 1) expect(level1).to.be.equal(false);
        if (level > 2) expect(level2).to.be.equal(false);
        if (level > 3) expect(level3).to.be.equal(false);
      }
    });
  });

});
