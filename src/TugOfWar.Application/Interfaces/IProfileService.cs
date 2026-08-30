using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;

namespace TugOfWar.Application.Interfaces;

public interface IProfileService
{
    Task<ProfileResponse> GetProfileAsync(
        int userId);

    Task<ProfileResponse> UpdateProfileAsync(
        int userId,
        UpdateProfileRequest request);

    Task<ProfileResponse> UpdateProfileImageAsync(
        int userId,
        string? profileImageUrl);

    Task<List<VoteHistoryResponse>> GetVoteHistoryAsync(
        int userId);

    Task<List<CommentHistoryResponse>> GetCommentHistoryAsync(
        int userId);

    Task<List<AchievementResponse>> GetAchievementsAsync(
        int userId);

    Task<DailyProgressResponse> GetDailyProgressAsync(
        int userId);

    Task<List<CoinTransactionHistoryResponse>>
        GetCoinTransactionHistoryAsync(
            int userId);
    Task<ProfileResponse> RemoveProfileImageAsync(
        int userId);
}
