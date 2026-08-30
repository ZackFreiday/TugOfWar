using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class SubmitVoteResponse
{
    public int VoteId { get; set; }

    public int FaceOffId { get; set; }

    public int ChosenSide { get; set; }

    public int CoinBoostSupport { get; set; }

    public int VotesToday { get; set; }

    public int VotesRequired { get; set; }

    public bool DailyRewardEarned { get; set; }

    public int DailyRewardCoins { get; set; }

    public int CoinBalance { get; set; }
}
