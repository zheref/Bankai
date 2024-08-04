package io.zheref.bankai.udf.rx

import kotlinx.coroutines.flow.MutableSharedFlow

// Void to * values
public typealias ZFlowOf<T> = MutableSharedFlow<T>