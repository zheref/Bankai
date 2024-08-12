package io.zheref.bankai.core.parity

public typealias Void = Unit

public abstract class Result<out T, out E: Exception> {}
public data class SuccessResult<out T, out E: Exception>(val value: T): Result<T, E>()
public data class FailureResult<out T, out E: Exception>(val exception: E): Result<T, E>()

// Void to void ONCE
public typealias ZBlock = (Exception?) -> Unit
public typealias ZJob = suspend () -> Unit

// Void to 1 value
public typealias ZFuture<T> = suspend () -> T

// Void to 1..* values
public typealias ZYielderOf<T, E> = ((Result<T, E>) -> Void) -> Void

data class ZBinding<T>(
    val get: () -> T,
    var set: (T) -> Unit
) {
    companion object {
        fun <T> create(initialValue: T): ZBinding<T> {
            var value = initialValue
            return ZBinding(
                get = { value },
                set = { newValue -> value = newValue }
            )
        }

        fun <T> constant(value: T): ZBinding<T>
            = ZBinding(
                get = { value },
                set = { _ -> }
            )
    }
}