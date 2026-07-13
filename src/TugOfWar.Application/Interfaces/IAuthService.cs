using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TugOfWar.Application.DTOs;

namespace TugOfWar.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> Register(RegisterRequest request);

    Task<AuthResponse> Login(LoginRequest request);
}
