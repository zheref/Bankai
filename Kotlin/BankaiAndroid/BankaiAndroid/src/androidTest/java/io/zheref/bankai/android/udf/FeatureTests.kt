package io.zheref.bankai.android.udf

import io.zheref.bankai.android.MainDispatcherRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class MyFeature(initialState: MyFeature.State): FeatureModel<MyFeature.State, MyFeature.Action>(initialState) {
    // Spies
    val calledFolderWithAction: MutableList<Action> = mutableListOf()

    data class State(val name: String)

    sealed class Action {
        data object Dismiss: Action()
        data class ChangeName(val name: String) : Action()
        data class DeployName(val name: String) : Action()
        data object ListenForNames: Action()
        data object StepByStep: Action()
    }

    override val folder: Folder<State, Action> = folder@ { state, action ->
        // Spy sake
        calledFolderWithAction.add(action)

        // Actual reducer logic
        return@folder when (action) {
            is Action.Dismiss -> {
                val newState = state.copy(name = "")
                resolve(newState)
            }
            is Action.ChangeName -> {
                val newState = state.copy(name = action.name)
                resolve(newState)
            }
            is Action.DeployName -> {
                val effect = Effect.fromSuspend(
                    {
                        delay(1000)
                        return@fromSuspend Action.ChangeName(action.name)
                    },
                    "deploy:${action.name}",
                )

                resolve().with(effect)
            }
            is Action.ListenForNames -> {
                val effect = Effect.fromFlow(
                    "listenForNames",
                    flow {
                        var itemIndex = 0
                        while(itemIndex < 5) {
                            delay(1000)
                            itemIndex++
                            emit(Action.ChangeName("RemoteName-$itemIndex"))
                        }
                    }
                )

                resolve().with(effect)
            }
            is Action.StepByStep -> {
                val effect = Effect.run({ send ->
                    var itemIndex = 0
                    while(itemIndex < 5) {
                        delay(1000)
                        itemIndex++
                        send(Action.ChangeName("RemoteName-$itemIndex"))
                    }
                }, "listenForNamesStepByStep")

                resolve().with(effect)
            }
        }
    }
}

class FeatureTests {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun testSend_withActionAndNoEffects() = runTest {
        // Given
        val initialName = "Initial"
        val feature = MyFeature(
            MyFeature.State(initialName)
        )

        // When
        val job = feature.send(MyFeature.Action.Dismiss)

        // Then
        job.join()

        val updatedState = feature.state.value
        val lastHandledAction = feature.calledFolderWithAction.last()

        assertEquals(lastHandledAction, MyFeature.Action.Dismiss)
        assertEquals(updatedState.name, "")
    }

    @Test
    fun testSend_withParameteredActionAndNoEffects() = runTest {
        // Given
        val initialName = "Initial"
        val feature = MyFeature(
            MyFeature.State(initialName)
        )
        val newName = "NewName"

        // When
        val job = feature.send(MyFeature.Action.ChangeName(newName))

        // Then
        job.join()

        val updatedState = feature.state.value
        val lastHandledAction = feature.calledFolderWithAction.last()

        assertEquals(lastHandledAction, MyFeature.Action.ChangeName(newName))
        assertEquals(updatedState.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndSuspendEffect() = runTest {
        // Given
        val initialName = "Initial"
        val feature = MyFeature(
            MyFeature.State(initialName)
        )
        val newName = "NewName"

        // When
        val job = feature.send(MyFeature.Action.DeployName(newName))

        // Then
        job.join()
        val updatedState1 = feature.state.value
        assertEquals(MyFeature.Action.DeployName(newName), feature.calledFolderWithAction.last())
        assertEquals(updatedState1.name, initialName)

        feature.waitForJobsToComplete()
        val updatedState2 = feature.state.value
        assertEquals(MyFeature.Action.ChangeName(newName), feature.calledFolderWithAction.last())
        assertEquals(updatedState2.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteEffects() = runTest {
        // Given
        val initialName = "Initial"
        val feature = MyFeature(
            MyFeature.State(initialName)
        )

        // When
        val job = feature.send(MyFeature.Action.ListenForNames)

        // Then
        job.join()
        val updatedState1 = feature.currentState
        assertEquals(MyFeature.Action.ListenForNames, feature.calledFolderWithAction.last())
        assertEquals(updatedState1.name, initialName)

        feature.waitForJobsToComplete()
        val updatedState2 = feature.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(MyFeature.Action.ChangeName("RemoteName-5"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-4"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-3"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-2"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-1"), feature.calledFolderWithAction.removeLast())

    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteIrregularEffects() = runTest {
        // Given
        val initialName = "Initial"
        val feature = MyFeature(
            MyFeature.State(initialName)
        )

        // When
        var job = feature.send(MyFeature.Action.StepByStep)
        job.join()

        // Then
        val updatedState1 = feature.currentState
        assertEquals(MyFeature.Action.StepByStep, feature.calledFolderWithAction.last())
        assertEquals(updatedState1.name, initialName)

        feature.waitForJobsToComplete()
        val updatedState2 = feature.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(MyFeature.Action.ChangeName("RemoteName-5"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-4"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-3"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-2"), feature.calledFolderWithAction.removeLast())
        assertEquals(MyFeature.Action.ChangeName("RemoteName-1"), feature.calledFolderWithAction.removeLast())
    }

}