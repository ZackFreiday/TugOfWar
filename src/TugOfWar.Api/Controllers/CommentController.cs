using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/faceoffs/{faceOffId}/comments")]
public class CommentsController : ControllerBase
{
    private readonly ICommentService _commentService;

    public CommentsController(ICommentService commentService)
    {
        _commentService = commentService;
    }

    [HttpGet]
    public async Task<IActionResult> GetComments(int faceOffId)
    {
        var userId = GetAuthenticatedUserId();

        var comments = await _commentService.GetCommentsAsync(
            userId,
            faceOffId);

        return Ok(comments);
    }

    [HttpPost]
    public async Task<IActionResult> CreateComment(
        int faceOffId,
        CreateCommentRequest request)
    {
        var userId = GetAuthenticatedUserId();

        var comment = await _commentService.CreateCommentAsync(
            userId,
            faceOffId,
            request);

        return Ok(comment);
    }

    [HttpPut("{commentId:int}")]
    public async Task<IActionResult> UpdateComment(
        int commentId,
        UpdateCommentRequest request)
    {
        var userId = GetAuthenticatedUserId();

        var comment = await _commentService.UpdateCommentAsync(
            userId,
            commentId,
            request);

        return Ok(comment);
    }

    [HttpDelete("{commentId:int}")]
    public async Task<IActionResult> DeleteComment(int commentId)
    {
        var userId = GetAuthenticatedUserId();

        await _commentService.DeleteCommentAsync(
            userId,
            commentId);

        return NoContent();
    }

    [HttpPost("{commentId:int}/like")]
    public async Task<IActionResult> ToggleLike(int commentId)
    {
        var userId = GetAuthenticatedUserId();

        var comment = await _commentService.ToggleLikeAsync(
            userId,
            commentId);

        return Ok(comment);
    }

    private int GetAuthenticatedUserId()
    {
        var userIdValue = User.FindFirstValue(
            ClaimTypes.NameIdentifier);

        if (!int.TryParse(userIdValue, out var userId))
        {
            throw new UnauthorizedAccessException(
                "The authenticated user ID is invalid.");
        }

        return userId;
    }
}
