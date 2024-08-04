package io.zheref.bankai.core.parity

public typealias Void = Unit

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