using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class MyVoteResponse
{
    public bool HasVoted { get; set; }

    public int? ChosenSide { get; set; }

    public int CoinBoostSupport { get; set; }

    public DateTime? CreatedAt { get; set; }
}
