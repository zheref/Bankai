package io.zheref.bankai.core.utils

public fun String.camelCase(): String =
    this
        .replaceFirstChar { it.lowercase() }