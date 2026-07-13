using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Interfaces;

public interface IJwtTokenGenerator
{
    Task<string> GenerateTokenAsync(User user);
}
