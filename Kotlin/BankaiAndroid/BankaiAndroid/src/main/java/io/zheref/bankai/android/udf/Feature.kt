package io.zheref.bankai.android.udf

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map

typealias Reducer<State, Action> = (state: State, action: Action) -> Feature.Effect<State, Action>
data class Thunk<Action>(val identifier: String?, val start: Flow<Action>)


abstract class Feature<State, Action>(initialState: State) : ViewModel() {
    abstract val reducer: Reducer<State, Action>
    // We keep feature state private so that it can only be changed by reducer
    private val _state: MutableState<State> = mutableStateOf(initialState)
    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()

    /**
     * Asynchronously sends an action to the reducer in order to update the feature state and trigger any associated thunks.
     *
     * @param action The action to be sent to the reducer.
     */
    suspend fun send(action: Action) = coroutineScope {
        println("Received action: $action")
        val (state, thunks) = reducer(_state.value, action)
        _state.value = state

        println("Found ${thunks.size} thunks to start")
        thunks.forEach { start(it) }
    }

    /**
     * Inner class representing the store of a feature.
     */
    inner class Store() {
        var state by _state
            private set

        fun dispatch(action: Action): () -> Unit = {
            runBlocking { send(action) }
        }

        operator fun component1() = state
        operator fun component2() = this::dispatch
    }

    data class Effect<State, Action>(
        val state: State,
        val thunks: List<Thunk<Action>> = emptyList()
    )

    private suspend fun start(thunk: Thunk<Action>) {
        val (id, start) = thunk
        val identifier = id ?: String.random()

        println("Starting thunk with identifier: $identifier")
        val job = viewModelScope.launch {
            start
                .flowOn(Dispatchers.Default)
                .map {
                    println("Intercepted action: $it")
                    it
                }
                .catch { terminate(identifier) }
                .collect { send(it) }
        }

        _runningJobs[identifier] = job
    }

    /**
     * Terminate a thunk with the specified identifier.
     * @param identifier The identifier of the thunk to terminate.
     */
    private fun terminate(identifier: String) {
        println("Terminating thunk with identifier: $identifier")
        _runningJobs[identifier]?.cancel()
        _runningJobs.remove(identifier)
    }
}

private fun String.Companion.random(): String {
    return (0..10).map { ('a'..'z').random() }.joinToString("")
}
