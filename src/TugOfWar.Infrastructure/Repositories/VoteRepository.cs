using Microsoft.EntityFrameworkCore;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Infrastructure.Data;

namespace TugOfWar.Infrastructure.Repositories;

public class VoteRepository : IVoteRepository
{
    private readonly ApplicationDbContext _context;

    public VoteRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<bool> HasUserVotedAsync(int userId, int faceOffId)
    {
        return await _context.Votes
            .AnyAsync(v => v.UserId == userId && v.FaceOffId == faceOffId);
    }

    public async Task<Vote> CreateAsync(Vote vote)
    {
        _context.Votes.Add(vote);
        await _context.SaveChangesAsync();

        return vote;
    }

    public async Task<User?> GetUserByIdAsync(int userId)
    {
        return await _context.Users
            .FirstOrDefaultAsync(u => u.Id == userId);
    }

    public async Task<Vote> CreateWithCoinTransactionAsync(
        Vote vote,
        User user,
        CoinTransaction? coinTransaction)
    {
        _context.Votes.Add(vote);
        _context.Users.Update(user);

        if (coinTransaction != null)
        {
            _context.CoinTransactions.Add(coinTransaction);
        }

        await _context.SaveChangesAsync();

        return vote;
    }

    public async Task<List<Vote>> GetByFaceOffIdAsync(int faceOffId)
    {
        return await _context.Votes
            .Where(v => v.FaceOffId == faceOffId)
            .ToListAsync();
    }

    public async Task<int> CountByUserIdAsync(int userId)
    {
        return await _context.Votes
            .CountAsync(v => v.UserId == userId);
    }

    public async Task<int> CountVotesByUserOnDateAsync(
    int userId,
    DateOnly date)
    {
        var start = date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);
        var end = date.AddDays(1).ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc);

        return await _context.Votes
            .Where(v =>
                v.UserId == userId &&
                v.CreatedAt >= start &&
                v.CreatedAt < end)
            .Select(v => v.FaceOffId)
            .Distinct()
            .CountAsync();
    }

    public async Task<bool> HasDailyRewardAsync(
        int userId,
        DateOnly date)
    {
        return await _context.DailyRewards
            .AnyAsync(r =>
                r.UserId == userId &&
                r.RewardDate == date);
    }

    public async Task<Vote> CreateWithRewardAsync(
        Vote vote,
        User user,
        CoinTransaction? spentTransaction,
        CoinTransaction? rewardTransaction,
        DailyReward? dailyReward)
    {
        _context.Votes.Add(vote);
        _context.Users.Update(user);

        if (spentTransaction != null)
        {
            _context.CoinTransactions.Add(spentTransaction);
        }

        if (rewardTransaction != null)
        {
            _context.CoinTransactions.Add(rewardTransaction);
        }

        if (dailyReward != null)
        {
            _context.DailyRewards.Add(dailyReward);
        }

        await _context.SaveChangesAsync();

        return vote;
    }

    public async Task<bool> FaceOffHasVotesAsync(int faceOffId)
    {
        return await _context.Votes
            .AnyAsync(v => v.FaceOffId == faceOffId);
    }
}
