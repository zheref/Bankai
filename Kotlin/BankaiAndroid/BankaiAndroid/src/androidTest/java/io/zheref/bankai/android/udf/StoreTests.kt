package io.zheref.bankai.android.udf

object testFeature {
    val reducer: Reducer<State, Action> = { state, action ->
        when (action) {
            is Action.Dismiss -> resolve(state.copy(name = ""))
            else -> resolve()
        }
    }

//    var store: Store<State, Action> = Store(
//        initialState = State(name = ""),
//        reducer = this.reducer
//    )

    data class State(val name: String)

    sealed class Action {
        data object Dismiss: Action()
    }
}