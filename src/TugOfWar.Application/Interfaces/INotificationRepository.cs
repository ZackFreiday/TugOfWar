using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface INotificationRepository
{
    Task<List<Notification>> GetByUserIdAsync(
        int userId);

    Task<Notification?> GetByIdAsync(
        int notificationId);

    Task<Notification> CreateAsync(
        Notification notification);

    Task CreateManyAsync(
        IEnumerable<Notification> notifications);

    Task<bool> ExistsAsync(
        int userId,
        int faceOffId,
        string type);

    Task<List<int>> GetEligibleLiveFaceOffUserIdsAsync(
        int faceOffId);

    Task DeleteAsync(
        Notification notification);

    Task DeleteAllByUserIdAsync(
        int userId);

    Task SaveChangesAsync();
}
