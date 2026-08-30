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

public class UserAchievementRepository
    : IUserAchievementRepository
{
    private readonly ApplicationDbContext _context;

    public UserAchievementRepository(
        ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<bool> HasUnlockedAsync(
        int userId,
        string code)
    {
        return await _context.UserAchievements
            .AnyAsync(a =>
                a.UserId == userId &&
                a.Code == code);
    }

    public async Task<UserAchievement> CreateAsync(
        UserAchievement achievement)
    {
        _context.UserAchievements.Add(
            achievement);

        await _context.SaveChangesAsync();

        return achievement;
    }
}
