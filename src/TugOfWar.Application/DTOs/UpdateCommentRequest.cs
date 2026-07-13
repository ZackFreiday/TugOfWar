using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;

namespace TugOfWar.Application.DTOs;

public class UpdateCommentRequest
{
    [Required(ErrorMessage = "Comment content is required.")]
    [StringLength(
        1000,
        MinimumLength = 1,
        ErrorMessage = "Comment must contain between 1 and 1000 characters.")]
    public string Content { get; set; } = string.Empty;
}
