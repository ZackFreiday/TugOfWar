using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/faceoffs/{faceOffId:int}/votes")]
public class VotesController : ControllerBase
{
    private readonly IVoteService _voteService;

    public VotesController(IVoteService voteService)
    {
        _voteService = voteService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyVote(
        int faceOffId)
    {
        var userId = GetAuthenticatedUserId();

        var vote = await _voteService.GetMyVote(
            userId,
            faceOffId);

        return Ok(vote);
    }

    [HttpPost]
    public async Task<IActionResult> SubmitVote(
        int faceOffId,
        SubmitVoteRequest request)
    {
        var userId = GetAuthenticatedUserId();

        var vote = await _voteService.SubmitVote(
            userId,
            faceOffId,
            request);

        return Ok(vote);
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
