const { ethers } = require('hardhat');
const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

async function fixture() {
  const [pauser] = await ethers.getSigners();

  const mock = await ethers.deployContract('PausableMock');

  return { pauser, mock };
}

describe('Pausable', function () {
  let pauseDuration = 10;

  beforeEach(async function () {
    Object.assign(this, await loadFixture(fixture));
  });

  describe('when unpaused', function () {
    beforeEach(async function () {
      expect(await this.mock.paused()).to.be.false;
    });

    it('can perform normal process in non-pause', async function () {
      expect(await this.mock.count()).to.equal(0n);

      await this.mock.normalProcess();
      expect(await this.mock.count()).to.equal(1n);
    });

    it('cannot take drastic measure in non-pause', async function () {
      await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');

      expect(await this.mock.drasticMeasureTaken()).to.be.false;
    });

    describe('when paused', function () {
      beforeEach(async function () {
        this.tx = await this.mock.pause();
      });

      it('emits a Paused event', async function () {
        await expect(this.tx).to.emit(this.mock, 'Paused').withArgs(this.pauser);
      });

      it('does not set pause deadline duration', async function () {
        expect(await this.mock.getPausedForDeadline()).to.equal(0);
      });

      it('cannot perform normal process in pause', async function () {
        await expect(this.mock.normalProcess()).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
      });

      it('can take a drastic measure in a pause', async function () {
        await this.mock.drasticMeasure();
        expect(await this.mock.drasticMeasureTaken()).to.be.true;
      });

      it('reverts when re-pausing with pause', async function () {
        await expect(this.mock.pause()).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
      });

      it('reverts when re-pausing with pauseFor', async function () {
        await expect(this.mock.pauseFor(pauseDuration)).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
      });

      describe('unpausing with unpause', function () {
        it('is unpausable by the pauser', async function () {
          await this.mock.unpause();
          expect(await this.mock.paused()).to.be.false;
        });

        describe('when unpaused', function () {
          beforeEach(async function () {
            this.tx = await this.mock.unpause();
          });

          it('emits an Unpaused event', async function () {
            await expect(this.tx).to.emit(this.mock, 'Unpaused').withArgs(this.pauser);
          });

          it('does not set pause deadline duration', async function () {
            expect(await this.mock.getPausedForDeadline()).to.equal(0);
          });

          it('should resume allowing normal process', async function () {
            expect(await this.mock.count()).to.equal(0n);
            await this.mock.normalProcess();
            expect(await this.mock.count()).to.equal(1n);
          });

          it('should prevent drastic measure', async function () {
            await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpause', async function () {
            await expect(this.mock.unpause()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpauseAfterPausedFor', async function () {
            await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });
        });

        describe('unpausing with unpausingAfterPausedFor', function () {
          beforeEach(async function () {
            this.tx = await this.mock.unpauseAfterPausedFor();
          });

          it('emits an Unpaused event', async function () {
            await expect(this.tx).to.emit(this.mock, 'Unpaused').withArgs(this.pauser);
          });

          it('does not set pause deadline duration', async function () {
            expect(await this.mock.getPausedForDeadline()).to.equal(0);
          });

          it('should resume allowing normal process', async function () {
            expect(await this.mock.count()).to.equal(0n);
            await this.mock.normalProcess();
            expect(await this.mock.count()).to.equal(1n);
          });

          it('should prevent drastic measure', async function () {
            await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpause', async function () {
            await expect(this.mock.unpause()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpauseAfterPausedFor', async function () {
            await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });
        });
      });
    });

    describe('when pausedFor', function () {
      beforeEach(async function () {
        this.tx = await this.mock.pauseFor(pauseDuration);
      });

      it('emits a PausedFor event', async function () {
        await expect(this.tx).to.emit(this.mock, 'PausedFor').withArgs(this.pauser, pauseDuration);
      });

      it('sets pause deadline duration and is equal to desired duration', async function () {
        const [unpauseDeadline, executionTimestamp] = await this.mock.getPausedForDeadlineAndTimestamp();
        expect(unpauseDeadline).to.not.equal(0);
        const expectedUnpauseDeadline = parseInt(executionTimestamp) + pauseDuration;
        expect(unpauseDeadline).to.equal(expectedUnpauseDeadline);
      });

      it('cannot perform normal process in pause', async function () {
        await expect(this.mock.normalProcess()).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
      });

      it('can take a drastic measure in a pause', async function () {
        await this.mock.drasticMeasure();
        expect(await this.mock.drasticMeasureTaken()).to.be.true;
      });

      it('reverts when re-pausing with pause', async function () {
        await expect(this.mock.pause()).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
      });

      it('reverts when re-pausing with pauseFor', async function () {
        await expect(this.mock.pauseFor(pauseDuration)).to.be.revertedWithCustomError(this.mock, 'EnforcedPause');
        // checking for pausing 0 seconds too
        await expect(this.mock.pauseFor(pauseDuration - pauseDuration)).to.be.revertedWithCustomError(this.mock,'EnforcedPause',);
      });

      describe('unpausing with unpause', function () {
        it('is unpausable by the pauser', async function () {
          await this.mock.unpause();
          expect(await this.mock.paused()).to.be.false;
        });

        describe('when unpaused before duration elapsed', function () {
          beforeEach(async function () {
            this.tx = await this.mock.unpause();
          });

          it('emits an Unpaused event', async function () {
            await expect(this.tx).to.emit(this.mock, 'Unpaused').withArgs(this.pauser);
          });

          it('does not set pause deadline duration', async function () {
            expect(await this.mock.getPausedForDeadline()).to.equal(0);
          });

          it('should resume allowing normal process', async function () {
            expect(await this.mock.count()).to.equal(0n);
            await this.mock.normalProcess();
            expect(await this.mock.count()).to.equal(1n);
          });

          it('should prevent drastic measure', async function () {
            await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpause', async function () {
            await expect(this.mock.unpause()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpauseAfterPausedFor', async function () {
            await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });
        });

        describe('when unpaused after duration elapsed', function () {
          beforeEach(async function () {
            await network.provider.send('evm_increaseTime', [pauseDuration]);
            await network.provider.send('evm_mine');
            this.tx = await this.mock.unpause();
          });

          it('emits an Unpaused event', async function () {
            await expect(this.tx).to.emit(this.mock, 'Unpaused').withArgs(this.pauser);
          });

          it('does not set pause deadline duration', async function () {
            expect(await this.mock.getPausedForDeadline()).to.equal(0);
          });

          it('should resume allowing normal process', async function () {
            expect(await this.mock.count()).to.equal(0n);
            await this.mock.normalProcess();
            expect(await this.mock.count()).to.equal(1n);
          });

          it('should prevent drastic measure', async function () {
            await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpause', async function () {
            await expect(this.mock.unpause()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpauseAfterPausedFor', async function () {
            await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });
        });
      });

      describe('unpausing with unpausingAfterPausedFor', function () {
        it('is unpauseAfterPausedFor by the pauser ifpauseDuration elapsed', async function () {
          await network.provider.send('evm_increaseTime', [pauseDuration]);
          await network.provider.send('evm_mine');
          await this.mock.unpauseAfterPausedFor();
          expect(await this.mock.paused()).to.be.false;
        });

        it('is not unpauseAfterPausedFor by the pauser ifpauseDuration did not elapse', async function () {
          await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(
            this.mock,
            'PauseDurationNotElapsed',
          );
          expect(await this.mock.paused()).to.be.true;
        });

        describe('when unpausingAfterPausedFor', function () {
          beforeEach(async function () {
            await network.provider.send('evm_increaseTime', [pauseDuration]);
            await network.provider.send('evm_mine');
            this.tx = await this.mock.unpauseAfterPausedFor();
          });

          it('emits an Unpaused event', async function () {
            await expect(this.tx).to.emit(this.mock, 'Unpaused').withArgs(this.pauser);
          });

          it('should resume allowing normal process', async function () {
            expect(await this.mock.count()).to.equal(0n);
            await this.mock.normalProcess();
            expect(await this.mock.count()).to.equal(1n);
          });

          it('should prevent drastic measure', async function () {
            await expect(this.mock.drasticMeasure()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpause', async function () {
            await expect(this.mock.unpause()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });

          it('reverts when re-unpausing with unpauseAfterPausedFor', async function () {
            await expect(this.mock.unpauseAfterPausedFor()).to.be.revertedWithCustomError(this.mock, 'ExpectedPause');
          });
        });
      });
    });
  });
});
