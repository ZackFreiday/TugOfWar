using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;

namespace TugOfWar.Application.Interfaces;

public interface ICommentService
{
    Task<CommentResponse> CreateCommentAsync(
        int userId,
        int faceOffId,
        CreateCommentRequest request);

    Task<List<CommentResponse>> GetCommentsAsync(
        int userId,
        int faceOffId);

    Task<CommentResponse> UpdateCommentAsync(
        int userId,
        int commentId,
        UpdateCommentRequest request);

    Task DeleteCommentAsync(
        int userId,
        int commentId);

    Task<CommentResponse> ToggleLikeAsync(
        int userId,
        int commentId);

    Task ReportCommentAsync(
        int userId,
        int commentId,
        ReportCommentRequest request);

    Task<List<CommentReportResponse>>
        GetUnresolvedReportsAsync();

    Task DismissReportAsync(
        int reportId);

    Task DeleteReportedCommentAsync(
        int reportId);
}
