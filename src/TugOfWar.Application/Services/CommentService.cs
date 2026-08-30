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
    private readonly IAchievementService _achievementService;

    public CommentService(
        ICommentRepository commentRepository,
        IVoteRepository voteRepository,
        IFaceOffRepository faceOffRepository,
        IAchievementService achievementService)
    {
        _commentRepository = commentRepository;
        _voteRepository = voteRepository;
        _faceOffRepository = faceOffRepository;
        _achievementService = achievementService;
    }

    public async Task<CommentResponse> CreateCommentAsync(
    int userId,
    int faceOffId,
    CreateCommentRequest request)
    {
        var faceOff =
            await _faceOffRepository.GetByIdAsync(
                faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        var now = DateTime.UtcNow;

        var isLive =
            (int)faceOff.Status == 2 &&
            now >= faceOff.StartTime &&
            now < faceOff.EndTime;

        if (isLive)
        {
            var hasVoted =
                await _voteRepository.HasUserVotedAsync(
                    userId,
                    faceOffId);

            if (!hasVoted)
            {
                throw new InvalidOperationException(
                    "You must vote before commenting.");
            }
        }

        var content =
            request.Content.Trim();

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
            await _commentRepository.CreateAsync(
                comment);

        await _achievementService
            .CheckAndUnlockAchievementsAsync(
                userId);

        var savedComment =
            await _commentRepository.GetByIdAsync(
                createdComment.Id);

        if (savedComment == null)
        {
            throw new InvalidOperationException(
                "The comment could not be loaded after creation.");
        }

        return await MapToResponseAsync(
            savedComment,
            userId);
    }

    public async Task<List<CommentResponse>>
    GetCommentsAsync(
        int userId,
        int faceOffId)
    {
        var faceOff =
            await _faceOffRepository.GetByIdAsync(
                faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        var now =
            DateTime.UtcNow;

        var isLive =
            (int)faceOff.Status == 2 &&
            now >= faceOff.StartTime &&
            now < faceOff.EndTime;

        if (isLive)
        {
            var hasVoted =
                await _voteRepository.HasUserVotedAsync(
                    userId,
                    faceOffId);

            if (!hasVoted)
            {
                throw new InvalidOperationException(
                    "You must vote before viewing comments.");
            }
        }

        var comments =
            await _commentRepository
                .GetByFaceOffIdAsync(
                    faceOffId);

        var responses =
            new List<CommentResponse>();

        foreach (var comment in comments)
        {
            responses.Add(
                await MapToResponseAsync(
                    comment,
                    userId));
        }

        return responses;
    }

    public async Task<CommentResponse>
        UpdateCommentAsync(
            int userId,
            int commentId,
            UpdateCommentRequest request)
    {
        var comment =
            await _commentRepository.GetByIdAsync(
                commentId);

        if (comment == null ||
            comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        if (comment.UserId != userId)
        {
            throw new InvalidOperationException(
                "You can only edit your own comments.");
        }

        var content =
            request.Content.Trim();

        ValidateContent(content);

        comment.Content = content;
        comment.UpdatedAt =
            DateTime.UtcNow;

        await _commentRepository
            .SaveChangesAsync();

        return await MapToResponseAsync(
            comment,
            userId);
    }

    public async Task DeleteCommentAsync(
        int userId,
        int commentId)
    {
        var comment =
            await _commentRepository.GetByIdAsync(
                commentId);

        if (comment == null ||
            comment.IsDeleted)
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
        comment.UpdatedAt =
            DateTime.UtcNow;

        await _commentRepository
            .SaveChangesAsync();
    }

    public async Task<CommentResponse>
    ToggleLikeAsync(
        int userId,
        int commentId)
    {
        var comment =
            await _commentRepository.GetByIdAsync(
                commentId);

        if (comment == null ||
            comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        var faceOff =
            await _faceOffRepository.GetByIdAsync(
                comment.FaceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException(
                "Face-off not found.");
        }

        if ((int)faceOff.Status == 4)
        {
            throw new InvalidOperationException(
                "This face-off is unavailable.");
        }

        var now =
            DateTime.UtcNow;

        var isLive =
            (int)faceOff.Status == 2 &&
            now >= faceOff.StartTime &&
            now < faceOff.EndTime;

        if (isLive)
        {
            var hasVoted =
                await _voteRepository.HasUserVotedAsync(
                    userId,
                    comment.FaceOffId);

            if (!hasVoted)
            {
                throw new InvalidOperationException(
                    "You must vote before liking comments.");
            }
        }

        var existingLike =
            await _commentRepository.GetLikeAsync(
                commentId,
                userId);

        if (existingLike == null)
        {
            var commentLike =
                new CommentLike
                {
                    CommentId =
                        commentId,

                    UserId =
                        userId,

                    CreatedAt =
                        DateTime.UtcNow
                };

            await _commentRepository
                .AddLikeAsync(
                    commentLike);
        }
        else
        {
            await _commentRepository
                .RemoveLikeAsync(
                    existingLike);
        }

        var updatedComment =
            await _commentRepository.GetByIdAsync(
                commentId);

        if (updatedComment == null)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        return await MapToResponseAsync(
            updatedComment,
            userId);
    }

    private static void ValidateContent(
        string content)
    {
        if (string.IsNullOrWhiteSpace(
            content))
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

    private async Task<CommentResponse>
    MapToResponseAsync(
        Comment comment,
        int currentUserId)
    {
        var vote =
            await _voteRepository.GetUserVoteAsync(
                comment.UserId,
                comment.FaceOffId);

        return new CommentResponse
        {
            Id = comment.Id,

            FaceOffId =
                comment.FaceOffId,

            UserId =
                comment.UserId,

            Username =
                comment.User?.UserName ??
                string.Empty,

            Content =
                comment.Content,

            CreatedAt =
                comment.CreatedAt,

            UpdatedAt =
                comment.UpdatedAt,

            LikeCount =
                comment.Likes.Count,

            IsLikedByCurrentUser =
                comment.Likes.Any(
                    like =>
                        like.UserId ==
                        currentUserId),

            ChosenSide =
                vote == null
                    ? null
                    : (int)vote.ChosenSide
        };
    }

    public async Task ReportCommentAsync(
    int userId,
    int commentId,
    ReportCommentRequest request)
    {
        var comment =
            await _commentRepository
                .GetByIdAsync(
                    commentId);

        if (comment == null ||
            comment.IsDeleted)
        {
            throw new InvalidOperationException(
                "Comment not found.");
        }

        if (comment.UserId == userId)
        {
            throw new InvalidOperationException(
                "You cannot report your own comment.");
        }

        var reason =
            request.Reason.Trim();

        var allowedReasons =
            new[]
            {
            "Spam",
            "Harassment",
            "Hate or abuse",
            "Inappropriate content",
            "Other"
            };

        if (!allowedReasons.Contains(
            reason))
        {
            throw new InvalidOperationException(
                "Invalid report reason.");
        }

        var alreadyReported =
            await _commentRepository
                .HasUserReportedCommentAsync(
                    commentId,
                    userId);

        if (alreadyReported)
        {
            throw new InvalidOperationException(
                "You have already reported this comment.");
        }

        var report =
            new CommentReport
            {
                CommentId =
                    commentId,

                ReporterUserId =
                    userId,

                Reason =
                    reason,

                CreatedAt =
                    DateTime.UtcNow,

                IsResolved =
                    false
            };

        await _commentRepository
            .CreateReportAsync(
                report);
    }

    public async Task<List<CommentReportResponse>>
    GetUnresolvedReportsAsync()
    {
        var reports =
            await _commentRepository
                .GetUnresolvedReportsAsync();

        return reports
            .Select(report =>
                new CommentReportResponse
                {
                    Id =
                        report.Id,

                    CommentId =
                        report.CommentId,

                    FaceOffId =
                        report.Comment?.FaceOffId ??
                        0,

                    FaceOffTitle =
                        report.Comment?
                            .FaceOff?
                            .Title ??
                        string.Empty,

                    CommentUserId =
                        report.Comment?.UserId ??
                        0,

                    CommentUsername =
                        report.Comment?
                            .User?
                            .UserName ??
                        string.Empty,

                    CommentContent =
                        report.Comment?.Content ??
                        string.Empty,

                    ReporterUserId =
                        report.ReporterUserId,

                    ReporterUsername =
                        report.ReporterUser?
                            .UserName ??
                        string.Empty,

                    Reason =
                        report.Reason,

                    CreatedAt =
                        report.CreatedAt,

                    IsResolved =
                        report.IsResolved
                })
            .ToList();
    }

    public async Task DismissReportAsync(
        int reportId)
    {
        var report =
            await _commentRepository
                .GetReportByIdAsync(
                    reportId);

        if (report == null)
        {
            throw new InvalidOperationException(
                "Comment report not found.");
        }

        if (report.IsResolved)
        {
            throw new InvalidOperationException(
                "This report has already been resolved.");
        }

        report.IsResolved = true;

        await _commentRepository
            .SaveChangesAsync();
    }

    public async Task DeleteReportedCommentAsync(
        int reportId)
    {
        var report =
            await _commentRepository
                .GetReportByIdAsync(
                    reportId);

        if (report == null)
        {
            throw new InvalidOperationException(
                "Comment report not found.");
        }

        if (report.IsResolved)
        {
            throw new InvalidOperationException(
                "This report has already been resolved.");
        }

        var comment =
            report.Comment;

        if (comment == null)
        {
            throw new InvalidOperationException(
                "Reported comment not found.");
        }

        if (!comment.IsDeleted)
        {
            comment.IsDeleted = true;
            comment.UpdatedAt =
                DateTime.UtcNow;
        }

        var reports =
            await _commentRepository
                .GetReportsByCommentIdAsync(
                    comment.Id);

        foreach (var commentReport in reports)
        {
            commentReport.IsResolved =
                true;
        }

        await _commentRepository
            .SaveChangesAsync();
    }
}
