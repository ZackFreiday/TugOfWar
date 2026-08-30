using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface INotificationService
{
    Task<List<NotificationResponse>>
        GetNotificationsAsync(
            int userId);

    Task<int> GetUnreadCountAsync(
        int userId);

    Task MarkAsReadAsync(
        int userId,
        int notificationId);

    Task MarkAllAsReadAsync(
        int userId);

    Task NotifyFaceOffLiveAsync(
        FaceOff faceOff);

    Task DeleteNotificationAsync(
        int userId,
        int notificationId);

    Task DeleteAllNotificationsAsync(
        int userId);
}
