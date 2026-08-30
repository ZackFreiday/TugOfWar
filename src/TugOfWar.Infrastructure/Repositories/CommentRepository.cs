using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Infrastructure.Data;

namespace TugOfWar.Infrastructure.Repositories;

public class CommentRepository
    : ICommentRepository
{
    private readonly ApplicationDbContext _context;

    public CommentRepository(
        ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Comment> CreateAsync(
        Comment comment)
    {
        _context.Comments.Add(
            comment);

        await _context.SaveChangesAsync();

        return comment;
    }

    public async Task<List<Comment>>
        GetByFaceOffIdAsync(
            int faceOffId)
    {
        return await _context.Comments
            .Include(comment =>
                comment.User)
            .Include(comment =>
                comment.Likes)
            .Where(comment =>
                comment.FaceOffId ==
                    faceOffId &&
                !comment.IsDeleted)
            .OrderByDescending(comment =>
                comment.CreatedAt)
            .ToListAsync();
    }

    public async Task<Comment?> GetByIdAsync(
        int commentId)
    {
        return await _context.Comments
            .Include(comment =>
                comment.User)
            .Include(comment =>
                comment.Likes)
            .Include(comment =>
                comment.FaceOff)
            .FirstOrDefaultAsync(
                comment =>
                    comment.Id ==
                    commentId);
    }

    public async Task<CommentLike?> GetLikeAsync(
        int commentId,
        int userId)
    {
        return await _context.CommentLikes
            .FirstOrDefaultAsync(
                like =>
                    like.CommentId ==
                        commentId &&
                    like.UserId ==
                        userId);
    }

    public async Task AddLikeAsync(
        CommentLike commentLike)
    {
        _context.CommentLikes.Add(
            commentLike);

        await _context.SaveChangesAsync();
    }

    public async Task RemoveLikeAsync(
        CommentLike commentLike)
    {
        _context.CommentLikes.Remove(
            commentLike);

        await _context.SaveChangesAsync();
    }

    public async Task<int> GetLikeCountAsync(
        int commentId)
    {
        return await _context.CommentLikes
            .CountAsync(
                like =>
                    like.CommentId ==
                    commentId);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    public async Task<int> CountByUserIdAsync(
        int userId)
    {
        return await _context.Comments
            .CountAsync(
                comment =>
                    comment.UserId ==
                        userId &&
                    !comment.IsDeleted);
    }

    public async Task<List<Comment>>
        GetByUserIdAsync(
            int userId)
    {
        return await _context.Comments
            .Include(comment =>
                comment.FaceOff)
            .Include(comment =>
                comment.Likes)
            .Where(comment =>
                comment.UserId ==
                    userId &&
                !comment.IsDeleted)
            .OrderByDescending(comment =>
                comment.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool>
    HasUserReportedCommentAsync(
        int commentId,
        int userId)
    {
        return await _context.CommentReports
            .AnyAsync(
                report =>
                    report.CommentId ==
                        commentId &&
                    report.ReporterUserId ==
                        userId &&
                    !report.IsResolved);
    }

    public async Task<CommentReport>
        CreateReportAsync(
            CommentReport report)
    {
        _context.CommentReports.Add(
            report);

        await _context.SaveChangesAsync();

        return report;
    }

    public async Task<List<CommentReport>>
        GetUnresolvedReportsAsync()
    {
        return await _context.CommentReports
            .Include(report =>
                report.ReporterUser)
            .Include(report =>
                report.Comment)
                .ThenInclude(comment =>
                    comment!.User)
            .Include(report =>
                report.Comment)
                .ThenInclude(comment =>
                    comment!.FaceOff)
            .Where(report =>
                !report.IsResolved)
            .OrderByDescending(report =>
                report.CreatedAt)
            .ToListAsync();
    }

    public async Task<CommentReport?>
        GetReportByIdAsync(
            int reportId)
    {
        return await _context.CommentReports
            .Include(report =>
                report.ReporterUser)
            .Include(report =>
                report.Comment)
                .ThenInclude(comment =>
                    comment!.User)
            .Include(report =>
                report.Comment)
                .ThenInclude(comment =>
                    comment!.FaceOff)
            .FirstOrDefaultAsync(
                report =>
                    report.Id ==
                    reportId);
    }

    public async Task<List<CommentReport>>
        GetReportsByCommentIdAsync(
            int commentId)
    {
        return await _context.CommentReports
            .Where(report =>
                report.CommentId ==
                    commentId)
            .ToListAsync();
    }
}
