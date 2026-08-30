using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class AdminUserResponse
{
    public int Id { get; set; }

    public string Username { get; set; } =
        string.Empty;

    public string Email { get; set; } =
        string.Empty;

    public int CoinBalance { get; set; }

    public string? Country { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public bool IsSuspended { get; set; }

    public bool IsAdmin { get; set; }
}
