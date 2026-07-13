using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Domain.Entities;

public class Comment
{
    public int Id { get; set; }

    public int FaceOffId { get; set; }

    public FaceOff? FaceOff { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool IsDeleted { get; set; }

    public ICollection<CommentLike> Likes { get; set; }
        = new List<CommentLike>();
}
