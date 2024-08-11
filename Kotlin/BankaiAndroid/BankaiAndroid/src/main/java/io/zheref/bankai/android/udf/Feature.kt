package io.zheref.bankai.android.udf

import androidx.compose.runtime.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.zheref.bankai.core.utils.random
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.coroutines.CoroutineContext

abstract class Feature<State, Action>(initialState: State) : ViewModel() {
    /**
     * The function that resolves the results of a given captured action.
     */
    abstract val folder: Folder<State, Action>

    /**
     * Collection of asynchronous job currently in execution.
     */
    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()
    public val runningJobs get(): Map<String, Job> = _runningJobs

    /**
     * The current state of the feature.
     */
    private val _state = MutableStateFlow(initialState)
    public val state: StateFlow<State> = _state.asStateFlow()
    public val currentState get() = state.value

    /**
     * Asynchronously sends an action to the reducer in order to update the feature state and trigger any associated
     * side effects.
     * @param action The action to be sent to the folder.
     * @return the job representing the asynchronous operatin running in the main thread.
     */
    suspend fun send(action: Action): Job {
        println("Received action: $action")
        val (newState, effects) = folder(currentState, action)

        val mutationJob = push(newState)

        println("Found ${effects.size} effects to start")
        effects.forEach { start(it) }
        return mutationJob
    }

    private fun push(newState: State): Job {
        val mutationJob = viewModelScope.launch(Dispatchers.Main) {
            println("Received new state: \n$newState")
            _state.emit(newState)
            println("New state emitted from thread ${Thread.currentThread().name}")
        }

        return mutationJob
    }

    /**
     * Inner class representing the store of a feature.
     */
    inner class Store() {
        /**
         * Dispatches an action from a store to the reducer.
         */
        fun dispatch(action: Action): () -> Unit = {
            runBlocking { send(action) }
        }

        @Composable
        operator fun component1(): androidx.compose.runtime.State<State> {
            return this@Feature.state.collectAsState()
        }
        operator fun component2() = this::dispatch
    }

    /**
     * Data class that represents the outcome of a reducer.
     */
    data class Fold<State, Action>(
        val state: State,
        val effects: List<Effect<Action>> = emptyList()
    ) {
        /**
         * Convenience function to apply an effect to the reduction.
         * @param effect The effect to be applied.
         */
        fun with(effect: Effect<Action>): Fold<State, Action> {
            return Fold(state, listOf(effect))
        }

        /**
         * Convenience function to apply multiple effects to the reduction.
         * @param effects The effects to be applied.
         */
        fun with(vararg effects: Effect<Action>): Fold<State, Action> {
            return Fold(state, effects.toList())
        }

        /**
         * Convenience function to apply list of effects to the reduction.
         * @param effects The effects to be applied.
         */
        fun withEffects(effects: List<Effect<Action>>): Fold<State, Action> {
            return Fold(state, effects)
        }
    }

    /**
     * Returns a new reduction with the new state. Function created for ergonomics and readability.
     */
    public fun resolve(state: State = this.state.value): Fold<State, Action> {
        return Fold(state)
    }

    /**
     * Represents a side effect, with an identifier and a thunk that encapsulates the unit of work.
     */
    data class Effect<out Action>(
        val identifier: String = String.random(),
        val start: ZOperation<Action>
    ) {
        companion object {
            /**
             * Allows the creation of an effect given a flow encapsulating the work to be done.
             * @param identifier The identifier of the effect.
             * @param flow The flow that encapsulates the work to be done.
             * @param context The coroutine context to be used for the flow.
             * @return A new [Effect] instance.
             */
            fun <Action> fromFlow(identifier: String,
                                  flow: Flow<Action>,
                                  context: CoroutineContext = Dispatchers.Default
            ): Effect<Action> {
                return Effect(identifier = identifier, start = { send ->
                    flow
                        .flowOn(context)
                        .map {
                            println("Intercepted action: $it")
                            it
                        }
                        // TODO: Handle exceptions
                        // .catch { send(it) }
                        .collect { send(it) }
                })
            }

            /**
             * Allows the creation of an effect given a suspend function encapsulating the unit of work.
             * @param suspend The suspend function that encapsulates the work to be done.
             * @param identifier The identifier of the effect.
             * @return A new [Effect] instance.
             */
            fun <Action> fromSuspend(suspend: suspend () -> Action,
                                     identifier: String,
                                     context: CoroutineContext = Dispatchers.Default): Effect<Action> {
                return Effect(identifier = identifier) { send ->
                    send(suspend())
                }
            }

            /**
             * Allows the creation of an effect given a function encapsulating the unit of work, which is not
             * expected to resolve any outcome so the operation will never deliver any actions back to the reducer.
             * @param fire The function that encapsulates the work to be done.
             * @return A new [Effect] instance.
             */
            fun <Action> fireAndForget(fire: () -> Unit): Effect<Action> {
                return Effect(start = {
                    runBlocking { launch {
                        // await
                        fire()
                    }}
                })
            }

            /**
             * Allows the creation of an effect given a saga encapsulating multiple potential action dispatches.
             * This is an alternative to fromFlow without having to rely on multiple flows for different operation
             * steps, and instead
             */
            fun <Action> run(work: suspend (send: Sender<Action>) -> Unit, identifier: String = String.random()): Effect<Action> {
                return Effect(identifier = identifier, start = work)
            }

            /**
             * Allows the creation of an effect that runs a list of given effects in sequential order.
             * @param effects The list of effects to be executed.
             */
            fun <Action> concat(vararg effects: Effect<Action>): Effect<Action> {
                return Effect(start = {
                    coroutineScope {
                        effects.forEach { effect ->
                            async { effect.start(it) }
                                .await()
                        }
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

        job.invokeOnCompletion {
            _runningJobs.remove(identifier)
        }

        _runningJobs[identifier] = job
    }

    /**
     * Creates an effect wrapping the termination of a running job (handling an effect)
     * @param identifier The identifier of the job.
     * @return [Effect] the effect to terminate the job.
     */
    public fun cancel(identifier: String): Effect<Action> {
        return Effect(start = {
            terminate(identifier)
        })
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

    /**
     * Waits for all running jobs to complete.
     */
    public suspend fun waitForJobsToComplete() {
        _runningJobs.values.joinAll()
    }
}
