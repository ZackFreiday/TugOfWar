using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TugOfWar.Application.DTOs;

public class FaceOffListResponse
{
    public int Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int CategoryId { get; set; }

    public string? CategoryName { get; set; }

    public string SideAName { get; set; } = string.Empty;

    public string SideBName { get; set; } = string.Empty;

    public string? SideAImageUrl { get; set; }

    public string? SideBImageUrl { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public int Status { get; set; }

    public bool IsFeatured { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public string? WinningSide { get; set; }

    public bool? IsTie { get; set; }

    public double? SideAPercentage { get; set; }

    public double? SideBPercentage { get; set; }
}
