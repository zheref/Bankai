package io.zheref.bankai.android.udf

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn

typealias Folder<State, Action> = (state: State, action: Action) -> FeatureModel.Fold<State, Action>
typealias Reducer<State, Action> = Store<State, Action>.(state: State, action: Action) -> Store.Reduction<State, Action>
typealias Sender<Action> = suspend (action: Action) -> Job
typealias Dispatcher<Action> = (action: Action) -> Unit
typealias StateResolver<State> = () -> State

// Effect Types
typealias Thunk<State, Action> = (dispatch: Dispatcher<Action>, getState: StateResolver<State>) -> Job
fun interface ZThunk<State, Action> {
    operator fun invoke(dispatch: Dispatcher<Action>, getState: StateResolver<State>): Job
}

typealias ZOperation<Action> = suspend (send: Sender<Action>) -> Unit
typealias ZFlow<Action> = Flow<Action>

suspend fun <Action> ZFlow<Action>.autosend(on: CoroutineDispatcher, using: Sender<Action>) {
    this.flowOn(on).collect { using(it) }
}

fun <Action> ZFlow<Action>.forEffect(): ZOperation<Action> = {
    this.autosend(Dispatchers.IO, using = it)
}