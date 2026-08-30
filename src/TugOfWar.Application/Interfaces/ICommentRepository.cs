using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface ICommentRepository
{
    Task<Comment> CreateAsync(
        Comment comment);

    Task<List<Comment>> GetByFaceOffIdAsync(
        int faceOffId);

    Task<Comment?> GetByIdAsync(
        int commentId);

    Task<CommentLike?> GetLikeAsync(
        int commentId,
        int userId);

    Task AddLikeAsync(
        CommentLike commentLike);

    Task RemoveLikeAsync(
        CommentLike commentLike);

    Task<int> GetLikeCountAsync(
        int commentId);

    Task SaveChangesAsync();

    Task<int> CountByUserIdAsync(
        int userId);

    Task<List<Comment>> GetByUserIdAsync(
        int userId);

    Task<bool> HasUserReportedCommentAsync(
        int commentId,
        int userId);

    Task<CommentReport> CreateReportAsync(
        CommentReport report);

    Task<List<CommentReport>>
        GetUnresolvedReportsAsync();

    Task<CommentReport?> GetReportByIdAsync(
        int reportId);

    Task<List<CommentReport>>
        GetReportsByCommentIdAsync(
            int commentId);
}
