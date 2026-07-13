using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Domain.Entities;

public class CoinTransaction
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public int? FaceOffId { get; set; }

    public FaceOff? FaceOff { get; set; }

    public int Amount { get; set; }

    public CoinTransactionType Type { get; set; }

    public DateTime CreatedAt { get; set; }
}
