using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TugOfWar.Application.Interfaces;

namespace TugOfWar.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService
        _notificationService;

    public NotificationsController(
        INotificationService notificationService)
    {
        _notificationService =
            notificationService;
    }

    [HttpGet]
    public async Task<IActionResult>
        GetNotifications()
    {
        var userId =
            GetAuthenticatedUserId();

        var notifications =
            await _notificationService
                .GetNotificationsAsync(
                    userId);

        return Ok(notifications);
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult>
        GetUnreadCount()
    {
        var userId =
            GetAuthenticatedUserId();

        var count =
            await _notificationService
                .GetUnreadCountAsync(
                    userId);

        return Ok(new
        {
            unreadCount = count
        });
    }

    [HttpPost("{id:int}/read")]
    public async Task<IActionResult>
        MarkAsRead(
            int id)
    {
        var userId =
            GetAuthenticatedUserId();

        await _notificationService
            .MarkAsReadAsync(
                userId,
                id);

        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult>
        MarkAllAsRead()
    {
        var userId =
            GetAuthenticatedUserId();

        await _notificationService
            .MarkAllAsReadAsync(
                userId);

        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult>
        DeleteNotification(
            int id)
    {
        var userId =
            GetAuthenticatedUserId();

        await _notificationService
            .DeleteNotificationAsync(
                userId,
                id);

        return NoContent();
    }

    [HttpDelete]
    public async Task<IActionResult>
        DeleteAllNotifications()
    {
        var userId =
            GetAuthenticatedUserId();

        await _notificationService
            .DeleteAllNotificationsAsync(
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
