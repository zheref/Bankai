using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BankaiCore.Common;

public static class DateExtensions
{
    public static DateTime oneDayOut(this DateTime self) => self.AddDays(1);
}
