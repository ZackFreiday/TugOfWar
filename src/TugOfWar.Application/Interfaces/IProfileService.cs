using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;

namespace TugOfWar.Application.Interfaces;

public interface IProfileService
{
    Task<ProfileResponse> GetProfileAsync(int userId);

    Task<ProfileResponse> UpdateProfileAsync(
        int userId,
        UpdateProfileRequest request);
}
