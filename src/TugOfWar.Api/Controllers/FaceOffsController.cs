using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FaceOffsController : ControllerBase
{
    private readonly IFaceOffService _faceOffService;

    public FaceOffsController(IFaceOffService faceOffService)
    {
        _faceOffService = faceOffService;
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    public async Task<IActionResult> CreateFaceOff(
        CreateFaceOffRequest request)
    {
        var faceOff = await _faceOffService.CreateFaceOff(request);

        return CreatedAtAction(
            nameof(GetFaceOff),
            new { id = faceOff.Id },
            faceOff);
    }

    [HttpGet]
    public async Task<IActionResult> GetFaceOffs()
    {
        var faceOffs = await _faceOffService.GetFaceOffs();

        return Ok(faceOffs);
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetFaceOff(int id)
    {
        var faceOff = await _faceOffService.GetFaceOffById(id);

        if (faceOff == null)
        {
            return NotFound();
        }

        return Ok(faceOff);
    }

    [Authorize]
    [HttpGet("{id:int}/results")]
    public async Task<IActionResult> GetResults(int id)
    {
        var userId = GetAuthenticatedUserId();

        var result = await _faceOffService.GetResultsAsync(
            id,
            userId);

        return Ok(result);
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

    [Authorize(Roles = "Admin")]
    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateFaceOff(
    int id,
    UpdateFaceOffRequest request)
    {
        var faceOff = await _faceOffService.UpdateFaceOffAsync(
            id,
            request);

        return Ok(faceOff);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id:int}/archive")]
    public async Task<IActionResult> ArchiveFaceOff(int id)
    {
        await _faceOffService.ArchiveFaceOffAsync(id);

        return NoContent();
    }

    [Authorize(Roles = "Admin")]
    [HttpPost("{id:int}/close")]
    public async Task<IActionResult> CloseFaceOff(int id)
    {
        await _faceOffService.CloseFaceOffAsync(id);

        return NoContent();
    }
}
