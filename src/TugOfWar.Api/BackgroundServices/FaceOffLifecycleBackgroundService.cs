using Microsoft.EntityFrameworkCore;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Domain.Enums;
using TugOfWar.Infrastructure.Data;

namespace TugOfWar.Api.BackgroundServices;

public class FaceOffLifecycleBackgroundService
    : BackgroundService
{
    private static readonly TimeSpan CheckInterval =
        TimeSpan.FromSeconds(30);

    private static readonly TimeSpan ClosedRetentionPeriod =
        TimeSpan.FromDays(30);

    private readonly IServiceScopeFactory
        _scopeFactory;

    private readonly ILogger<
        FaceOffLifecycleBackgroundService> _logger;

    public FaceOffLifecycleBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<FaceOffLifecycleBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessFaceOffsAsync(
                    stoppingToken);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                _logger.LogError(
                    exception,
                    "An error occurred while processing face-off lifecycle changes.");
            }

            try
            {
                await Task.Delay(
                    CheckInterval,
                    stoppingToken);
            }
            catch (OperationCanceledException)
                when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }
    }

    private async Task ProcessFaceOffsAsync(
        CancellationToken cancellationToken)
    {
        using var scope =
            _scopeFactory.CreateScope();

        var context =
            scope.ServiceProvider
                .GetRequiredService<
                    ApplicationDbContext>();

        var notificationService =
            scope.ServiceProvider
                .GetRequiredService<
                    INotificationService>();

        var now =
            DateTime.UtcNow;

        await ActivateScheduledFaceOffsAsync(
            context,
            notificationService,
            now,
            cancellationToken);

        await CloseExpiredLiveFaceOffsAsync(
            context,
            now,
            cancellationToken);

        await ArchiveExpiredClosedFaceOffsAsync(
            context,
            now,
            cancellationToken);
    }

    private async Task ActivateScheduledFaceOffsAsync(
        ApplicationDbContext context,
        INotificationService notificationService,
        DateTime now,
        CancellationToken cancellationToken)
    {
        var scheduledFaceOffs =
            await context.FaceOffs
                .Where(faceOff =>
                    faceOff.Status ==
                        FaceOffStatus.Scheduled &&
                    faceOff.StartTime <= now)
                .ToListAsync(
                    cancellationToken);

        var newlyLiveFaceOffs =
            new List<FaceOff>();

        foreach (var faceOff
                 in scheduledFaceOffs)
        {
            if (faceOff.EndTime <= now)
            {
                faceOff.Status =
                    FaceOffStatus.Closed;

                faceOff.IsFeatured =
                    false;

                faceOff.UpdatedAt =
                    now;

                continue;
            }

            faceOff.Status =
                FaceOffStatus.Live;

            faceOff.UpdatedAt =
                now;

            newlyLiveFaceOffs.Add(
                faceOff);
        }

        if (scheduledFaceOffs.Count > 0)
        {
            await context.SaveChangesAsync(
                cancellationToken);
        }

        foreach (var faceOff
                 in newlyLiveFaceOffs)
        {
            try
            {
                await notificationService
                    .NotifyFaceOffLiveAsync(
                        faceOff);
            }
            catch (Exception exception)
            {
                _logger.LogError(
                    exception,
                    "Could not create live notifications for face-off {FaceOffId}.",
                    faceOff.Id);
            }
        }
    }

    private static async Task
        CloseExpiredLiveFaceOffsAsync(
            ApplicationDbContext context,
            DateTime now,
            CancellationToken cancellationToken)
    {
        var expiredLiveFaceOffs =
            await context.FaceOffs
                .Where(faceOff =>
                    faceOff.Status ==
                        FaceOffStatus.Live &&
                    faceOff.EndTime <= now)
                .ToListAsync(
                    cancellationToken);

        if (expiredLiveFaceOffs.Count == 0)
        {
            return;
        }

        foreach (var faceOff
                 in expiredLiveFaceOffs)
        {
            faceOff.Status =
                FaceOffStatus.Closed;

            faceOff.IsFeatured =
                false;

            faceOff.UpdatedAt =
                now;
        }

        await context.SaveChangesAsync(
            cancellationToken);
    }

    private async Task
        ArchiveExpiredClosedFaceOffsAsync(
            ApplicationDbContext context,
            DateTime now,
            CancellationToken cancellationToken)
    {
        var archiveCutoff =
            now - ClosedRetentionPeriod;

        var expiredClosedFaceOffs =
            await context.FaceOffs
                .Where(faceOff =>
                    faceOff.Status ==
                        FaceOffStatus.Closed &&
                    faceOff.EndTime <=
                        archiveCutoff)
                .ToListAsync(
                    cancellationToken);

        if (expiredClosedFaceOffs.Count == 0)
        {
            return;
        }

        foreach (var faceOff
                 in expiredClosedFaceOffs)
        {
            faceOff.Status =
                FaceOffStatus.Archived;

            faceOff.IsFeatured =
                false;

            faceOff.UpdatedAt =
                now;

            _logger.LogInformation(
                "Automatically archived closed face-off {FaceOffId} after the retention period.",
                faceOff.Id);
        }

        await context.SaveChangesAsync(
            cancellationToken);
    }
}
