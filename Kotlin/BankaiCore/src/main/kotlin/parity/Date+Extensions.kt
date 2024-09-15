package io.zheref.bankai.core.parity

import kotlinx.datetime.*
import kotlinx.datetime.Instant
import java.time.Month
import java.time.Year
import kotlin.time.Duration
import kotlin.time.Duration.Companion.days

public fun Instant.asLocalTime(timeZone: TimeZone = TimeZone.currentSystemDefault()): LocalTime {
    return this.toLocalDateTime(timeZone).time
}

public fun Instant.Companion.fromDateComponents(
    year: Int,
    month: Month,
    day: Int,
    timeZone: TimeZone = TimeZone.currentSystemDefault()
): Instant =
    LocalDateTime(year, month, day, 0, 0, 0)
        .toInstant(timeZone)

public fun Instant.Companion.fromTimeComponents(
    hour: Int,
    min: Int,
    sec: Int = 0,
    timeZone: TimeZone = TimeZone.currentSystemDefault()
): Instant =
    Clock.System.todayIn(timeZone)
        .atTime(hour, min, sec)
        .toInstant(timeZone)

public val Instant.aDayOut get(): Instant = this.plus(1.days)

public fun Instant.endOfDay(
    timeZone: TimeZone = TimeZone.currentSystemDefault()
): Instant =
    toLocalDateTime(timeZone)
        .date
        .atTime(23, 59, 59)
        .toInstant(TimeZone.currentSystemDefault())