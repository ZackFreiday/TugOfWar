using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Application.Services;

public class FaceOffService : IFaceOffService
{
    private readonly IFaceOffRepository
        _faceOffRepository;

    private readonly IVoteRepository
        _voteRepository;

    private readonly INotificationRepository
        _notificationRepository;

    private readonly INotificationService
        _notificationService;

    public FaceOffService(
        IFaceOffRepository faceOffRepository,
        IVoteRepository voteRepository,
        INotificationRepository notificationRepository,
        INotificationService notificationService)
    {
        _faceOffRepository =
            faceOffRepository;

        _voteRepository =
            voteRepository;

        _notificationRepository =
            notificationRepository;

        _notificationService =
            notificationService;
    }

    public async Task<FaceOff> CreateFaceOff(
        CreateFaceOffRequest request)
    {
        var now =
            DateTime.UtcNow;

        if (request.EndTime <=
            request.StartTime)
        {
            throw new InvalidOperationException(
                "End time must be later than start time.");
        }

        var status =
            request.StartTime > now
                ? FaceOffStatus.Scheduled
                : request.EndTime <= now
                    ? FaceOffStatus.Closed
                    : FaceOffStatus.Live;

        var faceOff =
            new FaceOff
            {
                Title =
                    request.Title,

                Description =
                    request.Description,

                CategoryId =
                    request.CategoryId,

                SideAName =
                    request.SideAName,

                SideBName =
                    request.SideBName,

                SideAImageUrl =
                    string.IsNullOrWhiteSpace(
                        request.SideAImageUrl)
                        ? null
                        : request
                            .SideAImageUrl
                            .Trim(),

                SideBImageUrl =
                    string.IsNullOrWhiteSpace(
                        request.SideBImageUrl)
                        ? null
                        : request
                            .SideBImageUrl
                            .Trim(),

                StartTime =
                    request.StartTime,

                EndTime =
                    request.EndTime,

                Status =
                    status,

                IsFeatured =
                    request.IsFeatured,

                CreatedAt =
                    now,

                UpdatedAt =
                    now
            };

        var createdFaceOff =
            await _faceOffRepository
                .CreateAsync(
                    faceOff);

        // If the admin creates a face-off that is
        // already live, notify eligible users now.
        //
        // Scheduled face-offs are handled by the
        // lifecycle background service when their
        // StartTime is reached.
        if (createdFaceOff.Status ==
            FaceOffStatus.Live)
        {
            await _notificationService
                .NotifyFaceOffLiveAsync(
                    createdFaceOff);
        }

        return createdFaceOff;
    }

    public async Task<List<FaceOffListResponse>>
        GetFaceOffs(
            bool isAdmin)
    {
        var faceOffs =
            isAdmin
                ? await _faceOffRepository
                    .GetAllAdminAsync()
                : await _faceOffRepository
                    .GetPublicAsync();

        var responses =
            new List<FaceOffListResponse>();

        var now =
            DateTime.UtcNow;

        foreach (var faceOff in faceOffs)
        {
            string? winningSide =
                null;

            bool? isTie =
                null;

            double? sideAPercentage =
                null;

            double? sideBPercentage =
                null;

            var resultsAvailable =
                now >= faceOff.EndTime;

            if (resultsAvailable)
            {
                var votes =
                    await _voteRepository
                        .GetByFaceOffIdAsync(
                            faceOff.Id);

                var sideASupport =
                    votes
                        .Where(
                            vote =>
                                vote.ChosenSide ==
                                ChosenSide.A)
                        .Sum(
                            vote =>
                                vote.BaseSupport +
                                vote.CoinBoostSupport);

                var sideBSupport =
                    votes
                        .Where(
                            vote =>
                                vote.ChosenSide ==
                                ChosenSide.B)
                        .Sum(
                            vote =>
                                vote.BaseSupport +
                                vote.CoinBoostSupport);

                var totalSupport =
                    sideASupport +
                    sideBSupport;

                sideAPercentage =
                    totalSupport == 0
                        ? 0
                        : Math.Round(
                            (double)sideASupport /
                            totalSupport *
                            100,
                            2);

                sideBPercentage =
                    totalSupport == 0
                        ? 0
                        : Math.Round(
                            (double)sideBSupport /
                            totalSupport *
                            100,
                            2);

                isTie =
                    sideASupport ==
                    sideBSupport;

                winningSide =
                    isTie == true
                        ? null
                        : sideASupport >
                            sideBSupport
                            ? ChosenSide.A
                                .ToString()
                            : ChosenSide.B
                                .ToString();
            }

            responses.Add(
                new FaceOffListResponse
                {
                    Id =
                        faceOff.Id,

                    Title =
                        faceOff.Title,

                    Description =
                        faceOff.Description,

                    CategoryId =
                        faceOff.CategoryId,

                    CategoryName =
                        faceOff.Category?.Name,

                    SideAName =
                        faceOff.SideAName,

                    SideBName =
                        faceOff.SideBName,

                    SideAImageUrl =
                        faceOff.SideAImageUrl,

                    SideBImageUrl =
                        faceOff.SideBImageUrl,

                    StartTime =
                        faceOff.StartTime,

                    EndTime =
                        faceOff.EndTime,

                    Status =
                        (int)faceOff.Status,

                    IsFeatured =
                        faceOff.IsFeatured,

                    CreatedAt =
                        faceOff.CreatedAt,

                    UpdatedAt =
                        faceOff.UpdatedAt,

                    WinningSide =
                        winningSide,

                    IsTie =
                        isTie,

                    SideAPercentage =
                        sideAPercentage,

                    SideBPercentage =
                        sideBPercentage
                });
        }

        return responses;
    }

