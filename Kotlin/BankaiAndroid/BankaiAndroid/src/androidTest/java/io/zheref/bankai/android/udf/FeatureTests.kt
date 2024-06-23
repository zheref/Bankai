package io.zheref.bankai.android.udf

import io.zheref.bankai.android.MainDispatcherRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test

class MyFeature(initialState: MyFeature.State): Feature<MyFeature.State, MyFeature.Action>(initialState) {
    // Spies
    val calledReducerWithAction: MutableList<Action> = mutableListOf()

    data class State(val name: String)

    sealed class Action {
        data object Dismiss: Action()
        data class ChangeName(val name: String) : Action()
        data class DeployName(val name: String) : Action()
    }

    override val reducer: Reducer<State, Action> = reducer@ { state, action ->
        // Spy sake
        calledReducerWithAction.add(action)

        // Actual reducer logic
        return@reducer when (action) {
            is Action.Dismiss -> {
                val newState = state.copy(name = "")
                Effect(newState, emptyList())
            }
            is Action.ChangeName -> {
                val newState = state.copy(name = action.name)
                Effect(newState, emptyList())
            }
            is Action.DeployName -> {
                val thunk = Thunk<Action>(
                    identifier = "deploy:${action.name}",
                    start = flow {
                        delay(1000)
                        emit(Action.ChangeName(action.name))
                    }
                )

                Effect(state, listOf(thunk))
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
        val lastHandledAction = feature.calledReducerWithAction.last()

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
        val lastHandledAction = feature.calledReducerWithAction.last()

        assertEquals(lastHandledAction, MyFeature.Action.ChangeName(newName))
        assertEquals(updatedState.name, newName)
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testSend_withActionAndEffects() = runTest {
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
        assertEquals(MyFeature.Action.DeployName(newName), feature.calledReducerWithAction.last())
        assertEquals(updatedState1.name, initialName)

        feature.runningJobs.values.joinAll()
        val updatedState2 = feature.state.value
        assertEquals(MyFeature.Action.ChangeName(newName), feature.calledReducerWithAction.last())
        assertEquals(updatedState2.name, newName)
    }

}