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

public class CoinTransactionRepository
    : ICoinTransactionRepository
{
    private readonly ApplicationDbContext _context;

    public CoinTransactionRepository(
        ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<CoinTransaction>>
        GetByUserIdAsync(
            int userId)
    {
        return await _context.CoinTransactions
            .AsNoTracking()
            .Where(transaction =>
                transaction.UserId == userId)
            .OrderByDescending(transaction =>
                transaction.CreatedAt)
            .ToListAsync();
    }
}
