using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IFaceOffService
{
    Task<FaceOff> CreateFaceOff(
        CreateFaceOffRequest request);

    Task<List<FaceOffListResponse>> GetFaceOffs(
    bool isAdmin);

    Task<FaceOff?> GetFaceOffById(
        int id,
        bool isAdmin);

    Task<FaceOffResultResponse> GetResultsAsync(
        int faceOffId,
        int? currentUserId);

    Task<FaceOff> UpdateFaceOffAsync(
        int id,
        UpdateFaceOffRequest request);

    Task ArchiveFaceOffAsync(
        int id);

    Task CloseFaceOffAsync(
        int id);

    Task PermanentlyDeleteFaceOffAsync(
        int id);
}
