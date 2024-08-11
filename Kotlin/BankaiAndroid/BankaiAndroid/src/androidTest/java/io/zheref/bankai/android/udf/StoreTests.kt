package io.zheref.bankai.android.udf

import io.zheref.bankai.android.MainDispatcherRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

object testFeature {
    // Spies
    val calledReducerWithAction: MutableList<Action> = mutableListOf()

    val reducer: Reducer<State, Action> = { state, action ->
        // Spy sake
        calledReducerWithAction.add(action)

        when (action) {
            is Action.Dismiss -> resolve(state.copy(name = ""))
            else -> resolve()
        }
    }

    data class State(val name: String)

    val blankState get(): State = State(
        name = ""
    )

    sealed class Action {
        data object Dismiss: Action()
    }

    fun defaultStore(initialState: State): Store<State, Action> = Store<State, Action>(
        initialState = initialState,
        reducer = reducer
    )

    operator fun component1(): State = blankState
    operator fun component2() = this.reducer
}

class StoreTests {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun testSend_withActionAndNoEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = testFeature.defaultStore(
            initialState = testFeature.blankState.copy(
                name = initialName
            ),
        )

        // When
        val job = store.send(testFeature.Action.Dismiss)

        // Then
        job.join()

        val updatedState = store.currentState
        val lastHandledAction = testFeature.calledReducerWithAction.last()

        assertEquals(testFeature.Action.Dismiss, lastHandledAction)
        assertEquals("", updatedState.name)
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