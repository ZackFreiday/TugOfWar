using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Entities;

public class DailyReward
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public DateOnly RewardDate { get; set; }

    public int VotesRequired { get; set; }

    public int CoinsAwarded { get; set; }

    public DateTime CreatedAt { get; set; }
}
