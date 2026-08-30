using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Entities;

public class Notification
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty;

    public int? FaceOffId { get; set; }

    public FaceOff? FaceOff { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }
}
