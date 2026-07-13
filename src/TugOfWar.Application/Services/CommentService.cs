using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class CommentService : ICommentService
{
    private readonly ICommentRepository _commentRepository;
    private readonly IVoteRepository _voteRepository;
    private readonly IFaceOffRepository _faceOffRepository;

    public CommentService(
        ICommentRepository commentRepository,
        IVoteRepository voteRepository,
        IFaceOffRepository faceOffRepository)
    {
        _commentRepository = commentRepository;
        _voteRepository = voteRepository;
        _faceOffRepository = faceOffRepository;
    }

    public async Task<CommentResponse> CreateCommentAsync(
        int userId,
        int faceOffId,
        CreateCommentRequest request)
    {
        var faceOff =
            await _faceOffRepository.GetByIdAsync(faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        var hasVoted =
            await _voteRepository.HasUserVotedAsync(
                userId,
                faceOffId);

        if (!hasVoted)
        {
            throw new InvalidOperationException(
                "You must vote before commenting.");
        }

        var content = request.Content.Trim();

        ValidateContent(content);

        var comment = new Comment
        {
            FaceOffId = faceOffId,
            UserId = userId,
            Content = content,
            CreatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        var createdComment =
            await _commentRepository.CreateAsync(comment);

        var savedComment =
            await _commentRepository.GetByIdAsync(
                createdComment.Id);

        if (savedComment == null)
        {
            throw new InvalidOperationException(
                "The comment could not be loaded after creation.");
        }

        return MapToResponse(savedComment, userId);
    }

    public async Task<List<CommentResponse>> GetCommentsAsync(
        int userId,
        int faceOffId)
    {
        var faceOff =
            await _faceOffRepository.GetByIdAsync(faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        var hasVoted =
            await _voteRepository.HasUserVotedAsync(
                userId,
                faceOffId);

        if (!hasVoted)
        {
            throw new InvalidOperationException(
                "You must vote before viewing comments.");
        }

        var comments =
            await _commentRepository.GetByFaceOffIdAsync(
                faceOffId);

        return comments
            .Select(comment =>
                MapToResponse(comment, userId))
            .ToList();
    }

    public async Task<CommentResponse> UpdateCommentAsync(
        int userId,
        int commentId,
        UpdateCommentRequest request)
    {
        var comment =
            await _commentRepository.GetByIdAsync(commentId);

        if (comment == null || comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        if (comment.UserId != userId)
        {
            throw new InvalidOperationException(
                "You can only edit your own comments.");
        }

        var content = request.Content.Trim();

        ValidateContent(content);

        comment.Content = content;
        comment.UpdatedAt = DateTime.UtcNow;

        await _commentRepository.SaveChangesAsync();

        return MapToResponse(comment, userId);
    }

    public async Task DeleteCommentAsync(
        int userId,
        int commentId)
    {
        var comment =
            await _commentRepository.GetByIdAsync(commentId);

        if (comment == null || comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        if (comment.UserId != userId)
        {
            throw new InvalidOperationException(
                "You can only delete your own comments.");
        }

        comment.IsDeleted = true;
        comment.UpdatedAt = DateTime.UtcNow;

        await _commentRepository.SaveChangesAsync();
    }

    public async Task<CommentResponse> ToggleLikeAsync(
        int userId,
        int commentId)
    {
        var comment =
            await _commentRepository.GetByIdAsync(commentId);

        if (comment == null || comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        var hasVoted =
            await _voteRepository.HasUserVotedAsync(
                userId,
                comment.FaceOffId);

        if (!hasVoted)
        {
            throw new InvalidOperationException(
                "You must vote before liking comments.");
        }

        var existingLike =
            await _commentRepository.GetLikeAsync(
                commentId,
                userId);

        if (existingLike == null)
        {
            var commentLike = new CommentLike
            {
                CommentId = commentId,
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };

            await _commentRepository.AddLikeAsync(
                commentLike);
        }
        else
        {
            await _commentRepository.RemoveLikeAsync(
                existingLike);
        }

        var updatedComment =
            await _commentRepository.GetByIdAsync(commentId);

        if (updatedComment == null)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        return MapToResponse(updatedComment, userId);
    }

    private static void ValidateContent(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException(
                "Comment cannot be empty.");
        }

        if (content.Length > 1000)
        {
            throw new InvalidOperationException(
                "Comment cannot exceed 1000 characters.");
        }
    }

    private static CommentResponse MapToResponse(
        Comment comment,
        int currentUserId)
    {
        return new CommentResponse
        {
            Id = comment.Id,
            FaceOffId = comment.FaceOffId,
            UserId = comment.UserId,
            Username =
                comment.User?.UserName ?? string.Empty,
            Content = comment.Content,
            CreatedAt = comment.CreatedAt,
            UpdatedAt = comment.UpdatedAt,
            LikeCount = comment.Likes.Count,
            IsLikedByCurrentUser =
                comment.Likes.Any(
                    like => like.UserId == currentUserId)
        };
    }
}