    public async Task<FaceOff?>
        GetFaceOffById(
            int id,
            bool isAdmin)
    {
        if (isAdmin)
        {
            return await _faceOffRepository
                .GetByIdAsync(
                    id);
        }

        return await _faceOffRepository
            .GetPublicByIdAsync(
                id);
    }

    public async Task<FaceOffResultResponse>
        GetResultsAsync(
            int faceOffId,
            int? currentUserId)
    {
        var faceOff =
            await _faceOffRepository
                .GetByIdAsync(
                    faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if (DateTime.UtcNow <
            faceOff.EndTime)
        {
            throw new InvalidOperationException(
                "Results are not available until voting has closed.");
        }

        var votes =
            await _voteRepository
                .GetByFaceOffIdAsync(
                    faceOffId);

        var sideAVotes =
            votes.Count(
                vote =>
                    vote.ChosenSide ==
                    ChosenSide.A);

        var sideBVotes =
            votes.Count(
                vote =>
                    vote.ChosenSide ==
                    ChosenSide.B);

        var sideASupport =
            votes
                .Where(
                    vote =>
                        vote.ChosenSide ==
                        ChosenSide.A)
                .Sum(
                    vote =>
                        vote.BaseSupport +
                        vote.CoinBoostSupport);

        var sideBSupport =
            votes
                .Where(
                    vote =>
                        vote.ChosenSide ==
                        ChosenSide.B)
                .Sum(
                    vote =>
                        vote.BaseSupport +
                        vote.CoinBoostSupport);

        var totalSupport =
            sideASupport +
            sideBSupport;

        var sideAPercentage =
            totalSupport == 0
                ? 0
                : Math.Round(
                    (double)sideASupport /
                    totalSupport *
                    100,
                    2);

        var sideBPercentage =
            totalSupport == 0
                ? 0
                : Math.Round(
                    (double)sideBSupport /
                    totalSupport *
                    100,
                    2);

        var isTie =
            sideASupport ==
            sideBSupport;

        string? winningSide =
            isTie
                ? null
                : sideASupport >
                    sideBSupport
                    ? ChosenSide.A
                        .ToString()
                    : ChosenSide.B
                        .ToString();

        string? userSupportedSide =
            null;

        if (currentUserId.HasValue)
        {
            var userVote =
                votes.FirstOrDefault(
                    vote =>
                        vote.UserId ==
                        currentUserId.Value);

            if (userVote != null)
            {
                userSupportedSide =
                    userVote
                        .ChosenSide
                        .ToString();
            }
        }

        return new FaceOffResultResponse
        {
            FaceOffId =
                faceOff.Id,

            Title =
                faceOff.Title,

            SideAName =
                faceOff.SideAName,

            SideBName =
                faceOff.SideBName,

            SideAVotes =
                sideAVotes,

            SideBVotes =
                sideBVotes,

            SideASupport =
                sideASupport,

            SideBSupport =
                sideBSupport,

            TotalParticipants =
                votes.Count,

            SideAPercentage =
                sideAPercentage,

            SideBPercentage =
                sideBPercentage,

            UserSupportedSide =
                userSupportedSide,

            WinningSide =
                winningSide,

            IsTie =
                isTie
        };
    }

    public async Task<FaceOff>
        UpdateFaceOffAsync(
            int id,
            UpdateFaceOffRequest request)
    {
        var faceOff =
            await _faceOffRepository
                .GetByIdAsync(
                    id);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if (request.EndTime <=
            request.StartTime)
        {
            throw new InvalidOperationException(
                "End time must be later than start time.");
        }

        var hasVotes =
            await _voteRepository
                .FaceOffHasVotesAsync(
                    id);

        if (hasVotes)
        {
            if (faceOff.SideAName !=
                    request.SideAName ||
                faceOff.SideBName !=
                    request.SideBName)
            {
                throw new InvalidOperationException(
                    "Sides cannot be changed after voting has started.");
            }
        }

        var previousStatus =
            faceOff.Status;

        faceOff.SideAImageUrl =
            string.IsNullOrWhiteSpace(
                request.SideAImageUrl)
                ? null
                : request
                    .SideAImageUrl
                    .Trim();

        faceOff.SideBImageUrl =
            string.IsNullOrWhiteSpace(
                request.SideBImageUrl)
                ? null
                : request
                    .SideBImageUrl
                    .Trim();

        faceOff.Title =
            request.Title;

        faceOff.Description =
            request.Description;

        faceOff.CategoryId =
            request.CategoryId;

        if (!hasVotes)
        {
            faceOff.SideAName =
                request.SideAName;

            faceOff.SideBName =
                request.SideBName;
        }

        faceOff.StartTime =
            request.StartTime;

        faceOff.EndTime =
            request.EndTime;

        faceOff.IsFeatured =
            request.IsFeatured;

        var now =
            DateTime.UtcNow;

        faceOff.UpdatedAt =
            now;

        faceOff.Status =
            request.StartTime > now
                ? FaceOffStatus.Scheduled
                : request.EndTime <= now
                    ? FaceOffStatus.Closed
                    : FaceOffStatus.Live;

        await _faceOffRepository
            .SaveChangesAsync();

        // This covers an admin editing a scheduled
        // face-off so that it becomes live immediately.
        if (previousStatus !=
                FaceOffStatus.Live &&
            faceOff.Status ==
                FaceOffStatus.Live)
        {
            await _notificationService
                .NotifyFaceOffLiveAsync(
                    faceOff);
        }

        return faceOff;
    }

    public async Task ArchiveFaceOffAsync(
        int id)
    {
        var faceOff =
            await _faceOffRepository
                .GetByIdAsync(
                    id);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if (faceOff.Status ==
            FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "This face-off is already archived.");
        }

        faceOff.Status =
            FaceOffStatus.Archived;

        faceOff.IsFeatured =
            false;

        faceOff.UpdatedAt =
            DateTime.UtcNow;

        await _faceOffRepository
            .SaveChangesAsync();
    }

