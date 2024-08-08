package io.zheref.bankai.core.utils

public fun <T> mutableListWith(elements: List<T>): MutableList<T> {
    val mutableList: MutableList<T> = mutableListOf()
    mutableList.addAll(elements)
    return mutableList
}