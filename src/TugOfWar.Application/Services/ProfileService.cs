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

    public ProfileService(
        UserManager<User> userManager,
        IVoteRepository voteRepository,
        ICommentRepository commentRepository)
    {
        _userManager = userManager;
        _voteRepository = voteRepository;
        _commentRepository = commentRepository;
    }

    public async Task<ProfileResponse> GetProfileAsync(int userId)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        var faceOffsParticipated =
            await _voteRepository.CountByUserIdAsync(userId);

        var commentsCreated =
            await _commentRepository.CountByUserIdAsync(userId);

        return new ProfileResponse
        {
            Id = user.Id,
            Username = user.UserName ?? string.Empty,
            Email = user.Email ?? string.Empty,
            ProfileImageUrl = user.ProfileImageUrl,
            Bio = user.Bio,
            Country = user.Country,
            CoinBalance = user.CoinBalance,
            CreatedAt = user.CreatedAt,
            FaceOffsParticipated = faceOffsParticipated,
            CommentsCreated = commentsCreated
        };
    }

    public async Task<ProfileResponse> UpdateProfileAsync(
        int userId,
        UpdateProfileRequest request)
    {
        var user = await _userManager.FindByIdAsync(userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        var username = request.Username.Trim();

        var existingUser =
            await _userManager.FindByNameAsync(username);

        if (existingUser != null && existingUser.Id != userId)
        {
            throw new InvalidOperationException(
                "That username is already in use.");
        }

        user.UserName = username;
        user.Bio = string.IsNullOrWhiteSpace(request.Bio)
            ? null
            : request.Bio.Trim();

        user.Country = string.IsNullOrWhiteSpace(request.Country)
            ? null
            : request.Country.Trim();

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            var errors = string.Join(
                ", ",
                result.Errors.Select(error => error.Description));

            throw new InvalidOperationException(errors);
        }

        return await GetProfileAsync(userId);
    }
}
