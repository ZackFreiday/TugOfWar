using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class CommentHistoryResponse
{
    public int CommentId { get; set; }

    public int FaceOffId { get; set; }

    public string FaceOffTitle { get; set; }
        = string.Empty;

    public string Content { get; set; }
        = string.Empty;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int LikeCount { get; set; }
}
