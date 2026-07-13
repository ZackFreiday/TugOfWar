using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/profile")]
public class ProfileController : ControllerBase
{
    private readonly IProfileService _profileService;

    public ProfileController(IProfileService profileService)
    {
        _profileService = profileService;
    }

    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var userId = GetAuthenticatedUserId();

        var profile = await _profileService.GetProfileAsync(userId);

        return Ok(profile);
    }

    private int GetAuthenticatedUserId()
    {
        var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);

        if (!int.TryParse(userIdValue, out var userId))
        {
            throw new UnauthorizedAccessException(
                "The authenticated user ID is invalid.");
        }

        return userId;
    }

    [HttpPut]
    public async Task<IActionResult> UpdateProfile(
    UpdateProfileRequest request)
    {
        var userId = GetAuthenticatedUserId();

        var profile = await _profileService.UpdateProfileAsync(
            userId,
            request);

        return Ok(profile);
    }
}
