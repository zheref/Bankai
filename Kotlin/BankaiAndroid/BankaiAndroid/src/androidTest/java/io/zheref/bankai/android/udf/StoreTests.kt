package io.zheref.bankai.android.udf

import io.zheref.bankai.android.MainDispatcherRule
import io.zheref.bankai.android.udf.Store.Effect
import io.zheref.bankai.android.udf.TestFeature.State
import io.zheref.bankai.android.udf.TestFeature.Action
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

interface StoreFeature<State, Action> {
    val reducer: Reducer<State, Action>
    val defaultState: State
    fun defaultStore(initialState: State = defaultState): Store<State, Action>
}

object TestFeature: StoreFeature<State, Action> {
    // Spies
    val calledReducerWithAction: MutableList<Action> = mutableListOf()

    override val reducer: Reducer<State, Action> = { state, action ->
        // Spy sake
        calledReducerWithAction.add(action)

        when (action) {
            is Action.Dismiss -> resolve(state.copy(name = ""))
            is Action.ChangeName -> {
                val newState = state.copy(name = action.name)
                resolve(newState)
            }
            is Action.DeployName -> {
                val effect = Effect.future(
                    {
                        delay(1000)
                        return@future TestFeature.Action.ChangeName(action.name)
                    },
                    "deploy:${action.name}",
                )

                autoresolve.with(effect)
            }
            is Action.ListenForNames -> {
                val effect = Effect.flow(
                    flow {
                        var itemIndex = 0
                        while(itemIndex < 5) {
                            delay(1000)
                            itemIndex++
                            emit(Action.ChangeName("RemoteName-$itemIndex"))
                        }
                    },
                    "listenForNames"
                )

                autoresolve.with(effect)
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

                autoresolve.with(effect)
            }
        }
    }

    data class State(val name: String)

    override val defaultState get(): State = State(
        name = ""
    )

    sealed class Action {
        data object Dismiss: Action()
        data class ChangeName(val name: String) : Action()
        data class DeployName(val name: String) : Action()
        data object ListenForNames: Action()
        data object StepByStep: Action()
    }

    override fun defaultStore(initialState: State): Store<State, Action> = Store<State, Action>(
        initialState = initialState,
        reducer = reducer
    )

    operator fun component1(): State = defaultState
    operator fun component2() = this.reducer
}

class StoreTests {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun testSend_withActionAndNoEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = TestFeature.defaultStore(
            initialState = TestFeature.defaultState.copy(
                name = initialName
            ),
        )

        // When
        val job = store.send(Action.Dismiss)

        // Then
        job.join()

        val updatedState = store.currentState
        val lastHandledAction = TestFeature.calledReducerWithAction.last()

        assertEquals(Action.Dismiss, lastHandledAction)
        assertEquals("", updatedState.name)
    }

    @Test
    fun testSend_withParameteredActionAndNoEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = TestFeature.defaultStore(
            initialState = TestFeature.defaultState.copy(
                name = initialName
            ),
        )
        val newName = "NewName"

        // When
        val job = store.send(TestFeature.Action.ChangeName(newName))

        // Then
        job.join()

        val updatedState = store.currentState
        val lastHandledAction = TestFeature.calledReducerWithAction.last()

        assertEquals(lastHandledAction, TestFeature.Action.ChangeName(newName))
        assertEquals(updatedState.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndSuspendEffect() = runTest {
        // Given
        val initialName = "Initial"
        val store = TestFeature.defaultStore(
            initialState = TestFeature.defaultState.copy(
                name = initialName
            ),
        )
        val newName = "NewName"

        // When
        val job = store.send(TestFeature.Action.DeployName(newName))

        // Then
        job.join()
        val updatedState1 = store.state.value
        assertEquals(TestFeature.Action.DeployName(newName), TestFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.state.value
        assertEquals(TestFeature.Action.ChangeName(newName), TestFeature.calledReducerWithAction.last())
        assertEquals(updatedState2.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = TestFeature.defaultStore(
            initialState = TestFeature.defaultState.copy(
                name = initialName
            ),
        )

        // When
        val job = store.send(TestFeature.Action.ListenForNames)

        // Then
        job.join()
        val updatedState1 = store.currentState
        assertEquals(TestFeature.Action.ListenForNames, TestFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(TestFeature.Action.ChangeName("RemoteName-5"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-4"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-3"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-2"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-1"), TestFeature.calledReducerWithAction.removeLast())

    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteIrregularEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = TestFeature.defaultStore(
            initialState = TestFeature.defaultState.copy(
                name = initialName
            ),
        )

        // When
        var job = store.send(TestFeature.Action.StepByStep)
        job.join()

        // Then
        val updatedState1 = store.currentState
        assertEquals(TestFeature.Action.StepByStep, TestFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(TestFeature.Action.ChangeName("RemoteName-5"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-4"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-3"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-2"), TestFeature.calledReducerWithAction.removeLast())
        assertEquals(TestFeature.Action.ChangeName("RemoteName-1"), TestFeature.calledReducerWithAction.removeLast())
    }

}