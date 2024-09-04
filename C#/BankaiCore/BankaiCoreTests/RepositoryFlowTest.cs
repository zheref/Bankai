using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using BankaiCore.Common;
using BankaiCore.Repository;
using Microsoft.Reactive.Testing;

namespace BankaiCoreTests
{
    [TestClass]
    public class RepositoryFlowTests
    {
        [TestMethod]
        public async Task testLocalOnlyRepositoryFlow()
        {
            var testScheduler = new TestScheduler();

            var lastNumber = 0;
            var remoteReceived = String.Empty;
            var hasCompleted = false;

            // Given
            var sut = new RepositoryFlow<int>(
                async receiver =>
                {
                    await Task.Delay(1);
                    receiver.sendLocal(1);
                },
                onlyLocalExpected: true,
                scheduler: testScheduler
            );

            // When
            sut
                .onLocal(data => lastNumber = data)
                .onRemote((data, label) =>
                {
                    lastNumber = data;
                    remoteReceived = label;
                })
                .onCompletion(() => hasCompleted = true);

            var cancellable = sut.run();
            testScheduler.AdvanceBy(1.Seconds().Ticks);
            await Task.Delay(1.Seconds());

            // Then
            Assert.IsTrue(sut.hasCompleted);
            Assert.IsTrue(hasCompleted);
            Assert.AreEqual(1, lastNumber);
            Assert.AreEqual(String.Empty, remoteReceived);

            cancellable.Dispose();
        }

        [TestMethod]
        public async Task testRegularRepositoryFlow()
        {
            var testScheduler = new TestScheduler();

            var lastNumber = 0;
            var remoteReceived = String.Empty;
            var hasCompleted = false;

            // Given
            var sut = new RepositoryFlow<int>(
                async receiver =>
                {
                    await Task.Delay(500);
                    receiver.sendLocal(1);

                    await Task.Delay(500);
                    receiver.sendRemote(2, remoteName: "api");
                },
                onlyLocalExpected: false,
                scheduler: testScheduler
            );

            // When
            sut
                .onLocal(data => lastNumber = data)
                .onRemote((data, label) =>
                {
                    lastNumber = data;
                    remoteReceived = label;
                })
                .onCompletion(() => hasCompleted = true);

            var cancellable = sut.run();
            testScheduler.AdvanceBy(2.Seconds().Ticks);
            await Task.Delay(2.Seconds());

            // Then
            Assert.AreEqual(2, lastNumber);
            Assert.AreEqual("api", remoteReceived);
            Assert.IsTrue(sut.hasCompleted);
            Assert.IsTrue(hasCompleted);

            cancellable.Dispose();
        }
    }
}
