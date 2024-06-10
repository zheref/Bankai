package io.zheref.bankai.android.redux

import androidx.compose.runtime.Composable
import io.zheref.bankai.udf.redux.Dispatcher
import io.zheref.bankai.udf.redux.TypedDispatcher

/**
 * Retrieves a [Dispatcher] from the current local store
 * @return retrieved [Dispatcher]
 * @see StoreProvider
 * @see rememberTypedDispatcher
 */
@Composable
public fun rememberDispatcher(): Dispatcher = rememberStore<Any>().dispatch

/**
 * Retrieves a [Dispatcher] from the current local store
 * @return retrieved [Dispatcher]
 * @see StoreProvider
 * @see rememberDispatcher
 */
@Composable
public fun <Action> rememberTypedDispatcher(): TypedDispatcher<Action> =
    rememberTypedStore<Any, Action>().dispatch