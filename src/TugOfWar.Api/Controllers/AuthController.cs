using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IProfileService _profileService;
    private readonly IWebHostEnvironment _environment;

    public AuthController(
        IAuthService authService,
        IProfileService profileService,
        IWebHostEnvironment environment)
    {
        _authService = authService;
        _profileService = profileService;
        _environment = environment;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(
        RegisterRequest request)
    {
        var response =
            await _authService.Register(request);

        return Ok(response);
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(
        LoginRequest request)
    {
        var response =
            await _authService.Login(request);

        return Ok(response);
    }

    [Authorize]
    [HttpDelete("account")]
    public async Task<IActionResult> DeleteAccount()
    {
        var userIdValue =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!int.TryParse(
                userIdValue,
                out var userId))
        {
            return Unauthorized();
        }

        var profile =
            await _profileService
                .GetProfileAsync(userId);

        await _authService
            .DeleteAccount(userId);

        DeleteStoredProfileImage(
            profile.ProfileImageUrl);

        return NoContent();
    }

    private string GetProfileImagesDirectory()
    {
        var webRootPath =
            _environment.WebRootPath;

        if (string.IsNullOrWhiteSpace(
                webRootPath))
        {
            webRootPath =
                Path.Combine(
                    _environment.ContentRootPath,
                    "wwwroot");
        }

        return Path.Combine(
            webRootPath,
            "profile-images");
    }

    private void DeleteStoredProfileImage(
        string? profileImageUrl)
    {
        if (string.IsNullOrWhiteSpace(
                profileImageUrl))
        {
            return;
        }

        string imagePath;

        if (Uri.TryCreate(
                profileImageUrl,
                UriKind.Absolute,
                out var absoluteUri))
        {
            imagePath =
                absoluteUri.AbsolutePath;
        }
        else
        {
            imagePath =
                profileImageUrl;
        }

        if (!imagePath.StartsWith(
                "/profile-images/",
                StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var fileName =
            Path.GetFileName(imagePath);

        if (string.IsNullOrWhiteSpace(
                fileName))
        {
            return;
        }

        var filePath =
            Path.Combine(
                GetProfileImagesDirectory(),
                fileName);

        if (System.IO.File.Exists(
                filePath))
        {
            System.IO.File.Delete(
                filePath);
        }
    }
}
