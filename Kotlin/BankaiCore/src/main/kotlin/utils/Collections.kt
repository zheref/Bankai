package io.zheref.bankai.core.utils

/**
 * Returns a new list with the elements of all lists passed as parameter in
 * the order they were passed.
 * @param lists A variadic series of lists to mixed into a single list.
 * @return A new list with the elements of all lists in order.
 */
fun <T> listMixing(vararg lists: List<T>): List<T> {
    val totalList = mutableListOf<T>()
    for (list in lists) {
        totalList.addAll(list)
    }
    return totalList
}

/**
 * Returns a new list with the original elements of the collection plus
 * the elements of the list passed as parameter appended at the end.
 * @param list The list which elements should be appended at the very end
 * of the current collection.
 * @return A new reference to a new list with the elements of both arrays.
 */
fun <T> List<T>.plusElementsOf(list: List<T>): List<T> {
    val newList = mutableListOf<T>()
    newList.addAll(this)
    newList.addAll(list)
    return newList
}