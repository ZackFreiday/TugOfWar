using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class CoinTransactionHistoryResponse
{
    public int Id { get; set; }

    public int Amount { get; set; }

    public int Type { get; set; }

    public string TypeName { get; set; } = string.Empty;

    public int? FaceOffId { get; set; }

    public string? FaceOffTitle { get; set; }

    public DateTime CreatedAt { get; set; }
}
