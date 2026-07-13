using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Domain.Entities;

public class Vote
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public int FaceOffId { get; set; }

    public FaceOff? FaceOff { get; set; }

    public ChosenSide ChosenSide { get; set; }

    public int BaseSupport { get; set; } = 100;

    public int CoinBoostSupport { get; set; }

    public DateTime CreatedAt { get; set; }
}
