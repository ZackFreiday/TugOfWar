using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class NotificationService
    : INotificationService
{
    private const string FaceOffLiveType =
        "FaceOffLive";

    private readonly INotificationRepository
        _notificationRepository;

    public NotificationService(
        INotificationRepository notificationRepository)
    {
        _notificationRepository =
            notificationRepository;
    }

    public async Task<List<NotificationResponse>>
        GetNotificationsAsync(
            int userId)
    {
        var notifications =
            await _notificationRepository
                .GetByUserIdAsync(
                    userId);

        return notifications
            .Select(notification =>
                new NotificationResponse
                {
                    Id =
                        notification.Id,

                    Title =
                        notification.Title,

                    Message =
                        notification.Message,

                    Type =
                        notification.Type,

                    FaceOffId =
                        notification.FaceOffId,

                    IsRead =
                        notification.IsRead,

                    CreatedAt =
                        notification.CreatedAt
                })
            .ToList();
    }

    public async Task<int> GetUnreadCountAsync(
        int userId)
    {
        var notifications =
            await _notificationRepository
                .GetByUserIdAsync(
                    userId);

        return notifications.Count(
            notification =>
                !notification.IsRead);
    }

    public async Task MarkAsReadAsync(
        int userId,
        int notificationId)
    {
        var notification =
            await _notificationRepository
                .GetByIdAsync(
                    notificationId);

        if (notification == null ||
            notification.UserId != userId)
        {
            throw new InvalidOperationException(
                "Notification not found.");
        }

        if (notification.IsRead)
        {
            return;
        }

        notification.IsRead = true;

        await _notificationRepository
            .SaveChangesAsync();
    }

    public async Task MarkAllAsReadAsync(
        int userId)
    {
        var notifications =
            await _notificationRepository
                .GetByUserIdAsync(
                    userId);

        var unreadNotifications =
            notifications
                .Where(notification =>
                    !notification.IsRead)
                .ToList();

        if (unreadNotifications.Count == 0)
        {
            return;
        }

        foreach (var notification
                 in unreadNotifications)
        {
            notification.IsRead = true;
        }

        await _notificationRepository
            .SaveChangesAsync();
    }

    public async Task NotifyFaceOffLiveAsync(
        FaceOff faceOff)
    {
        var userIds =
            await _notificationRepository
                .GetEligibleLiveFaceOffUserIdsAsync(
                    faceOff.Id);

        if (userIds.Count == 0)
        {
            return;
        }

        var now =
            DateTime.UtcNow;

        var notifications =
            new List<Notification>();

        foreach (var userId in userIds)
        {
            var alreadyExists =
                await _notificationRepository
                    .ExistsAsync(
                        userId,
                        faceOff.Id,
                        FaceOffLiveType);

            if (alreadyExists)
            {
                continue;
            }

            notifications.Add(
                new Notification
                {
                    UserId =
                        userId,

                    Title =
                        "New face-off",

                    Message =
                        $"{faceOff.Title} is now live. Choose your side.",

                    Type =
                        FaceOffLiveType,

                    FaceOffId =
                        faceOff.Id,

                    IsRead =
                        false,

                    CreatedAt =
                        now
                });
        }

        if (notifications.Count == 0)
        {
            return;
        }

        await _notificationRepository
            .CreateManyAsync(
                notifications);
    }

    public async Task DeleteNotificationAsync(
        int userId,
        int notificationId)
    {
        var notification =
            await _notificationRepository
                .GetByIdAsync(
                    notificationId);

        if (notification == null ||
            notification.UserId != userId)
        {
            throw new InvalidOperationException(
                "Notification not found.");
        }

        await _notificationRepository
            .DeleteAsync(
                notification);
    }

    public async Task DeleteAllNotificationsAsync(
        int userId)
    {
        await _notificationRepository
            .DeleteAllByUserIdAsync(
                userId);
    }
}
