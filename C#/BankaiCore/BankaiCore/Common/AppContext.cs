using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;
public interface AppContext
{
    public void AddDependency(IDepContainer dep);

    public DepContainer<T>? GetDependencyContainer<T>(string name) where T : class;

    public Dep? GetDependency<Dep>(string name, DepEnv environment) where Dep : class;
}
