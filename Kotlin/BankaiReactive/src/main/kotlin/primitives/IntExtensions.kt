package io.zheref.bankai.reactive.primitives

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.yield

fun Int.secondsCounter(): Flow<Int> {
    val upTo = this
    return flow {
        for (i in 1..upTo) {
            emit(i)
            delay(1000)
        }
        yield()
    }
}