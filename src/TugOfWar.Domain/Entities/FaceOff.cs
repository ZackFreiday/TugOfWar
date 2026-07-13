using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Domain.Entities;

public class FaceOff
{
    public int Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int CategoryId { get; set; }

    public Category? Category { get; set; }

    public string SideAName { get; set; } = string.Empty;

    public string SideBName { get; set; } = string.Empty;

    public string? SideAImageUrl { get; set; }

    public string? SideBImageUrl { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public FaceOffStatus Status { get; set; } = FaceOffStatus.Draft;

    public bool IsFeatured { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }
}
