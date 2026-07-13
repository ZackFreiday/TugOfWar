using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Application.Services;

public class VoteService : IVoteService
{
    private const int DailyVotesRequired = 3;
    private const int DailyRewardCoins = 5;

    private readonly IVoteRepository _voteRepository;
    private readonly IFaceOffRepository _faceOffRepository;

    public VoteService(
        IVoteRepository voteRepository,
        IFaceOffRepository faceOffRepository)
    {
        _voteRepository = voteRepository;
        _faceOffRepository = faceOffRepository;
    }

    public async Task<Vote> SubmitVote(
        int userId,
        int faceOffId,
        SubmitVoteRequest request)
    {
        var faceOff = await _faceOffRepository.GetByIdAsync(faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException("Face-off not found.");
        }

        var now = DateTime.UtcNow;

        if (now < faceOff.StartTime)
        {
            throw new InvalidOperationException("Voting has not started yet.");
        }

        if (now >= faceOff.EndTime)
        {
            throw new InvalidOperationException("Voting has already closed.");
        }

        if (faceOff.Status == FaceOffStatus.Draft ||
            faceOff.Status == FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "This face-off is unavailable.");
        }

        if (!Enum.IsDefined(typeof(ChosenSide), request.ChosenSide))
        {
            throw new InvalidOperationException(
                "Invalid side selection.");
        }

        if (request.CoinBoostSupport < 0 ||
            request.CoinBoostSupport > 50)
        {
            throw new InvalidOperationException(
                "Coin boost must be between 0 and 50.");
        }

        var hasAlreadyVoted =
            await _voteRepository.HasUserVotedAsync(userId, faceOffId);

        if (hasAlreadyVoted)
        {
            throw new InvalidOperationException(
                "User has already voted in this face-off.");
        }

        var user = await _voteRepository.GetUserByIdAsync(userId);

        if (user == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        if (user.CoinBalance < request.CoinBoostSupport)
        {
            throw new InvalidOperationException(
                "You do not have enough Tug Coins.");
        }

        var vote = new Vote
        {
            UserId = userId,
            FaceOffId = faceOffId,
            ChosenSide = request.ChosenSide,
            BaseSupport = 100,
            CoinBoostSupport = request.CoinBoostSupport,
            CreatedAt = now
        };

        CoinTransaction? spentTransaction = null;

        if (request.CoinBoostSupport > 0)
        {
            user.CoinBalance -= request.CoinBoostSupport;

            spentTransaction = new CoinTransaction
            {
                UserId = userId,
                FaceOffId = faceOffId,
                Amount = -request.CoinBoostSupport,
                Type = CoinTransactionType.SpentBoost,
                CreatedAt = now
            };
        }

        var today = DateOnly.FromDateTime(now);

        var votesToday =
            await _voteRepository.CountVotesByUserOnDateAsync(
                userId,
                today);

        var alreadyRewarded =
            await _voteRepository.HasDailyRewardAsync(
                userId,
                today);

        CoinTransaction? rewardTransaction = null;
        DailyReward? dailyReward = null;

        // votesToday does not yet include the vote currently being created.
        var voteCountAfterThisVote = votesToday + 1;

        if (!alreadyRewarded &&
            voteCountAfterThisVote >= DailyVotesRequired)
        {
            user.CoinBalance += DailyRewardCoins;

            rewardTransaction = new CoinTransaction
            {
                UserId = userId,
                FaceOffId = null,
                Amount = DailyRewardCoins,
                Type = CoinTransactionType.EarnedDailyReward,
                CreatedAt = now
            };

            dailyReward = new DailyReward
            {
                UserId = userId,
                RewardDate = today,
                VotesRequired = DailyVotesRequired,
                CoinsAwarded = DailyRewardCoins,
                CreatedAt = now
            };
        }

        return await _voteRepository.CreateWithRewardAsync(
            vote,
            user,
            spentTransaction,
            rewardTransaction,
            dailyReward);
    }
}
