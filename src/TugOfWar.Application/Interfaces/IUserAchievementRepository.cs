using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IUserAchievementRepository
{
    Task<bool> HasUnlockedAsync(
        int userId,
        string code);

    Task<UserAchievement> CreateAsync(
        UserAchievement achievement);
}
