using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class FaceOffResultResponse
{
    public int FaceOffId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string SideAName { get; set; } = string.Empty;

    public string SideBName { get; set; } = string.Empty;

    public int SideAVotes { get; set; }

    public int SideBVotes { get; set; }

    public int SideASupport { get; set; }

    public int SideBSupport { get; set; }

    public int TotalParticipants { get; set; }

    public double SideAPercentage { get; set; }

    public double SideBPercentage { get; set; }

    public string? UserSupportedSide { get; set; }
}
