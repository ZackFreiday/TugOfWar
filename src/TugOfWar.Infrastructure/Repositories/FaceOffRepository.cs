using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;
using TugOfWar.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using TugOfWar.Domain.Enums;

namespace TugOfWar.Infrastructure.Repositories;

public class FaceOffRepository : IFaceOffRepository
{
    private readonly ApplicationDbContext _context;

    public FaceOffRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<FaceOff> CreateAsync(FaceOff faceOff)
    {
        _context.FaceOffs.Add(faceOff);
        await _context.SaveChangesAsync();

        return faceOff;
    }

    public async Task<List<FaceOff>> GetAllAsync()
    {
        return await _context.FaceOffs
            .Include(f => f.Category)
            .Where(f => f.Status != FaceOffStatus.Archived)
            .OrderByDescending(f => f.CreatedAt)
            .ToListAsync();
    }

    public async Task<FaceOff?> GetByIdAsync(int id)
    {
        return await _context.FaceOffs
            .Include(f => f.Category)
            .FirstOrDefaultAsync(f => f.Id == id);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}
