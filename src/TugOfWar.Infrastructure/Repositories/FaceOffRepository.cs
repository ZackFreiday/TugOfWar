using Microsoft.EntityFrameworkCore;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Domain.Enums;
using TugOfWar.Infrastructure.Data;

namespace TugOfWar.Infrastructure.Repositories;

public class FaceOffRepository
    : IFaceOffRepository
{
    private readonly ApplicationDbContext _context;

    public FaceOffRepository(
        ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<FaceOff> CreateAsync(
        FaceOff faceOff)
    {
        _context.FaceOffs.Add(
            faceOff);

        await _context.SaveChangesAsync();

        return faceOff;
    }

    public async Task<List<FaceOff>>
        GetPublicAsync()
    {
        return await _context.FaceOffs
            .Include(faceOff =>
                faceOff.Category)
            .Where(faceOff =>
                faceOff.Status ==
                    FaceOffStatus.Live ||
                faceOff.Status ==
                    FaceOffStatus.Closed)
            .OrderByDescending(faceOff =>
                faceOff.IsFeatured)
            .ThenByDescending(faceOff =>
                faceOff.CreatedAt)
            .ToListAsync();
    }

    public async Task<List<FaceOff>>
        GetAllAdminAsync()
    {
        return await _context.FaceOffs
            .Include(faceOff =>
                faceOff.Category)
            .OrderByDescending(faceOff =>
                faceOff.CreatedAt)
            .ToListAsync();
    }

    public async Task<FaceOff?> GetByIdAsync(
        int id)
    {
        return await _context.FaceOffs
            .Include(faceOff =>
                faceOff.Category)
            .FirstOrDefaultAsync(
                faceOff =>
                    faceOff.Id == id);
    }

    public async Task<FaceOff?>
        GetPublicByIdAsync(
            int id)
    {
        return await _context.FaceOffs
            .Include(faceOff =>
                faceOff.Category)
            .FirstOrDefaultAsync(
                faceOff =>
                    faceOff.Id == id &&
                    (
                        faceOff.Status ==
                            FaceOffStatus.Live ||
                        faceOff.Status ==
                            FaceOffStatus.Closed
                    ));
    }

    public async Task PermanentlyDeleteAsync(
        int faceOffId)
    {
        await using var databaseTransaction =
            await _context.Database
                .BeginTransactionAsync();

        await _context.Notifications
            .Where(notification =>
                notification.FaceOffId ==
                    faceOffId)
            .ExecuteDeleteAsync();

        await _context.CoinTransactions
            .Where(transaction =>
                transaction.FaceOffId ==
                    faceOffId)
            .ExecuteUpdateAsync(
                setters =>
                    setters.SetProperty(
                        transaction =>
                            transaction.FaceOffId,
                        (int?)null));

        var commentIds =
            await _context.Comments
                .Where(comment =>
                    comment.FaceOffId ==
                        faceOffId)
                .Select(comment =>
                    comment.Id)
                .ToListAsync();

        if (commentIds.Count > 0)
        {
            await _context.CommentLikes
                .Where(like =>
                    commentIds.Contains(
                        like.CommentId))
                .ExecuteDeleteAsync();
        }

        await _context.Comments
            .Where(comment =>
                comment.FaceOffId ==
                    faceOffId)
            .ExecuteDeleteAsync();

        await _context.Votes
            .Where(vote =>
                vote.FaceOffId ==
                    faceOffId)
            .ExecuteDeleteAsync();

        await _context.FaceOffs
            .Where(faceOff =>
                faceOff.Id ==
                    faceOffId)
            .ExecuteDeleteAsync();

        await databaseTransaction
            .CommitAsync();
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
