
namespace BankaiCore.Common;

public interface Identifiable
{
    /// <summary>
    /// Returns the identifier of the object.
    /// </summary>
    /// <returns>Identifier of the object.</returns>
    public String Identifier { get; }
}