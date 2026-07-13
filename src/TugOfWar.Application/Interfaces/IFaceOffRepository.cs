using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IFaceOffRepository
{
    Task<FaceOff> CreateAsync(FaceOff faceOff);

    Task<List<FaceOff>> GetAllAsync();

    Task<FaceOff?> GetByIdAsync(int id);

    Task SaveChangesAsync();
}
