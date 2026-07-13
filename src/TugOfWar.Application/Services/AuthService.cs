using Microsoft.AspNetCore.Identity;
using TugOfWar.Application.DTOs;
using TugOfWar.Application.Interfaces;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Application.Services;

public class AuthService : IAuthService
{
    private readonly UserManager<User> _userManager;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;

    public AuthService(
        UserManager<User> userManager,
        IJwtTokenGenerator jwtTokenGenerator)
    {
        _userManager = userManager;
        _jwtTokenGenerator = jwtTokenGenerator;
    }

    public async Task<AuthResponse> Register(RegisterRequest request)
    {
        var user = new User
        {
            UserName = request.Username.Trim(),
            Email = request.Email.Trim(),
            CoinBalance = 25,
            CreatedAt = DateTime.UtcNow,
            IsSuspended = false
        };

        var result = await _userManager.CreateAsync(
            user,
            request.Password);

        if (!result.Succeeded)
        {
            var errors = string.Join(
                ", ",
                result.Errors.Select(error => error.Description));

            throw new InvalidOperationException(errors);
        }

        return new AuthResponse
        {
            Token = await _jwtTokenGenerator.GenerateTokenAsync(user),
            UserId = user.Id,
            Username = user.UserName ?? string.Empty,
            CoinBalance = user.CoinBalance
        };
    }

    public async Task<AuthResponse> Login(LoginRequest request)
    {
        var email = request.Email.Trim();

        var user = await _userManager.FindByEmailAsync(email);

        if (user == null)
        {
            throw new InvalidOperationException(
                "Invalid email or password.");
        }

        if (user.IsSuspended)
        {
            throw new UnauthorizedAccessException(
                "This account has been suspended.");
        }

        var passwordValid = await _userManager.CheckPasswordAsync(
            user,
            request.Password);

        if (!passwordValid)
        {
            throw new InvalidOperationException(
                "Invalid email or password.");
        }

        user.LastLoginAt = DateTime.UtcNow;

        var updateResult = await _userManager.UpdateAsync(user);

        if (!updateResult.Succeeded)
        {
            var errors = string.Join(
                ", ",
                updateResult.Errors.Select(error => error.Description));

            throw new InvalidOperationException(errors);
        }

        return new AuthResponse
        {
            Token = await _jwtTokenGenerator.GenerateTokenAsync(user),
            UserId = user.Id,
            Username = user.UserName ?? string.Empty,
            CoinBalance = user.CoinBalance
        };
    }
}
