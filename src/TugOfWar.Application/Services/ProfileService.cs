using Microsoft.AspNetCore.Identity;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class ProfileService : IProfileService
{
    private readonly UserManager<User> _userManager;
    private readonly IVoteRepository _voteRepository;
    private readonly ICommentRepository _commentRepository;
    private readonly IFaceOffRepository _faceOffRepository;
    private readonly ICoinTransactionRepository
        _coinTransactionRepository;

    public ProfileService(
        UserManager<User> userManager,
        IVoteRepository voteRepository,
        ICommentRepository commentRepository,
        IFaceOffRepository faceOffRepository,
        ICoinTransactionRepository coinTransactionRepository)
    {
        _userManager = userManager;
        _voteRepository = voteRepository;
        _commentRepository = commentRepository;
        _faceOffRepository = faceOffRepository;
        _coinTransactionRepository =
            coinTransactionRepository;
    }

    public async Task<ProfileResponse> GetProfileAsync(
        int userId)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var faceOffsParticipated =
            await _voteRepository.CountByUserIdAsync(
                userId);

        var commentsCreated =
            await _commentRepository.CountByUserIdAsync(
                userId);

        var roles =
            await _userManager.GetRolesAsync(user);

        return new ProfileResponse
        {
            Id = user.Id,
            Username =
                user.UserName ?? string.Empty,
            Email =
                user.Email ?? string.Empty,
            ProfileImageUrl =
                user.ProfileImageUrl,
            Bio = user.Bio,
            Country = user.Country,
            CoinBalance = user.CoinBalance,
            CreatedAt = user.CreatedAt,
            FaceOffsParticipated =
                faceOffsParticipated,
            CommentsCreated =
                commentsCreated,
            Roles = roles.ToList()
        };
    }

    public async Task<ProfileResponse> UpdateProfileAsync(
        int userId,
        UpdateProfileRequest request)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var username =
            request.Username.Trim();

        var existingUser =
            await _userManager.FindByNameAsync(
                username);

        if (existingUser != null &&
            existingUser.Id != userId)
        {
            throw new InvalidOperationException(
                "That username is already in use.");
        }

        user.UserName = username;

        user.Bio =
            string.IsNullOrWhiteSpace(
                request.Bio)
                ? null
                : request.Bio.Trim();

        user.Country =
    string.IsNullOrWhiteSpace(
        request.Country)
        ? null
        : request.Country.Trim();

        user.ProfileImageUrl =
            string.IsNullOrWhiteSpace(
                request.ProfileImageUrl)
                ? null
                : request.ProfileImageUrl.Trim();

        var result =
            await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            var errors = string.Join(
                ", ",
                result.Errors.Select(
                    error =>
                        error.Description));

            throw new InvalidOperationException(
                errors);
        }

        return await GetProfileAsync(userId);
    }

    public async Task<ProfileResponse>
    UpdateProfileImageAsync(
        int userId,
        string? profileImageUrl)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        user.ProfileImageUrl =
            string.IsNullOrWhiteSpace(
                profileImageUrl)
                ? null
                : profileImageUrl.Trim();

        var result =
            await _userManager.UpdateAsync(
                user);

        if (!result.Succeeded)
        {
            var errors =
                string.Join(
                    ", ",
                    result.Errors.Select(
                        error =>
                            error.Description));

            throw new InvalidOperationException(
                errors);
        }

        return await GetProfileAsync(
            userId);
    }

    public async Task<List<VoteHistoryResponse>>
        GetVoteHistoryAsync(
            int userId)
    {
        var votes =
            await _voteRepository.GetByUserIdAsync(
                userId);

        var history =
            new List<VoteHistoryResponse>();

        foreach (var vote in votes)
        {
            var faceOff =
                await _faceOffRepository
                    .GetByIdAsync(
                        vote.FaceOffId);

            if (faceOff == null)
            {
                continue;
            }

            history.Add(
                new VoteHistoryResponse
                {
                    FaceOffId =
                        faceOff.Id,

                    FaceOffTitle =
                        faceOff.Title,

                    SideAName =
                        faceOff.SideAName,

                    SideBName =
                        faceOff.SideBName,

                    ChosenSide =
                        (int)vote.ChosenSide,

                    CoinBoostSupport =
                        vote.CoinBoostSupport,

                    VotedAt =
                        vote.CreatedAt,

                    StartTime =
                        faceOff.StartTime,

                    EndTime =
                        faceOff.EndTime,

                    Status =
                        (int)faceOff.Status
                });
        }

        return history;
    }

    public async Task<List<AchievementResponse>>
        GetAchievementsAsync(
            int userId)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

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

        return new List<AchievementResponse>
        {
            new AchievementResponse
            {
                Code = "first_pull",
                Name = "First Pull",
                Description =
                    "Vote in your first face-off.",
                IsUnlocked = voteCount >= 1,
                CurrentProgress =
                    Math.Min(voteCount, 1),
                RequiredProgress = 1
            },

            new AchievementResponse
            {
                Code = "getting_involved",
                Name = "Getting Involved",
                Description =
                    "Participate in 5 face-offs.",
                IsUnlocked = voteCount >= 5,
                CurrentProgress =
                    Math.Min(voteCount, 5),
                RequiredProgress = 5
            },

            new AchievementResponse
            {
                Code = "regular_voter",
                Name = "Regular Voter",
                Description =
                    "Participate in 10 face-offs.",
                IsUnlocked = voteCount >= 10,
                CurrentProgress =
                    Math.Min(voteCount, 10),
                RequiredProgress = 10
            },

            new AchievementResponse
            {
                Code = "dedicated_voter",
                Name = "Dedicated Voter",
                Description =
                    "Participate in 25 face-offs.",
                IsUnlocked = voteCount >= 25,
                CurrentProgress =
                    Math.Min(voteCount, 25),
                RequiredProgress = 25
            },

            new AchievementResponse
            {
                Code = "first_word",
                Name = "First Word",
                Description =
                    "Post your first comment.",
                IsUnlocked = commentCount >= 1,
                CurrentProgress =
                    Math.Min(commentCount, 1),
                RequiredProgress = 1
            },

            new AchievementResponse
            {
                Code = "discussion_starter",
                Name = "Discussion Starter",
                Description =
                    "Post 10 comments.",
                IsUnlocked = commentCount >= 10,
                CurrentProgress =
                    Math.Min(commentCount, 10),
                RequiredProgress = 10
            },

            new AchievementResponse
            {
                Code = "extra_pull",
                Name = "Extra Pull",
                Description =
                    "Use a Tug Coin boost on a vote.",
                IsUnlocked =
                    hasUsedCoinBoost,
                CurrentProgress =
                    hasUsedCoinBoost ? 1 : 0,
                RequiredProgress = 1
            }
        };
    }

    public async Task<DailyProgressResponse>
        GetDailyProgressAsync(
            int userId)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var today =
            DateOnly.FromDateTime(
                DateTime.UtcNow);

        var votesToday =
            await _voteRepository
                .CountVotesByUserOnDateAsync(
                    userId,
                    today);

        var rewardClaimed =
            await _voteRepository
                .HasDailyRewardAsync(
                    userId,
                    today);

        return new DailyProgressResponse
        {
            VotesToday = Math.Min(
                votesToday,
                3),

            VotesRequired = 3,

            RewardCoins = 5,

            RewardClaimed =
                rewardClaimed
        };
    }

    public async Task<
        List<CoinTransactionHistoryResponse>>
        GetCoinTransactionHistoryAsync(
            int userId)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var transactions =
            await _coinTransactionRepository
                .GetByUserIdAsync(
                    userId);

        var history =
            new List<CoinTransactionHistoryResponse>();

        foreach (var transaction in transactions)
        {
            string? faceOffTitle = null;

            if (transaction.FaceOffId.HasValue)
            {
                var faceOff =
                    await _faceOffRepository
                        .GetByIdAsync(
                            transaction.FaceOffId.Value);

                faceOffTitle =
                    faceOff?.Title;
            }

            history.Add(
                new CoinTransactionHistoryResponse
                {
                    Id =
                        transaction.Id,

                    Amount =
                        transaction.Amount,

                    Type =
                        (int)transaction.Type,

                    TypeName =
                        transaction.Type.ToString(),

                    FaceOffId =
                        transaction.FaceOffId,

                    FaceOffTitle =
                        faceOffTitle,

                    CreatedAt =
                        transaction.CreatedAt
                });
        }

        return history;
    }

    public async Task<List<CommentHistoryResponse>>
    GetCommentHistoryAsync(
        int userId)
    {
        var comments =
            await _commentRepository
                .GetByUserIdAsync(
                    userId);

        return comments
            .Select(
                comment =>
                    new CommentHistoryResponse
                    {
                        CommentId =
                            comment.Id,

                        FaceOffId =
                            comment.FaceOffId,

                        FaceOffTitle =
                            comment.FaceOff?.Title ??
                            string.Empty,

                        Content =
                            comment.Content,

                        CreatedAt =
                            comment.CreatedAt,

                        UpdatedAt =
                            comment.UpdatedAt,

                        LikeCount =
                            comment.Likes.Count
                    })
            .ToList();
    }

    public async Task<ProfileResponse>
    RemoveProfileImageAsync(
        int userId)
    {
        var user =
            await _userManager.FindByIdAsync(
                userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        user.ProfileImageUrl = null;

        var result =
            await _userManager.UpdateAsync(
                user);

        if (!result.Succeeded)
        {
            var errors =
                string.Join(
                    ", ",
                    result.Errors.Select(
                        error =>
                            error.Description));

            throw new InvalidOperationException(
                errors);
        }

        return await GetProfileAsync(
            userId);
    }
}
