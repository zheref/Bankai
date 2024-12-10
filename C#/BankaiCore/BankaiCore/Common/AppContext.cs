using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;
public interface AppContext
{
    public void AddDependency(IDepContainer dep);
    public DepContainer<T>? GetDependency<T>(string name) where T: class;
}
