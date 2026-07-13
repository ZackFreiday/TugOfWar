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

public class CommentRepository : ICommentRepository
{
    private readonly ApplicationDbContext _context;

    public CommentRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Comment> CreateAsync(Comment comment)
    {
        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();

        return comment;
    }

    public async Task<List<Comment>> GetByFaceOffIdAsync(int faceOffId)
    {
        return await _context.Comments
            .Include(c => c.User)
            .Include(c => c.Likes)
            .Where(c =>
                c.FaceOffId == faceOffId &&
                !c.IsDeleted)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();
    }

    public async Task<Comment?> GetByIdAsync(int commentId)
    {
        return await _context.Comments
            .Include(c => c.User)
            .Include(c => c.Likes)
            .FirstOrDefaultAsync(c => c.Id == commentId);
    }

    public async Task<CommentLike?> GetLikeAsync(
        int commentId,
        int userId)
    {
        return await _context.CommentLikes
            .FirstOrDefaultAsync(cl =>
                cl.CommentId == commentId &&
                cl.UserId == userId);
    }

    public async Task AddLikeAsync(CommentLike commentLike)
    {
        _context.CommentLikes.Add(commentLike);
        await _context.SaveChangesAsync();
    }

    public async Task RemoveLikeAsync(CommentLike commentLike)
    {
        _context.CommentLikes.Remove(commentLike);
        await _context.SaveChangesAsync();
    }

    public async Task<int> GetLikeCountAsync(int commentId)
    {
        return await _context.CommentLikes
            .CountAsync(cl => cl.CommentId == commentId);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    public async Task<int> CountByUserIdAsync(int userId)
    {
        return await _context.Comments
            .CountAsync(c => c.UserId == userId && !c.IsDeleted);
    }
}
