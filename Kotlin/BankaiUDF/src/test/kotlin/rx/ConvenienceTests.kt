package rx

import io.zheref.bankai.udf.rx.ZEvent
import io.zheref.bankai.udf.rx.ZFlowOf
import io.zheref.bankai.udf.rx.createFlow
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import org.junit.Rule
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

class ConvenienceTests {

    @OptIn(ExperimentalCoroutinesApi::class)
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @OptIn(ExperimentalCoroutinesApi::class)
    @Test
    fun testCreateFlow_v1() = runTest {
        val sut: ZFlowOf<Int> = createFlow { send ->
            // Iterate for 5 seconds and send the seconds ellapsed every 1 second
            val job = launch {
                var ellapsedSeconds = 0
                val milliSecondsToEllapsed = 1000
                for (i in 0..4) {
                    delay(milliSecondsToEllapsed.toLong())
                    ellapsedSeconds += milliSecondsToEllapsed / 1000
                    send(ZEvent.Value(ellapsedSeconds))
                }

                send(ZEvent.Complete)
            }

            job.invokeOnCompletion { it?.let { error -> send(ZEvent.Failure(error)) } }

            return@createFlow job
        }

        val result = sut.toList()
        assertEquals(
            expected = listOf(1, 2, 3, 4, 5),
            actual = result
        )
    }

}