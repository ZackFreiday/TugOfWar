using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/admin/users")]
public class AdminUsersController : ControllerBase
{
    private readonly IAdminUserService
        _adminUserService;

    public AdminUsersController(
        IAdminUserService adminUserService)
    {
        _adminUserService =
            adminUserService;
    }

    [HttpGet]
    public async Task<IActionResult>
        GetUsers()
    {
        var users =
            await _adminUserService
                .GetUsersAsync();

        return Ok(users);
    }

    [HttpPost("{userId:int}/suspend")]
    public async Task<IActionResult>
        SuspendUser(
            int userId)
    {
        var currentAdminId =
            GetAuthenticatedUserId();

        await _adminUserService
            .SuspendUserAsync(
                userId,
                currentAdminId);

        return NoContent();
    }

    [HttpPost("{userId:int}/unsuspend")]
    public async Task<IActionResult>
        UnsuspendUser(
            int userId)
    {
        await _adminUserService
            .UnsuspendUserAsync(
                userId);

        return NoContent();
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
