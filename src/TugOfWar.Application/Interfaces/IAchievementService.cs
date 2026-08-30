using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.Interfaces;

public interface IAchievementService
{
    Task CheckAndUnlockAchievementsAsync(
        int userId);
}
