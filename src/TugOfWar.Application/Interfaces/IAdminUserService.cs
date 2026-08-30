using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;

namespace TugOfWar.Application.Interfaces;

public interface IAdminUserService
{
    Task<List<AdminUserResponse>>
        GetUsersAsync();

    Task SuspendUserAsync(
        int userId,
        int currentAdminId);

    Task UnsuspendUserAsync(
        int userId);
}
