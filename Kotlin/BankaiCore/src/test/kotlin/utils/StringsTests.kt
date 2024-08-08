package utils

import io.zheref.bankai.core.utils.camelCase
import org.junit.Assert
import kotlin.test.Test

class StringsTests {

    @Test
    fun testStringCamelCase() {
        Assert.assertEquals("event", "Event".camelCase())
        Assert.assertEquals("a", "A".camelCase())
        Assert.assertEquals("qA", "QA".camelCase())
        Assert.assertEquals("toDo", "ToDo".camelCase())
        Assert.assertEquals("toto", "toto".camelCase())
    }

}