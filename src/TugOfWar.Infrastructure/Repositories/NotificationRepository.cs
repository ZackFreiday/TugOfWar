using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Infrastructure.Data;

namespace TugOfWar.Infrastructure.Repositories;

public class NotificationRepository
    : INotificationRepository
{
    private readonly ApplicationDbContext _context;

    public NotificationRepository(
        ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<Notification>>
        GetByUserIdAsync(
            int userId)
    {
        return await _context.Notifications
            .Where(notification =>
                notification.UserId == userId)
            .OrderByDescending(notification =>
                notification.CreatedAt)
            .ToListAsync();
    }

    public async Task<Notification?> GetByIdAsync(
        int notificationId)
    {
        return await _context.Notifications
            .FirstOrDefaultAsync(
                notification =>
                    notification.Id ==
                    notificationId);
    }

    public async Task<Notification> CreateAsync(
        Notification notification)
    {
        _context.Notifications.Add(
            notification);

        await _context.SaveChangesAsync();

        return notification;
    }

    public async Task CreateManyAsync(
        IEnumerable<Notification> notifications)
    {
        _context.Notifications.AddRange(
            notifications);

        await _context.SaveChangesAsync();
    }

    public async Task<bool> ExistsAsync(
        int userId,
        int faceOffId,
        string type)
    {
        return await _context.Notifications
            .AnyAsync(notification =>
                notification.UserId == userId &&
                notification.FaceOffId == faceOffId &&
                notification.Type == type);
    }

    public async Task<List<int>>
        GetEligibleLiveFaceOffUserIdsAsync(
            int faceOffId)
    {
        return await _context.Users
            .Where(user =>
                !user.IsSuspended &&
                !_context.Votes.Any(vote =>
                    vote.UserId == user.Id &&
                    vote.FaceOffId == faceOffId))
            .Select(user =>
                user.Id)
            .ToListAsync();
    }

    public async Task DeleteAsync(
        Notification notification)
    {
        _context.Notifications.Remove(
            notification);

        await _context.SaveChangesAsync();
    }

    public async Task DeleteAllByUserIdAsync(
        int userId)
    {
        await _context.Notifications
            .Where(notification =>
                notification.UserId == userId)
            .ExecuteDeleteAsync();
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
