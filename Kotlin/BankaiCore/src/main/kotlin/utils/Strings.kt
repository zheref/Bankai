package io.zheref.bankai.core.utils

public fun String.camelCase(): String =
    this
        .replaceFirstChar { it.lowercase() }

public fun String.Companion.random(): String {
    return (0..10).map { ('a'..'z').random() }.joinToString("")
}