package io.zheref.bankai.android.udf

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.zheref.bankai.core.utils.random
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

public interface IStore<State, Action> {
    suspend fun send(action: Action): Job
    fun send(thunk: ZThunk<State, Action>): Job
    suspend fun waitForJobsToComplete()
}

public class Store<State, Action>(
    initialState: State,
    val reducer: Reducer<State, Action>,
): ViewModel(), IStore<State, Action> {

    // State
    private val _state = MutableStateFlow(initialState)
    public val state: StateFlow<State> = _state.asStateFlow()
    public val currentState get() = state.value

    private val _runningJobs: MutableMap<String, Job> = mutableMapOf()
    public val runningJobs get(): Map<String, Job> = _runningJobs

    // Public interface

    override suspend fun send(action: Action): Job {
        println("Received action: $action")
        val (newState, effects) = reducer(currentState, action)

        val mutationJob = push(newState)

        println("Found ${effects.size} effects to start")
        effects.forEach { start(it) }
        return mutationJob
    }

    override fun send(thunk: ZThunk<State, Action>): Job {
        println("Received thunk: $thunk")

        val thunkJob = viewModelScope.launch {
            thunk(::dispatch) { currentState }
        }

        return thunkJob
    }

    override suspend fun waitForJobsToComplete() {
        _runningJobs.values.joinAll()
    }

    // Private operations

    private fun dispatch(action: Action) = runBlocking {
        launch(Dispatchers.Default) {
            send(action)
        }
    }

    private suspend fun start(effect: Effect<Action>) {
        val identifier = effect.identifier ?: String.random()

        println("Starting thunk with identifier: $identifier")
        val job = viewModelScope.launch {
            effect.operation(this@Store::send)
        }

        job.invokeOnCompletion {
            _runningJobs.remove(identifier)
        }

        _runningJobs[identifier] = job
    }

    private fun push(newState: State): Job {
        val mutationJob = viewModelScope.launch(Dispatchers.Main) {
            println("Received new state: \n$newState")
            _state.emit(newState)
            println("New state emitted from thread ${Thread.currentThread().name}")
        }

        return mutationJob
    }

    // Contextual Types

    fun resolve(state: State = currentState): Reduction<State, Action> = Reduction<State, Action>(state)
    val autoresolve get(): Reduction<State, Action> = this.resolve()

    data class Reduction<State, Action> (
        val state: State,
        val effects: List<Effect<Action>> = emptyList(),
    ) {
        fun with(effect: Effect<Action>): Reduction<State, Action> = Reduction(state, listOf(effect))
        fun with(vararg effects: Effect<Action>): Reduction<State, Action> = Reduction(state, effects.toList())
        fun with(effects: List<Effect<Action>>): Reduction<State, Action> = Reduction(state, effects)
        fun then(vararg  effects: Effect<Action>): Reduction<State, Action> = Reduction(state, effects.toList())
        fun then(effects: List<Effect<Action>>): Reduction<State, Action> = Reduction(state, listOf(Effect.concat(effects)))
    }

    data class Effect<out Action> private constructor(
        val identifier: String = String.random(),
        val operation: ZOperation<Action>
    ) {
        companion object {
            fun <Action> fireAndForget(fire: () -> Unit): Effect<Action>
                = Effect { fire() }

            fun <Action> future(suspend: suspend () -> Action, identifier: String = String.random()): Effect<Action>
                 = Effect(identifier = identifier) { it(suspend()) }

            fun <Action> run(work: ZOperation<Action>, identifier: String = String.random()): Effect<Action>
                = Effect(identifier = identifier, operation = work)

            fun <Action> flow(flow: ZFlow<Action>, identifier: String = String.random()): Effect<Action>
                = Effect(identifier, operation = flow.forEffect())

            fun <State, Action> thunk(work: Thunk<State, Action>, identifier: String = String.random()): ZThunk<State, Action>
                = ZThunk(work)

            fun <Action> concat(effects: List<Effect<Action>>): Effect<Action> = Effect { withSender ->
                coroutineScope {
                    effects.forEach { effect ->
                        async { effect.operation(withSender) }
                            .await()
                    }
                }
            }
        }
    }



}