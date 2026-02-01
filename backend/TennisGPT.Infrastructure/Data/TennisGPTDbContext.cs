using Microsoft.EntityFrameworkCore;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Infrastructure.Data;

public class TennisGPTDbContext : DbContext
{
    public TennisGPTDbContext(DbContextOptions<TennisGPTDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<CheckIn> CheckIns => Set<CheckIn>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.GoogleId).IsUnique();
            entity.HasIndex(e => e.Email);

            entity.Property(e => e.GoogleId).IsRequired();
            entity.Property(e => e.Email).IsRequired();
            
            // Plan stored as int
            entity.Property(e => e.Plan)
                .HasConversion<int>()
                .HasDefaultValue(UserPlan.Free);
            
            entity.Property(e => e.OnboardingCompleted).HasDefaultValue(false);
            entity.Property(e => e.TacticalUsedPeriod).HasDefaultValue(0);
            entity.Property(e => e.IsComped).HasDefaultValue(false);
        });

        // Match configuration
        modelBuilder.Entity<Match>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.Date).IsDescending();

            entity.Property(e => e.Opponent).IsRequired();
            entity.Property(e => e.Result).IsRequired();
            entity.Property(e => e.Surface).IsRequired();

            entity.HasOne(e => e.User)
                .WithMany(u => u.Matches)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // CheckIn configuration
        modelBuilder.Entity<CheckIn>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.UserId);
            entity.HasIndex(e => e.Timestamp).IsDescending();

            entity.Property(e => e.JournalText).IsRequired();

            entity.HasOne(e => e.User)
                .WithMany(u => u.CheckIns)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