    public async Task PermanentlyDeleteFaceOffAsync(
        int id)
    {
        var faceOff =
            await _faceOffRepository
                .GetByIdAsync(
                    id);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if (faceOff.Status !=
            FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "Only archived face-offs can be permanently deleted.");
        }

        await _faceOffRepository
            .PermanentlyDeleteAsync(
                id);
    }

    public async Task CloseFaceOffAsync(
        int id)
    {
        var faceOff =
            await _faceOffRepository
                .GetByIdAsync(
                    id);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if (faceOff.Status ==
            FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "An archived face-off cannot be closed.");
        }

        if (faceOff.Status ==
                FaceOffStatus.Closed ||
            DateTime.UtcNow >=
                faceOff.EndTime)
        {
            throw new InvalidOperationException(
                "This face-off is already closed.");
        }

        var now =
            DateTime.UtcNow;

        faceOff.Status =
            FaceOffStatus.Closed;

        faceOff.EndTime =
            now;

        faceOff.IsFeatured =
            false;

        faceOff.UpdatedAt =
            now;

        var votes =
            await _voteRepository
                .GetByFaceOffIdAsync(
                    id);

        var participantIds =
            votes
                .Select(
                    vote =>
                        vote.UserId)
                .Distinct()
                .ToList();

        var notifications =
            new List<Notification>();

        foreach (var userId
                 in participantIds)
        {
            var alreadyExists =
                await _notificationRepository
                    .ExistsAsync(
                        userId,
                        id,
                        "FaceOffClosed");

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
                        "Face-off ended",

                    Message =
                        $"{faceOff.Title} has ended. View the results.",

                    Type =
                        "FaceOffClosed",

                    FaceOffId =
                        faceOff.Id,

                    IsRead =
                        false,

                    CreatedAt =
                        now
                });
        }

        if (notifications.Count > 0)
        {
            await _notificationRepository
                .CreateManyAsync(
                    notifications);
        }
        else
        {
            await _faceOffRepository
                .SaveChangesAsync();
        }
    }
}
