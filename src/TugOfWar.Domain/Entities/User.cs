using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;

namespace TugOfWar.Domain.Entities;

public class User : IdentityUser<int>
{
    public int CoinBalance { get; set; }

    public string? ProfileImageUrl { get; set; }

    public string? Bio { get; set; }

    public string? Country { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public bool IsSuspended { get; set; }
}
