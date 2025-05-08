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

