using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.Interfaces;

public interface IAdminUserService
{
    Task SuspendUserAsync(int userId, int currentAdminId);

    Task UnsuspendUserAsync(int userId);
}
