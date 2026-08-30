using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class CommentResponse
{
    public int Id { get; set; }

    public int FaceOffId { get; set; }

    public int UserId { get; set; }

    public string Username { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int LikeCount { get; set; }

    public bool IsLikedByCurrentUser { get; set; }

    public int? ChosenSide { get; set; }
}
