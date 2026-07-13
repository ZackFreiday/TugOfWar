using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;

namespace TugOfWar.Application.DTOs;

public class UpdateProfileRequest
{
    [Required]
    [StringLength(30, MinimumLength = 3)]
    public string Username { get; set; } = string.Empty;

    [StringLength(300)]
    public string? Bio { get; set; }

    [StringLength(100)]
    public string? Country { get; set; }
}
