using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class VoteHistoryResponse
{
    public int FaceOffId { get; set; }

    public string FaceOffTitle { get; set; } = string.Empty;

    public string SideAName { get; set; } = string.Empty;

    public string SideBName { get; set; } = string.Empty;

    public int ChosenSide { get; set; }

    public int CoinBoostSupport { get; set; }

    public DateTime VotedAt { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public int Status { get; set; }
}
