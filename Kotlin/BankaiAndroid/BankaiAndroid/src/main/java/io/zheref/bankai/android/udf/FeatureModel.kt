package io.zheref.bankai.android.udf

import androidx.compose.runtime.*
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
//import androidx.lifecycle.compose
import io.zheref.bankai.core.utils.random
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.coroutines.CoroutineContext

interface ParentFeature<ParentAction> {
    suspend fun receiveFromChild(action: ParentAction): Job
}

/**
 * An abstract class representing a feature model.
 *
 * @param State The type of the feature state.
 * @param Action The type of the action.
 * @property initialState The initial state of the feature.
 * @property folder The function that resolves the results of a given captured action.
 * @property runningJobs A read-only map that holds the currently running jobs.
 * @property state A read-only state flow controlling the current state of the feature.
 * @property currentState The current state of the feature.
 */
abstract class FeatureModel<State, Action>(
    initialState: State
) : ViewModel() {
    /**
     * The function that resolves the results of a given captured action.
     */
    abstract val folder: Folder<State, Action>

    /**
     * Collection of asynchronous job currently in execution.
     */
    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()
    val runningJobs get(): Map<String, Job> = _runningJobs

    /**
     * The current state of the feature.
     */
    private val _state = MutableStateFlow(initialState)
    val state: StateFlow<State> = _state.asStateFlow()
    val currentState get() = state.value

    /**
     * Asynchronously sends an action to the reducer in order to update the feature state and trigger any associated
     * side effects.
     * @param action The action to be sent to the folder.
     * @return the job representing the asynchronous operation running in the main thread.
     */
    suspend fun send(
        action: Action,
        produce: suspend (List<Effect<Action>>) -> Unit = { this.produce(it) }
    ): Job = viewModelScope.launch(Dispatchers.Main) {
        println("Received action: $action")

        _state.update { oldState ->
            val (newState, effects) = folder(oldState, action)
            produce(effects)
            println("Received new state: \n$newState")
            newState
        }
    }

    /**
     * Represents a dispatcher function that creates a function which can be invoked to send the given action
     * @param Action The type of the action.
     */
    fun interface Dispatcher<Action> {
        operator fun invoke(action: Action): () -> Unit
    }

    /**
     * Inner class representing the store of a feature.
     */
    inner class Store() {
        /**
         * Dispatches an action from a store to the reducer.
         */
        val dispatch = Dispatcher<Action> {
            { runBlocking { send(it) } }
        }

        @Composable
        operator fun component1(): androidx.compose.runtime.State<State>
            = this@FeatureModel.state.collectAsStateWithLifecycle()
        operator fun component2(): Dispatcher<Action> = this.dispatch
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

    public val autoresolve get(): Fold<State, Action> = this.resolve()

    /**
     * Represents a side effect, with an identifier and a thunk that encapsulates the unit of work.
     */
    data class Effect<out Action>(
        val identifier: String = String.random(),
        val start: ZOperation<Action>
    ) {
        companion object {
            fun <Action> send(action: Action): Effect<Action> = Effect { it(action) }

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
    
    private suspend fun produce(effects: List<Effect<Action>>) = coroutineScope {
        println("Found ${effects.size} effects to start")
        effects.forEach { start(it) }
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
        val job = viewModelScope.launch(Dispatchers.Default) {
            effect.start(this@FeatureModel::send)
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

    suspend fun receiveFromChild(action: Action) = coroutineScope {
        send(action)
    }
}

abstract class ChildFeatureModel<State, Action, ParentAction>(
    initialState: State,
    val parentFeature: ParentFeature<ParentAction>?
): FeatureModel<State, Action>(
    initialState
) {

    fun Effect.Companion.parentSend(action: ParentAction): Effect<Action> = Effect {
        parentFeature?.receiveFromChild(action)
    }

}
