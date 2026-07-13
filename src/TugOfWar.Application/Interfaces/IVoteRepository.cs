using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IVoteRepository
{
    Task<bool> HasUserVotedAsync(int userId, int faceOffId);

    Task<Vote> CreateAsync(Vote vote);

    Task<User?> GetUserByIdAsync(int userId);

    Task<bool> FaceOffHasVotesAsync(int faceOffId);

    Task<Vote> CreateWithCoinTransactionAsync(
        Vote vote,
        User user,
        CoinTransaction? coinTransaction);

    Task<List<Vote>> GetByFaceOffIdAsync(int faceOffId);
    Task<int> CountByUserIdAsync(int userId);
    Task<int> CountVotesByUserOnDateAsync(
    int userId,
    DateOnly date);

    Task<bool> HasDailyRewardAsync(
        int userId,
        DateOnly date);

    Task<Vote> CreateWithRewardAsync(
        Vote vote,
        User user,
        CoinTransaction? spentTransaction,
        CoinTransaction? rewardTransaction,
        DailyReward? dailyReward);
}
