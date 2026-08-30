using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TugOfWar.Domain.Entities;

namespace TugOfWar.Infrastructure.Data;

public class ApplicationDbContext
    : IdentityDbContext<User, IdentityRole<int>, int>
{
    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Category> Categories =>
        Set<Category>();

    public DbSet<FaceOff> FaceOffs =>
        Set<FaceOff>();

    public DbSet<Vote> Votes =>
        Set<Vote>();

    public DbSet<CoinTransaction> CoinTransactions =>
        Set<CoinTransaction>();

    public DbSet<Comment> Comments =>
        Set<Comment>();

    public DbSet<CommentLike> CommentLikes =>
        Set<CommentLike>();

    public DbSet<DailyReward> DailyRewards =>
        Set<DailyReward>();

    public DbSet<Notification> Notifications =>
        Set<Notification>();

    public DbSet<UserAchievement> UserAchievements =>
        Set<UserAchievement>();

    public DbSet<CommentReport> CommentReports =>
        Set<CommentReport>();

    protected override void OnModelCreating(
        ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Vote>()
            .HasIndex(v => new
            {
                v.UserId,
                v.FaceOffId
            })
            .IsUnique();

        modelBuilder.Entity<Comment>()
            .Property(c => c.Content)
            .HasMaxLength(1000)
            .IsRequired();

        modelBuilder.Entity<CommentLike>()
            .HasIndex(cl => new
            {
                cl.CommentId,
                cl.UserId
            })
            .IsUnique();

        modelBuilder.Entity<DailyReward>()
            .HasIndex(r => new
            {
                r.UserId,
                r.RewardDate
            })
            .IsUnique();

        modelBuilder.Entity<Notification>()
            .Property(n => n.Title)
            .HasMaxLength(150)
            .IsRequired();

        modelBuilder.Entity<Notification>()
            .Property(n => n.Message)
            .HasMaxLength(500)
            .IsRequired();

        modelBuilder.Entity<Notification>()
            .Property(n => n.Type)
            .HasMaxLength(50)
            .IsRequired();

        modelBuilder.Entity<Notification>()
            .HasIndex(n => new
            {
                n.UserId,
                n.IsRead,
                n.CreatedAt
            });

        modelBuilder.Entity<UserAchievement>()
            .Property(a => a.Code)
            .HasMaxLength(100)
            .IsRequired();

        modelBuilder.Entity<UserAchievement>()
            .HasIndex(a => new
            {
                a.UserId,
                a.Code
            })
            .IsUnique();

        modelBuilder.Entity<CommentReport>()
            .Property(report => report.Reason)
            .HasMaxLength(100)
            .IsRequired();

        modelBuilder.Entity<CommentReport>()
            .HasIndex(report => new
            {
                report.CommentId,
                report.ReporterUserId
            });

        modelBuilder.Entity<Category>()
            .HasData(
                new Category
                {
                    Id = 1,
                    Name = "Sports",
                    Slug = "sports",
                    DisplayOrder = 1,
                    IsActive = true
                },
                new Category
                {
                    Id = 2,
                    Name = "Gaming",
                    Slug = "gaming",
                    DisplayOrder = 2,
                    IsActive = true
                },
                new Category
                {
                    Id = 3,
                    Name = "Entertainment",
                    Slug = "entertainment",
                    DisplayOrder = 3,
                    IsActive = true
                },
                new Category
                {
                    Id = 4,
                    Name = "Technology",
                    Slug = "technology",
                    DisplayOrder = 4,
                    IsActive = true
                },
                new Category
                {
                    Id = 5,
                    Name = "Society",
                    Slug = "society",
                    DisplayOrder = 5,
                    IsActive = true
                },
                new Category
                {
                    Id = 6,
                    Name = "Lifestyle",
                    Slug = "lifestyle",
                    DisplayOrder = 6,
                    IsActive = true
                });
    }
}