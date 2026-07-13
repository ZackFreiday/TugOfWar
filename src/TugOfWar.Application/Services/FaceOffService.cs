using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Application.Services;

public class FaceOffService : IFaceOffService
{
    private readonly IFaceOffRepository _faceOffRepository;
    private readonly IVoteRepository _voteRepository;

    public FaceOffService(
        IFaceOffRepository faceOffRepository,
        IVoteRepository voteRepository)
    {
        _faceOffRepository = faceOffRepository;
        _voteRepository = voteRepository;
    }

    public async Task<FaceOff> CreateFaceOff(CreateFaceOffRequest request)
    {
        var now = DateTime.UtcNow;

        if (request.EndTime <= request.StartTime)
        {
            throw new InvalidOperationException(
                "End time must be later than start time.");
        }

        var status = request.StartTime > now
            ? FaceOffStatus.Scheduled
            : request.EndTime <= now
                ? FaceOffStatus.Closed
                : FaceOffStatus.Live;

        var faceOff = new FaceOff
        {
            Title = request.Title,
            Description = request.Description,
            CategoryId = request.CategoryId,
            SideAName = request.SideAName,
            SideBName = request.SideBName,
            StartTime = request.StartTime,
            EndTime = request.EndTime,
            Status = status,
            CreatedAt = now,
            UpdatedAt = now
        };

        return await _faceOffRepository.CreateAsync(faceOff);
    }

    public async Task<List<FaceOff>> GetFaceOffs()
    {
        return await _faceOffRepository.GetAllAsync();
    }

    public async Task<FaceOff?> GetFaceOffById(int id)
    {
        return await _faceOffRepository.GetByIdAsync(id);
    }

    public async Task<FaceOffResultResponse> GetResultsAsync(
        int faceOffId,
        int? currentUserId)
    {
        var faceOff = await _faceOffRepository.GetByIdAsync(faceOffId);

        if (faceOff == null)
        {
            throw new InvalidOperationException("Face-off not found.");
        }

        if (DateTime.UtcNow < faceOff.EndTime)
        {
            throw new InvalidOperationException(
                "Results are not available until voting has closed.");
        }

        var votes = await _voteRepository.GetByFaceOffIdAsync(faceOffId);

        var sideAVotes = votes.Count(v => v.ChosenSide == ChosenSide.A);
        var sideBVotes = votes.Count(v => v.ChosenSide == ChosenSide.B);

        var sideASupport = votes
            .Where(v => v.ChosenSide == ChosenSide.A)
            .Sum(v => v.BaseSupport + v.CoinBoostSupport);

        var sideBSupport = votes
            .Where(v => v.ChosenSide == ChosenSide.B)
            .Sum(v => v.BaseSupport + v.CoinBoostSupport);

        var totalSupport = sideASupport + sideBSupport;

        var sideAPercentage = totalSupport == 0
            ? 0
            : Math.Round(
                (double)sideASupport / totalSupport * 100,
                2);

        var sideBPercentage = totalSupport == 0
            ? 0
            : Math.Round(
                (double)sideBSupport / totalSupport * 100,
                2);

        string? userSupportedSide = null;

        if (currentUserId.HasValue)
        {
            var userVote = votes.FirstOrDefault(
                v => v.UserId == currentUserId.Value);

            if (userVote != null)
            {
                userSupportedSide = userVote.ChosenSide.ToString();
            }
        }

        return new FaceOffResultResponse
        {
            FaceOffId = faceOff.Id,
            Title = faceOff.Title,
            SideAName = faceOff.SideAName,
            SideBName = faceOff.SideBName,
            SideAVotes = sideAVotes,
            SideBVotes = sideBVotes,
            SideASupport = sideASupport,
            SideBSupport = sideBSupport,
            TotalParticipants = votes.Count,
            SideAPercentage = sideAPercentage,
            SideBPercentage = sideBPercentage,
            UserSupportedSide = userSupportedSide
        };
    }

    public async Task<FaceOff> UpdateFaceOffAsync(
    int id,
    UpdateFaceOffRequest request)
    {
        var faceOff = await _faceOffRepository.GetByIdAsync(id);

        if (faceOff == null)
        {
            throw new InvalidOperationException("Face-off not found.");
        }

        if (request.EndTime <= request.StartTime)
        {
            throw new InvalidOperationException(
                "End time must be later than start time.");
        }

        var hasVotes =
            await _voteRepository.FaceOffHasVotesAsync(id);

        if (hasVotes)
        {
            if (faceOff.SideAName != request.SideAName ||
                faceOff.SideBName != request.SideBName)
            {
                throw new InvalidOperationException(
                    "Sides cannot be changed after voting has started.");
            }
        }

        faceOff.Title = request.Title;
        faceOff.Description = request.Description;
        faceOff.CategoryId = request.CategoryId;

        if (!hasVotes)
        {
            faceOff.SideAName = request.SideAName;
            faceOff.SideBName = request.SideBName;
        }

        faceOff.StartTime = request.StartTime;
        faceOff.EndTime = request.EndTime;
        faceOff.IsFeatured = request.IsFeatured;
        faceOff.UpdatedAt = DateTime.UtcNow;

        var now = DateTime.UtcNow;

        faceOff.Status = request.StartTime > now
            ? FaceOffStatus.Scheduled
            : request.EndTime <= now
                ? FaceOffStatus.Closed
                : FaceOffStatus.Live;

        await _faceOffRepository.SaveChangesAsync();

        return faceOff;
    }

    public async Task ArchiveFaceOffAsync(int id)
    {
        var faceOff = await _faceOffRepository.GetByIdAsync(id);

        if (faceOff == null)
        {
            throw new InvalidOperationException("Face-off not found.");
        }

        if (faceOff.Status == FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "This face-off is already archived.");
        }

        faceOff.Status = FaceOffStatus.Archived;
        faceOff.IsFeatured = false;
        faceOff.UpdatedAt = DateTime.UtcNow;

        await _faceOffRepository.SaveChangesAsync();
    }

    public async Task CloseFaceOffAsync(int id)
    {
        var faceOff = await _faceOffRepository.GetByIdAsync(id);

        if (faceOff == null)
        {
            throw new InvalidOperationException("Face-off not found.");
        }

        if (faceOff.Status == FaceOffStatus.Archived)
        {
            throw new InvalidOperationException(
                "An archived face-off cannot be closed.");
        }

        if (faceOff.Status == FaceOffStatus.Closed ||
            DateTime.UtcNow >= faceOff.EndTime)
        {
            throw new InvalidOperationException(
                "This face-off is already closed.");
        }

        var now = DateTime.UtcNow;

        faceOff.Status = FaceOffStatus.Closed;
        faceOff.EndTime = now;
        faceOff.IsFeatured = false;
        faceOff.UpdatedAt = now;

        await _faceOffRepository.SaveChangesAsync();
    }
}
