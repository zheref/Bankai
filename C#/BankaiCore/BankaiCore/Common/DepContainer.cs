namespace BankaiCore.Common;

public interface IDepContainer
{
    string Name { get; init; }
}

public interface DepContainer<Dep> : IDepContainer where Dep: class
{
    Dep Live { get; }
    Dep Test { get; set; }
    Dep Preview { get; set; }
}
