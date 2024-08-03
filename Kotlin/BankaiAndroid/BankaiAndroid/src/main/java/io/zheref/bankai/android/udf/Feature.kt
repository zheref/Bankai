package io.zheref.bankai.android.udf

import androidx.compose.runtime.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

public abstract class Result<T, E: Exception> {}
public data class SuccessResult<T, E: Exception>(val value: T): Result<T, E>()
public data class FailureResult<T, E: Exception>(val exception: E): Result<T, E>()

// Void to void ONCE
public typealias ZBlock = (Exception?) -> Unit
public typealias ZJob = suspend () -> Unit

// Void to 1 value
public typealias ZFuture<T> = suspend () -> T

// Void to 1..* values
public typealias ZYielderOf<T, E> = ((Result<T, E>) -> Void) -> Void

// Void to * values
public typealias ZFlowOf<T> = Flow<T>

// TODO: Remove Zs
typealias Reducer<State, Action> = (state: State, action: Action) -> Feature.Reduction<State, Action>
typealias Sender<Action> = suspend (action: Action) -> Job
typealias Thunk<Action> = suspend (send: Sender<Action>) -> Unit

abstract class Feature<State, Action>(initialState: State) : ViewModel() {
    abstract val reducer: Reducer<State, Action>
    // We keep feature state private so that it can only be changed by reducer
    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()

    val runningJobs: Map<String, Job> = _runningJobs

    /**
     * The current state of the feature.
     */
    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()

    /**
     * Asynchronously sends an action to the reducer in order to update the feature state and trigger any associated side effects.
     *
     * @param action The action to be sent to the reducer.
     */
    suspend fun send(action: Action): Job {
        println("Received action: $action")
        return viewModelScope.launch {
            _state.update { currentState ->
                val (newState, effects) = reducer(currentState, action)
                println("Found ${effects.size} effects to start")
                effects.forEach { start(it) }
                return@update newState
            }
        }
    }

    /**
     * Inner class representing the store of a feature.
     */
    inner class Store() {
        fun dispatch(action: Action): () -> Unit = {
            runBlocking { send(action) }
        }

        @Composable
        operator fun component1(): androidx.compose.runtime.State<State> {
            return this@Feature.state.collectAsState()
        }
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
