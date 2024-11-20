namespace BankaiCore.Common;

public static class DurationExtensions
{
    /// <summary>
    /// This integer interpreted as a TimeSpan in hours.
    /// </summary>
    /// <param name="self">This integer number</param>
    /// <returns>The corresponding <see cref="TimeSpan"/> interpretation in hours</returns>
    public static TimeSpan hours(this int self)
        => TimeSpan.FromHours(self);


    /// <summary>
    /// This integer interpreted as a TimeSpan in minutes.
    /// </summary>
    /// <param name="self">This integer number</param>
    /// <returns>The corresponding <see cref="TimeSpan"/> interpretation in minutes</returns>
    public static TimeSpan minutes(this int self)
        => TimeSpan.FromMinutes(self);

    /// <summary>
    /// This integer interpreted as a TimeSpan in seconds.
    /// </summary>
    /// <param name="self">This integer number</param>
    /// <returns>The corresponding <see cref="TimeSpan"/> interpretation in seconds</returns>
    public static TimeSpan seconds(this int self)
        => TimeSpan.FromSeconds(self);

    /// <summary>
    /// A string representation of this TimeSpan in digital format.
    /// As in: "00:00:00"
    /// </summary>
    /// <param name="self">This duration as a TimeSpan</param>
    /// <param name="includingSeconds">Whether to include seconds in the output</param>
    /// <returns>Digital formatted string reading this duration</returns>
    public static string digitalDuration(this TimeSpan self, bool includingSeconds = false)
        => includingSeconds && self.Hours > 0 ? 
            $"{self.Hours:D2}:{self.Minutes:D2}:{self.Seconds:D2}"
            : $"{self.Minutes:D2}:{self.Seconds:D2}";
}