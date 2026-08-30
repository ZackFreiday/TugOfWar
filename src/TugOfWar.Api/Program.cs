using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using TugOfWar.Api.BackgroundServices;
using TugOfWar.Api.ExceptionHandling;
using TugOfWar.Application.Interfaces;
using TugOfWar.Application.Services;
using TugOfWar.Domain.Entities;
using TugOfWar.Infrastructure.Authentication;
using TugOfWar.Infrastructure.Data;
using TugOfWar.Infrastructure.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "FlutterDevelopment",
        policy =>
        {
            policy
                .AllowAnyOrigin()
                .AllowAnyHeader()
                .AllowAnyMethod();
        });
});

// Database
var connectionString =
    builder.Configuration
        .GetConnectionString(
            "DefaultConnection")
    ?? throw new InvalidOperationException(
        "Database connection string is missing.");

builder.Services.AddDbContext<ApplicationDbContext>(
    options =>
        options.UseNpgsql(
            connectionString));

// ASP.NET Core Identity
builder.Services
    .AddIdentityCore<User>(options =>
    {
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = true;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequiredLength = 8;

        options.User.RequireUniqueEmail = true;
    })
    .AddRoles<IdentityRole<int>>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

// JWT configuration
var jwtSettings =
    builder.Configuration
        .GetSection("Jwt");

var jwtKey =
    jwtSettings["Key"]
    ?? throw new InvalidOperationException(
        "JWT Key is missing.");

var jwtIssuer =
    jwtSettings["Issuer"]
    ?? throw new InvalidOperationException(
        "JWT Issuer is missing.");

var jwtAudience =
    jwtSettings["Audience"]
    ?? throw new InvalidOperationException(
        "JWT Audience is missing.");

builder.Services
    .AddAuthentication(
        JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(
        JwtBearerDefaults.AuthenticationScheme,
        options =>
        {
            options.TokenValidationParameters =
                new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwtIssuer,

                    ValidateAudience = true,
                    ValidAudience = jwtAudience,

                    ValidateLifetime = true,

                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey =
                        new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(
                                jwtKey)),

                    ClockSkew =
                        TimeSpan.Zero
                };

            options.Events =
                new JwtBearerEvents
                {
                    OnTokenValidated =
                        async context =>
                        {
                            var userIdValue =
                                context.Principal?
                                    .FindFirstValue(
                                        ClaimTypes
                                            .NameIdentifier);

                            if (!int.TryParse(
                                userIdValue,
                                out var userId))
                            {
                                context.Fail(
                                    "The authenticated user ID is invalid.");

                                return;
                            }

                            var userManager =
                                context.HttpContext
                                    .RequestServices
                                    .GetRequiredService<
                                        UserManager<User>>();

                            var user =
                                await userManager
                                    .FindByIdAsync(
                                        userId.ToString());

                            if (user == null)
                            {
                                context.Fail(
                                    "The user account no longer exists.");

                                return;
                            }

                            if (user.IsSuspended)
                            {
                                context.Fail(
                                    "This account has been suspended.");
                            }
                        }
                };
        });

builder.Services.AddAuthorization(
    options =>
    {
        options.DefaultPolicy =
            new Microsoft.AspNetCore.Authorization
                .AuthorizationPolicyBuilder(
                    JwtBearerDefaults
                        .AuthenticationScheme)
                .RequireAuthenticatedUser()
                .Build();
    });

// Repositories
builder.Services.AddScoped<
    IFaceOffRepository,
    FaceOffRepository>();

builder.Services.AddScoped<
    IVoteRepository,
    VoteRepository>();

builder.Services.AddScoped<
    ICommentRepository,
    CommentRepository>();

builder.Services.AddScoped<
    ICoinTransactionRepository,
    CoinTransactionRepository>();

builder.Services.AddScoped<
    INotificationRepository,
    NotificationRepository>();

builder.Services.AddScoped<
    IUserAchievementRepository,
    UserAchievementRepository>();

// Application services
builder.Services.AddScoped<
    IFaceOffService,
    FaceOffService>();

builder.Services.AddScoped<
    IVoteService,
    VoteService>();

builder.Services.AddScoped<
    IAuthService,
    AuthService>();

builder.Services.AddScoped<
    ICommentService,
    CommentService>();

builder.Services.AddScoped<
    IProfileService,
    ProfileService>();

builder.Services.AddScoped<
    IAdminUserService,
    AdminUserService>();

builder.Services.AddScoped<
    INotificationService,
    NotificationService>();

builder.Services.AddScoped<
    IAchievementService,
    AchievementService>();

// Infrastructure services
builder.Services.AddScoped<
    IJwtTokenGenerator,
    JwtTokenGenerator>();

// Background services
builder.Services.AddHostedService<
    FaceOffLifecycleBackgroundService>();

// Global exception handling
builder.Services.AddExceptionHandler<
    GlobalExceptionHandler>();

builder.Services.AddProblemDetails();

// Reverse proxy / HTTPS forwarding support
builder.Services.Configure<ForwardedHeadersOptions>(
    options =>
    {
        options.ForwardedHeaders =
            ForwardedHeaders.XForwardedFor |
            ForwardedHeaders.XForwardedProto;
    });

// Swagger
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(
    options =>
    {
        options.SwaggerDoc(
            "v1",
            new OpenApiInfo
            {
                Title = "TugVote API",
                Version = "v1"
            });

        options.AddSecurityDefinition(
            "Bearer",
            new OpenApiSecurityScheme
            {
                Name = "Authorization",
                Description =
                    "Paste the JWT token only. Swagger adds 'Bearer' automatically.",
                In = ParameterLocation.Header,
                Type = SecuritySchemeType.Http,
                Scheme =
                    JwtBearerDefaults
                        .AuthenticationScheme,
                BearerFormat = "JWT"
            });

        options.AddSecurityRequirement(
            new OpenApiSecurityRequirement
            {
                {
                    new OpenApiSecurityScheme
                    {
                        Reference =
                            new OpenApiReference
                            {
                                Type =
                                    ReferenceType
                                        .SecurityScheme,
                                Id = "Bearer"
                            }
                    },
                    Array.Empty<string>()
                }
            });
    });

var app = builder.Build();

app.UseForwardedHeaders();

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();

    app.UseCors(
        "FlutterDevelopment");
}

// Static files
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

await IdentitySeeder.SeedAsync(
    app.Services,
    app.Environment.IsDevelopment());

app.Run();