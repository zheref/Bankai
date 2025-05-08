namespace BankaiCore.Common;

public interface FeatureFlagManager
{
    /// <summary>
    /// Creates a closure that resolves the state of a feature flag.
    /// </summary>
    /// <param name="flag"> The feature flag to resolve.</param>
    /// <returns> A function that returns a boolean indicating whether the feature is enabled.</returns>
    Func<bool> EnabledResolver(FeatureFlag flag);

    /// <summary>
    /// Checks if a feature flag is enabled.
    /// </summary>
    /// <param name="flag">The feature flag to check</param>
    /// <returns>Whether it is enabled or not</returns>
    Boolean IsEnabled(FeatureFlag flag);

    /// <summary>
    /// Retrieves the current state of a feature flag.
    /// </summary>
    /// <param name="flag" > The feature flag to check.</param>
    /// <returns> The current state of the feature flag.</returns>
    FeatureFlagState? StateFor(FeatureFlag flag);

    /// <summary>
    /// Changes the state of a feature flag.
    /// </summary>
    /// <param name="flag"> The feature flag to change.</param>
    /// <param name="state"> The new state of the feature flag.</param>
    void ChangeState(FeatureFlag flag, FeatureFlagState state);
}