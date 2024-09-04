using System.Reactive.Concurrency;
using BankaiCore;
using BankaiCore.Common;
using BankaiCore.Repository;
using Microsoft.Reactive.Testing;

namespace BankaiCoreTests
{
    [TestClass]
    public class UnitTest1
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
                operation: async receiver =>
                {
                    await Task.Delay(1);
                    receiver.sendLocal(1);
                },
                onlyLocalExpected: true, 
                scheduler: testScheduler
            );

            // When
            sut
                .onLocal(data =>
                {
                    lastNumber = data;
                })
                .onRemote((data, label) =>
                {
                    lastNumber = data;
                    remoteReceived = label;
                })
                .onCompletion(() =>
                {
                    hasCompleted = true;
                });

            var cancellable = sut.cancellable;
            testScheduler.AdvanceBy(1.Seconds().Ticks);
            await Task.Delay(1.Seconds());

            // Then
            Assert.IsTrue(sut.hasCompleted);
            Assert.IsTrue(hasCompleted);
            Assert.AreEqual(1, lastNumber);
            Assert.AreEqual(String.Empty, remoteReceived);

            cancellable.Dispose();
        }
    }
}