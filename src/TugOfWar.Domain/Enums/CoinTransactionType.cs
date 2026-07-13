using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Enums;

public enum CoinTransactionType
{
    EarnedParticipation = 1,
    EarnedDailyReward = 2,
    Purchase = 3,
    SpentBoost = 4,
    Refund = 5,
    AdminAdjustment = 6
}
