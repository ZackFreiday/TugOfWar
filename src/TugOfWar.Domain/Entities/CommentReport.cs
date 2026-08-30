using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Entities;

public class CommentReport
{
    public int Id { get; set; }

    public int CommentId { get; set; }

    public Comment? Comment { get; set; }

    public int ReporterUserId { get; set; }

    public User? ReporterUser { get; set; }

    public string Reason { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public bool IsResolved { get; set; }
}
