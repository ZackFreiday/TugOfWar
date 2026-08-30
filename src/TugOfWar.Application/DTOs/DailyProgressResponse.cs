using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class DailyProgressResponse
{
    public int VotesToday { get; set; }

    public int VotesRequired { get; set; }

    public int RewardCoins { get; set; }

    public bool RewardClaimed { get; set; }
}
