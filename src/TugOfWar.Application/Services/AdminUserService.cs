using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Identity;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class AdminUserService : IAdminUserService
{
    private readonly UserManager<User>
        _userManager;

    public AdminUserService(
        UserManager<User> userManager)
    {
        _userManager =
            userManager;
    }

    public async Task<List<AdminUserResponse>>
        GetUsersAsync()
    {
        var users =
    _userManager
        .Users
        .OrderBy(
            user =>
                user.UserName)
        .ToList();

        var responses =
            new List<AdminUserResponse>();

        foreach (var user in users)
        {
            var isAdmin =
                await _userManager
                    .IsInRoleAsync(
                        user,
                        "Admin");

            responses.Add(
                new AdminUserResponse
                {
                    Id =
                        user.Id,

                    Username =
                        user.UserName ??
                        string.Empty,

                    Email =
                        user.Email ??
                        string.Empty,

                    CoinBalance =
                        user.CoinBalance,

                    Country =
                        user.Country,

                    CreatedAt =
                        user.CreatedAt,

                    LastLoginAt =
                        user.LastLoginAt,

                    IsSuspended =
                        user.IsSuspended,

                    IsAdmin =
                        isAdmin
                });
        }

        return responses;
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

        var user =
            await _userManager
                .FindByIdAsync(
                    userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var isAdmin =
            await _userManager
                .IsInRoleAsync(
                    user,
                    "Admin");

        if (isAdmin)
        {
            throw new InvalidOperationException(
                "Administrator accounts cannot be suspended.");
        }

        if (user.IsSuspended)
        {
            throw new InvalidOperationException(
                "This user is already suspended.");
        }

        user.IsSuspended =
            true;

        var result =
            await _userManager
                .UpdateAsync(
                    user);

        if (!result.Succeeded)
        {
            var errors =
                string.Join(
                    ", ",
                    result.Errors.Select(
                        error =>
                            error.Description));

            throw new InvalidOperationException(
                errors);
        }
    }

    public async Task UnsuspendUserAsync(
        int userId)
    {
        var user =
            await _userManager
                .FindByIdAsync(
                    userId.ToString());

        if (user == null)
        {
            throw new InvalidOperationException(
                "User not found.");
        }

        var isAdmin =
            await _userManager
                .IsInRoleAsync(
                    user,
                    "Admin");

        if (isAdmin)
        {
            throw new InvalidOperationException(
                "Administrator accounts cannot be suspended.");
        }

        if (!user.IsSuspended)
        {
            throw new InvalidOperationException(
                "This user is not suspended.");
        }

        user.IsSuspended =
            false;

        var result =
            await _userManager
                .UpdateAsync(
                    user);

        if (!result.Succeeded)
        {
            var errors =
                string.Join(
                    ", ",
                    result.Errors.Select(
                        error =>
                            error.Description));

            throw new InvalidOperationException(
                errors);
        }
    }
}
