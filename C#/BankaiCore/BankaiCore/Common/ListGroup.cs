namespace BankaiCore.Common;

public class ListGroup<Element, K> : List<Element> where Element : Identifiable
{
    public K Key { get; set; }

    public ListGroup(K key, IEnumerable<Element> items) : base(items) 
    {
        this.Key = key;
    }

    public bool IsEmpty => Count == 0;

    public string GroupName => Key!.ToString() ?? "";
}