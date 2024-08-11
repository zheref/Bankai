package io.zheref.bankai.android.udf

import io.zheref.bankai.android.MainDispatcherRule
import io.zheref.bankai.android.udf.Store.Effect
import io.zheref.bankai.android.udf.MyFeature.Action
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flow
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
            is Action.ChangeName -> {
                val newState = state.copy(name = action.name)
                resolve(newState)
            }
            is Action.DeployName -> {
                val effect = Effect.future(
                    {
                        delay(1000)
                        return@future testFeature.Action.ChangeName(action.name)
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
                            emit(testFeature.Action.ChangeName("RemoteName-$itemIndex"))
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
                        send(testFeature.Action.ChangeName("RemoteName-$itemIndex"))
                    }
                }, "listenForNamesStepByStep")

                autoresolve.with(effect)
            }
        }
    }

    data class State(val name: String)

    val blankState get(): State = State(
        name = ""
    )

    sealed class Action {
        data object Dismiss: Action()
        data class ChangeName(val name: String) : Action()
        data class DeployName(val name: String) : Action()
        data object ListenForNames: Action()
        data object StepByStep: Action()
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
        val store = testFeature.defaultStore(
            initialState = testFeature.blankState.copy(
                name = initialName
            ),
        )
        val newName = "NewName"

        // When
        val job = store.send(testFeature.Action.ChangeName(newName))

        // Then
        job.join()

        val updatedState = store.currentState
        val lastHandledAction = testFeature.calledReducerWithAction.last()

        assertEquals(lastHandledAction, testFeature.Action.ChangeName(newName))
        assertEquals(updatedState.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndSuspendEffect() = runTest {
        // Given
        val initialName = "Initial"
        val store = testFeature.defaultStore(
            initialState = testFeature.blankState.copy(
                name = initialName
            ),
        )
        val newName = "NewName"

        // When
        val job = store.send(testFeature.Action.DeployName(newName))

        // Then
        job.join()
        val updatedState1 = store.state.value
        assertEquals(testFeature.Action.DeployName(newName), testFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.state.value
        assertEquals(testFeature.Action.ChangeName(newName), testFeature.calledReducerWithAction.last())
        assertEquals(updatedState2.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = testFeature.defaultStore(
            initialState = testFeature.blankState.copy(
                name = initialName
            ),
        )

        // When
        val job = store.send(testFeature.Action.ListenForNames)

        // Then
        job.join()
        val updatedState1 = store.currentState
        assertEquals(testFeature.Action.ListenForNames, testFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(testFeature.Action.ChangeName("RemoteName-5"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-4"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-3"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-2"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-1"), testFeature.calledReducerWithAction.removeLast())

    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndIndefiniteIrregularEffects() = runTest {
        // Given
        val initialName = "Initial"
        val store = testFeature.defaultStore(
            initialState = testFeature.blankState.copy(
                name = initialName
            ),
        )

        // When
        var job = store.send(testFeature.Action.StepByStep)
        job.join()

        // Then
        val updatedState1 = store.currentState
        assertEquals(testFeature.Action.StepByStep, testFeature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        store.waitForJobsToComplete()
        val updatedState2 = store.currentState
        assertEquals(updatedState2.name, "RemoteName-5")
        assertEquals(testFeature.Action.ChangeName("RemoteName-5"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-4"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-3"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-2"), testFeature.calledReducerWithAction.removeLast())
        assertEquals(testFeature.Action.ChangeName("RemoteName-1"), testFeature.calledReducerWithAction.removeLast())
    }

}