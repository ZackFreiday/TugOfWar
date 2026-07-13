using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Entities;

public class CommentLike
{
    public int Id { get; set; }

    public int CommentId { get; set; }

    public Comment? Comment { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public DateTime CreatedAt { get; set; }
}
