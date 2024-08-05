package io.zheref.bankai.udf.rx

import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*

public sealed class ZEvent<out T, out E: Throwable> {
    public data object Complete: ZEvent<Nothing, Nothing>()
    public data class Failure<E: Throwable>(val error: E): ZEvent<Nothing, E>()
    public data class Value<T>(val value: T): ZEvent<T, Nothing>()
}

// Void to * values
public typealias ZSubjectOf<T> = MutableSharedFlow<T>
fun <T> ZSubjectOf<T>.send(value: T) = this::emit
typealias ZFlowOf<T> = Flow<T>

public fun <T, E: Throwable> createFlow(collector: suspend ((ZEvent<T, E>) -> Unit) -> Job): ZFlowOf<T> = callbackFlow {
    val job = collector { event ->
        when (event) {
            is ZEvent.Value -> {
                trySend(event.value)
            }
            is ZEvent.Complete -> close()
            is ZEvent.Failure -> close(event.error)
        }
    }

    awaitClose { job.cancel() }
}