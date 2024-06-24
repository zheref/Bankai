package io.zheref.bankai.android.udf

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

typealias Reducer<State, Action> = (state: State, action: Action) -> Feature.Reduction<State, Action>
typealias Sender<Action> = suspend (action: Action) -> Job
typealias IntentHandler = () -> Unit
typealias Thunk<Action> = suspend (send: Sender<Action>) -> Unit

abstract class Feature<State, Action>(initialState: State) : ViewModel() {
    abstract val reducer: Reducer<State, Action>
    // We keep feature state private so that it can only be changed by reducer
    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()

    val runningJobs: Map<String, Job> = _runningJobs

    /**
     * The current state of the feature.
     */
    var state = mutableStateOf(initialState)
        private set
    private var _state: State by state

    /**
     * Asynchronously sends an action to the reducer in order to update the feature state and trigger any associated side effects.
     *
     * @param action The action to be sent to the reducer.
     */
    suspend fun send(action: Action): Job {
        println("Received action: $action")
        val (state, effects) = reducer(_state, action)

        val mutationJob = viewModelScope.launch {
            this@Feature._state = state
        }

        println("Found ${effects.size} effects to start")
        effects.forEach { start(it) }
        return mutationJob
    }

    /**
     * Inner class representing the store of a feature.
     */
    inner class Store() {
        var state = this@Feature.state

        fun dispatch(action: Action): IntentHandler = {
            runBlocking { send(action) }
        }

        operator fun component1() = state
        operator fun component2() = this::dispatch
    }

    data class Reduction<State, Action>(
        val state: State,
        val effects: List<Effect<Action>> = emptyList()
    )

    data class Effect<out Action>(
        val identifier: String = String.random(),
        val start: Thunk<Action>
    ) {
        companion object {
            fun <Action> fromFlow(identifier: String, flow: Flow<Action>): Effect<Action> {
                return Effect(identifier = identifier, start = { send ->
                    flow
                        .flowOn(Dispatchers.Default)
                        .map {
                            println("Intercepted action: $it")
                            it
                        }
                        // TODO: Handle exceptions
                        // .catch { send(it) }
                        .collect { send(it) }
                })
            }

            fun <Action> fromSuspend(suspend: suspend () -> Action, identifier: String): Effect<Action> {
                return Effect(identifier = identifier, start = { send ->
                    coroutineScope {
                        val futureAction = async { suspend() }
                        send(futureAction.await())
                    }
                })
            }

            fun <Action> fireAndForget(fire: () -> Unit): Effect<Action> {
                return Effect(start = {
                    runBlocking {
                        launch { fire() }
                    }
                })
            }
        }
    }

    /**
     * Starts an effect by executing the provided [effect]. The thunk is executed asynchronously and any actions emitted
     * by the [thunk.start] flow are sent to the reducer and processed.
     *
     * If [thunk.identifier] is null, a random identifier is generated for the thunk.
     *
     * @param thunk The thunk to be started.
     */
    private suspend fun start(effect: Effect<Action>) {
        val identifier = effect.identifier ?: String.random()

        println("Starting thunk with identifier: $identifier")
        val job = viewModelScope.launch {
            effect.start(this@Feature::send)
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
