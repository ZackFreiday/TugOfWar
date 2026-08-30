using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/admin/comment-reports")]
public class AdminCommentReportsController
    : ControllerBase
{
    private readonly ICommentService
        _commentService;

    public AdminCommentReportsController(
        ICommentService commentService)
    {
        _commentService =
            commentService;
    }

    [HttpGet]
    public async Task<IActionResult>
        GetUnresolvedReports()
    {
        var reports =
            await _commentService
                .GetUnresolvedReportsAsync();

        return Ok(reports);
    }

    [HttpPost("{id:int}/dismiss")]
    public async Task<IActionResult>
        DismissReport(
            int id)
    {
        await _commentService
            .DismissReportAsync(
                id);

        return NoContent();
    }

    [HttpDelete("{id:int}/comment")]
    public async Task<IActionResult>
        DeleteReportedComment(
            int id)
    {
        await _commentService
            .DeleteReportedCommentAsync(
                id);

        return NoContent();
    }
}
