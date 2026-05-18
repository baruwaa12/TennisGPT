using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.IdentityModel.Tokens;
using TennisGPT.Application.Interfaces;
using TennisGPT.Application.Services;
using TennisGPT.Infrastructure.Data;
using TennisGPT.Infrastructure.External;
using TennisGPT.Infrastructure.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// Database — reads DATABASE_URL (Railway) or falls back to config
string connectionString;
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

if (!string.IsNullOrEmpty(databaseUrl))
{
    connectionString = ConvertPostgresUrl(databaseUrl);
    Console.WriteLine($"[DB] Using DATABASE_URL env var -> Host parsed OK");
}
else
{
    var raw = builder.Configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("No DATABASE_URL or ConnectionStrings:DefaultConnection found.");
    
    if (raw.StartsWith("postgresql://") || raw.StartsWith("postgres://"))
        connectionString = ConvertPostgresUrl(raw);
    else
        connectionString = raw;
    
    Console.WriteLine($"[DB] Using ConnectionStrings:DefaultConnection");
}

builder.Services.AddDbContext<TennisGPTDbContext>(options =>
{
    options.UseNpgsql(connectionString);
});

// Helper: convert postgres:// URL to Npgsql key-value connection string
static string ConvertPostgresUrl(string url)
{
    var uri = new Uri(url);
    var userInfo = uri.UserInfo.Split(':');
    var host = uri.Host;
    var port = uri.Port > 0 ? uri.Port : 5432;
    var database = uri.AbsolutePath.TrimStart('/');
    var username = userInfo[0];
    var password = userInfo.Length > 1 ? userInfo[1] : "";
    
    return $"Host={host};Port={port};Database={database};Username={username};Password={password};Pooling=true;Minimum Pool Size=0;Maximum Pool Size=20";
}

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IMatchRepository, MatchRepository>();
builder.Services.AddScoped<ICheckInRepository, CheckInRepository>();
builder.Services.AddScoped<ISavedEntryRepository, SavedEntryRepository>();
builder.Services.AddScoped<IFounderClaimRepository, FounderClaimRepository>();

// External clients
builder.Services.AddHttpClient<IGoogleAuthClient, GoogleAuthClient>();
builder.Services.AddHttpClient<IAppleAuthClient, AppleAuthClient>();
builder.Services.AddHttpClient<IOpenAIClient, OpenAIClient>();

builder.Services.AddHttpClient("RevenueCat", client =>
{
    client.BaseAddress = new Uri("https://api.revenuecat.com/");
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Application services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOpenAIService, OpenAIService>();
builder.Services.AddScoped<IQuotaService, QuotaService>();
builder.Services.AddScoped<IRevenueCatSubscriptionSyncService, RevenueCatSubscriptionSyncService>();

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("JWT Key not configured");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

builder.Services.AddAuthorization();

// CORS for Flutter app and landing page.
// Allowed origins come from config (Cors:AllowedOrigins) or the CORS_ALLOWED_ORIGINS env var
// (comma-separated). In Development with no allowlist configured, any origin is allowed so
// local browsers/devices keep working.
var corsOriginsConfig =
    Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS")
    ?? builder.Configuration["Cors:AllowedOrigins"]
    ?? string.Empty;

var allowedOrigins = corsOriginsConfig
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    .ToArray();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        }
        else if (builder.Environment.IsDevelopment())
        {
            policy.AllowAnyOrigin()
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        }
        else
        {
            Console.WriteLine("[CORS] WARN: No allowed origins configured for production. Browser clients will be blocked. Set CORS_ALLOWED_ORIGINS or Cors:AllowedOrigins.");
        }
    });
});

var app = builder.Build();

// Apply EF Core migrations on startup.
// Handles three cases safely:
//   1. Fresh DB                                          -> Migrate() creates everything.
//   2. DB previously bootstrapped via EnsureCreated()    -> backfill __EFMigrationsHistory, then Migrate() applies any new migrations.
//   3. DB already on migrations                          -> Migrate() applies pending migrations only.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TennisGPTDbContext>();
    await ApplyMigrationsAsync(db);
}

static async Task ApplyMigrationsAsync(TennisGPTDbContext db)
{
    const string historyTable = "__EFMigrationsHistory";
    var historyTableExists = await TableExistsAsync(db, historyTable);

    if (!historyTableExists && await TableExistsAsync(db, "Users"))
    {
        Console.WriteLine($"[DB] Detected schema without {historyTable}; backfilling history before applying new migrations.");
        var historyRepo = db.GetService<IHistoryRepository>();
        await db.Database.ExecuteSqlRawAsync(historyRepo.GetCreateScript());

        var assembly = db.GetService<IMigrationsAssembly>();
        var efVersion = typeof(DbContext).Assembly.GetName().Version?.ToString() ?? "9.0.0";
        foreach (var migrationId in assembly.Migrations.Keys)
        {
            var insertSql = historyRepo.GetInsertScript(new HistoryRow(migrationId, efVersion));
            await db.Database.ExecuteSqlRawAsync(insertSql);
        }
    }

    await db.Database.MigrateAsync();

    var pending = (await db.Database.GetPendingMigrationsAsync()).ToList();
    Console.WriteLine(pending.Count == 0
        ? "[DB] Migrations up to date."
        : $"[DB] WARN: {pending.Count} pending migration(s) remain after Migrate(): {string.Join(", ", pending)}");
}

static async Task<bool> TableExistsAsync(TennisGPTDbContext db, string tableName)
{
    var conn = db.Database.GetDbConnection();
    if (conn.State != System.Data.ConnectionState.Open)
        await conn.OpenAsync();

    await using var cmd = conn.CreateCommand();
    cmd.CommandText = "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = @name)";
    var p = cmd.CreateParameter();
    p.ParameterName = "@name";
    p.Value = tableName;
    cmd.Parameters.Add(p);
    var result = await cmd.ExecuteScalarAsync();
    return result is bool b && b;
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Skip HTTPS redirect in development (ngrok handles SSL)
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseCors("AllowFlutterApp");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Health check endpoint for Railway (no auth required)
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Run();
