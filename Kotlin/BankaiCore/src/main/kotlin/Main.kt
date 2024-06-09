package io.zheref

fun main() {
    println("Hello World!")
}

fun isNumber(number: Int, multipleOf: Int): Boolean {
    return number % multipleOf == 0
}