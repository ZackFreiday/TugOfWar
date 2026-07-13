using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class AdminUserService : IAdminUserService
{
    private readonly UserManager<User> _userManager;

    public AdminUserService(UserManager<User> userManager)
    {
        _userManager = userManager;
    }

    public async Task SuspendUserAsync(
        int userId,
        int currentAdminId)
    {
        if (userId == currentAdminId)
        {
            throw new InvalidOperationException(
                "You cannot suspend your own account.");
        }

        var user = await _userManager.FindByIdAsync(
            userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        if (user.IsSuspended)
        {
            throw new InvalidOperationException(
                "This user is already suspended.");
        }

        user.IsSuspended = true;

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            var errors = string.Join(
                ", ",
                result.Errors.Select(error => error.Description));

            throw new InvalidOperationException(errors);
        }
    }

    public async Task UnsuspendUserAsync(int userId)
    {
        var user = await _userManager.FindByIdAsync(
            userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException("User not found.");
        }

        if (!user.IsSuspended)
        {
            throw new InvalidOperationException(
                "This user is not suspended.");
        }

        user.IsSuspended = false;

        var result = await _userManager.UpdateAsync(user);

        if (!result.Succeeded)
        {
            var errors = string.Join(
                ", ",
                result.Errors.Select(error => error.Description));

            throw new InvalidOperationException(errors);
        }
    }
}
