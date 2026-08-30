using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class CommentReportResponse
{
    public int Id { get; set; }

    public int CommentId { get; set; }

    public int FaceOffId { get; set; }

    public string FaceOffTitle { get; set; } =
        string.Empty;

    public int CommentUserId { get; set; }

    public string CommentUsername { get; set; } =
        string.Empty;

    public string CommentContent { get; set; } =
        string.Empty;

    public int ReporterUserId { get; set; }

    public string ReporterUsername { get; set; } =
        string.Empty;

    public string Reason { get; set; } =
        string.Empty;

    public DateTime CreatedAt { get; set; }

    public bool IsResolved { get; set; }
}
