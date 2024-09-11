package utils

import org.junit.Assert
import kotlin.test.Test
import io.zheref.bankai.core.utils.listMixing
import io.zheref.bankai.core.utils.plusElementsOf

class CollectionTests {

    @Test
    fun testListMixing() {
        // Given
        val list1 = listOf(1, 2, 3)
        val list2 = listOf(4, 5, 6)
        val list3 = listOf(7, 8, 9)

        // When
        val mixedList = listMixing(list1, list2, list3)

        // Then
        Assert.assertEquals(
            list1.size + list2.size + list3.size,
            mixedList.size
        )
        Assert.assertArrayEquals(
            list1
                .plusElementsOf(list2)
                .plusElementsOf(list3)
                .toTypedArray(),
            mixedList.toTypedArray()
        )
    }

    @Test
    fun testListMixingWithRepeatedElements() {
        // Given
        val list1 = listOf(1, 2, 3)
        val list2 = listOf(4, 5, 6)
        val list3 = listOf(5, 6, 7)

        // When
        val mixedList = listMixing(list1, list2, list3)

        // Then (repeated elements should not make a difference)
        Assert.assertEquals(
            list1.size + list2.size + list3.size,
            mixedList.size
        )
        Assert.assertArrayEquals(
            list1
                .plusElementsOf(list2)
                .plusElementsOf(list3)
                .toTypedArray(),
            mixedList.toTypedArray()
        )
    }

    @Test
    fun testPlusElementsOf() {
        // Given
        val list1 = listOf(1, 2, 3)
        val list2 = listOf(4, 5, 6)

        // When
        val addedList = list1.plusElementsOf(list2)

        // Then
        Assert.assertEquals(list1.size + list2.size, addedList.size)
        Assert.assertArrayEquals(
            arrayOf(*list1.toTypedArray(), *list2.toTypedArray()),
            addedList.toTypedArray()
        )
    }

}