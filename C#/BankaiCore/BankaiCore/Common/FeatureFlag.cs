using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;

public enum FeatureFlagState
{
    /// <summary>
    /// The feature is enabled.
    /// </summary>
    Enabled,
    /// <summary>
    /// The feature is disabled.
    /// </summary>
    Disabled,
    /// <summary>
    /// The feature is in a testing phase.
    /// </summary>
    Testing
}

public struct FeatureFlag
{
    public string Name { get; set; }

    /// <summary>
    /// Creates a new instance of the <see cref="FeatureFlag"/> struct.
    /// </summary>
    public FeatureFlag(string name)
    {
        Name = name;
    }
}

public class FeatureFlagAssignment
{
    public FeatureFlag Flag { get; set; }
    public FeatureFlagState State { get; set; }

    /// <summary>
    /// Creates a new instance of the <see cref="FeatureFlagAssignment"/> class.
    /// </summary>
    public FeatureFlagAssignment(FeatureFlag flag, FeatureFlagState state)
    {
        Flag = flag;
        State = state;
    }
}

public interface FeatureFlagService
{
    /// <summary>
    /// Creates a closure that resolves the state of a feature flag.
    /// </summary>
    /// <param name="flag"> The feature flag to resolve.</param>
    /// <returns> A function that returns a boolean indicating whether the feature is enabled.</returns>
    Func<bool> EnabledResolver(FeatureFlag flag);

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