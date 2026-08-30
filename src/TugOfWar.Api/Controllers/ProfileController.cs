using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/profile")]
public class ProfileController : ControllerBase
{
    private static readonly HashSet<string>
        AllowedProfileImageExtensions =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        };

    private readonly IProfileService _profileService;
    private readonly IWebHostEnvironment _environment;

    public ProfileController(
        IProfileService profileService,
        IWebHostEnvironment environment)
    {
        _profileService = profileService;
        _environment = environment;
    }

    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var userId =
            GetAuthenticatedUserId();

        var profile =
            await _profileService
                .GetProfileAsync(
                    userId);

        return Ok(profile);
    }

    [HttpGet("votes")]
    public async Task<IActionResult>
        GetVoteHistory()
    {
        var userId =
            GetAuthenticatedUserId();

        var history =
            await _profileService
                .GetVoteHistoryAsync(
                    userId);

        return Ok(history);
    }

    [HttpGet("comments")]
    public async Task<IActionResult>
        GetCommentHistory()
    {
        var userId =
            GetAuthenticatedUserId();

        var history =
            await _profileService
                .GetCommentHistoryAsync(
                    userId);

        return Ok(history);
    }

    [HttpGet("achievements")]
    public async Task<IActionResult>
        GetAchievements()
    {
        var userId =
            GetAuthenticatedUserId();

        var achievements =
            await _profileService
                .GetAchievementsAsync(
                    userId);

        return Ok(achievements);
    }

    [HttpPut]
    public async Task<IActionResult>
        UpdateProfile(
            UpdateProfileRequest request)
    {
        var userId =
            GetAuthenticatedUserId();

        var profile =
            await _profileService
                .UpdateProfileAsync(
                    userId,
                    request);

        return Ok(profile);
    }

    [HttpPost("image")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult>
        UploadProfileImage(
            IFormFile image)
    {
        var userId =
            GetAuthenticatedUserId();

        if (image == null ||
            image.Length == 0)
        {
            return BadRequest(
                new
                {
                    message =
                        "Select an image first."
                });
        }

        const long maxOriginalImageSize =
            20 * 1024 * 1024;

        if (image.Length >
            maxOriginalImageSize)
        {
            return BadRequest(
                new
                {
                    message =
                        "The selected image is too large. "
                        + "Please choose an image smaller than 20 MB."
                });
        }

        var extension =
            Path.GetExtension(
                image.FileName);

        if (string.IsNullOrWhiteSpace(
                extension) ||
            !AllowedProfileImageExtensions
                .Contains(
                    extension))
        {
            return BadRequest(
                new
                {
                    message =
                        "Only JPG, JPEG, PNG, and WEBP images are allowed."
                });
        }

        Image processedImage;

        try
        {
            await using var inputStream =
                image.OpenReadStream();

            processedImage =
                await Image.LoadAsync(
                    inputStream);
        }
        catch
        {
            return BadRequest(
                new
                {
                    message =
                        "The selected file could not be read as a valid image."
                });
        }

        var existingProfile =
            await _profileService
                .GetProfileAsync(
                    userId);

        using (processedImage)
        {
            processedImage.Mutate(
                context =>
                {
                    context.AutoOrient();

                    context.Resize(
                        new ResizeOptions
                        {
                            Size =
                                new Size(
                                    1024,
                                    1024),
                            Mode =
                                ResizeMode.Max
                        });
                });

            var profileImagesDirectory =
                GetProfileImagesDirectory();

            Directory.CreateDirectory(
                profileImagesDirectory);

            var fileName =
                $"{Guid.NewGuid():N}.jpg";

            var filePath =
                Path.Combine(
                    profileImagesDirectory,
                    fileName);

            var encoder =
                new JpegEncoder
                {
                    Quality = 85
                };

            await processedImage.SaveAsync(
                filePath,
                encoder);

            var relativeImageUrl =
                $"/profile-images/{fileName}";

            var absoluteImageUrl =
                $"{Request.Scheme}://"
                + $"{Request.Host}"
                + relativeImageUrl;

            try
            {
                var updatedProfile =
                    await _profileService
                        .UpdateProfileImageAsync(
                            userId,
                            absoluteImageUrl);

                DeleteStoredProfileImage(
                    existingProfile
                        .ProfileImageUrl);

                return Ok(
                    new
                    {
                        profileImageUrl =
                            absoluteImageUrl,
                        profile =
                            updatedProfile
                    });
            }
            catch
            {
                // The database update failed,
                // so do not leave the newly
                // uploaded file behind.
                if (System.IO.File.Exists(
                        filePath))
                {
                    System.IO.File.Delete(
                        filePath);
                }

                throw;
            }
        }
    }

    [HttpDelete("image")]
    public async Task<IActionResult>
        DeleteProfileImage()
    {
        var userId =
            GetAuthenticatedUserId();

        var existingProfile =
            await _profileService
                .GetProfileAsync(
                    userId);

        var updatedProfile =
            await _profileService
                .RemoveProfileImageAsync(
                    userId);

        DeleteStoredProfileImage(
            existingProfile
                .ProfileImageUrl);

        return Ok(
            updatedProfile);
    }

    [HttpGet("daily-progress")]
    public async Task<IActionResult>
        GetDailyProgress()
    {
        var userId =
            GetAuthenticatedUserId();

        var progress =
            await _profileService
                .GetDailyProgressAsync(
                    userId);

        return Ok(progress);
    }

    [HttpGet("coin-transactions")]
    public async Task<IActionResult>
        GetCoinTransactions()
    {
        var userId =
            GetAuthenticatedUserId();

        var transactions =
            await _profileService
                .GetCoinTransactionHistoryAsync(
                    userId);

        return Ok(transactions);
    }

    private string
        GetProfileImagesDirectory()
    {
        var webRootPath =
            _environment.WebRootPath;

        if (string.IsNullOrWhiteSpace(
                webRootPath))
        {
            webRootPath =
                Path.Combine(
                    _environment
                        .ContentRootPath,
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
            Path.GetFileName(
                imagePath);

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

    private int GetAuthenticatedUserId()
    {
        var userIdValue =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!int.TryParse(
                userIdValue,
                out var userId))
        {
            throw new UnauthorizedAccessException(
                "The authenticated user ID is invalid.");
        }

        return userId;
    }
}
