using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Infrastructure.Data;

public static class IdentitySeeder
{
    public const string AdminRole = "Admin";

    public static async Task SeedAsync(
        IServiceProvider serviceProvider,
        bool isDevelopment)
    {
        using var scope =
            serviceProvider.CreateScope();

        var roleManager =
            scope.ServiceProvider
                .GetRequiredService<
                    RoleManager<
                        IdentityRole<int>>>();

        if (!await roleManager
                .RoleExistsAsync(AdminRole))
        {
            await roleManager.CreateAsync(
                new IdentityRole<int>(
                    AdminRole));
        }

        if (!isDevelopment)
        {
            return;
        }

        var userManager =
            scope.ServiceProvider
                .GetRequiredService<
                    UserManager<User>>();

        var testUser =
            await userManager
                .FindByEmailAsync(
                    "testemail@gmail.com");

        if (testUser != null &&
            !await userManager
                .IsInRoleAsync(
                    testUser,
                    AdminRole))
        {
            await userManager
                .AddToRoleAsync(
                    testUser,
                    AdminRole);
        }
    }
}