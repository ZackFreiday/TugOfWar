using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class AchievementService
    : IAchievementService
{
    private readonly IVoteRepository _voteRepository;
    private readonly ICommentRepository _commentRepository;
    private readonly IUserAchievementRepository
        _userAchievementRepository;
    private readonly INotificationRepository
        _notificationRepository;

    public AchievementService(
        IVoteRepository voteRepository,
        ICommentRepository commentRepository,
        IUserAchievementRepository userAchievementRepository,
        INotificationRepository notificationRepository)
    {
        _voteRepository = voteRepository;
        _commentRepository = commentRepository;
        _userAchievementRepository =
            userAchievementRepository;
        _notificationRepository =
            notificationRepository;
    }

    public async Task CheckAndUnlockAchievementsAsync(
        int userId)
    {
        var voteCount =
            await _voteRepository.CountByUserIdAsync(
                userId);

        var commentCount =
            await _commentRepository.CountByUserIdAsync(
                userId);

        var hasUsedCoinBoost =
            await _voteRepository
                .HasUserUsedCoinBoostAsync(
                    userId);

        await TryUnlockAsync(
            userId,
            "first_pull",
            "First Pull",
            voteCount >= 1);

        await TryUnlockAsync(
            userId,
            "getting_involved",
            "Getting Involved",
            voteCount >= 5);

        await TryUnlockAsync(
            userId,
            "regular_voter",
            "Regular Voter",
            voteCount >= 10);

        await TryUnlockAsync(
            userId,
            "dedicated_voter",
            "Dedicated Voter",
            voteCount >= 25);

        await TryUnlockAsync(
            userId,
            "first_word",
            "First Word",
            commentCount >= 1);

        await TryUnlockAsync(
            userId,
            "discussion_starter",
            "Discussion Starter",
            commentCount >= 10);

        await TryUnlockAsync(
            userId,
            "extra_pull",
            "Extra Pull",
            hasUsedCoinBoost);
    }

    private async Task TryUnlockAsync(
        int userId,
        string code,
        string name,
        bool condition)
    {
        if (!condition)
        {
            return;
        }

        var alreadyUnlocked =
            await _userAchievementRepository
                .HasUnlockedAsync(
                    userId,
                    code);

        if (alreadyUnlocked)
        {
            return;
        }

        var now = DateTime.UtcNow;

        await _userAchievementRepository
            .CreateAsync(
                new UserAchievement
                {
                    UserId = userId,
                    Code = code,
                    UnlockedAt = now
                });

        await _notificationRepository
            .CreateAsync(
                new Notification
                {
                    UserId = userId,
                    Title =
                        "Achievement unlocked",
                    Message =
                        $"You unlocked: {name}.",
                    Type =
                        "AchievementUnlocked",
                    FaceOffId = null,
                    IsRead = false,
                    CreatedAt = now
                });
    }
}
