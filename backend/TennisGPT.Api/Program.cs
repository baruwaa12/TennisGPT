using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
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
    options.ConfigureWarnings(w =>
        w.Ignore(RelationalEventId.PendingModelChangesWarning));
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

// External clients
builder.Services.AddHttpClient<IGoogleAuthClient, GoogleAuthClient>();
builder.Services.AddHttpClient<IAppleAuthClient, AppleAuthClient>();
builder.Services.AddHttpClient<IOpenAIClient, OpenAIClient>();

// Application services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOpenAIService, OpenAIService>();
builder.Services.AddScoped<IQuotaService, QuotaService>();

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

// CORS for Flutter app
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Create database schema on startup (fresh Postgres — no migration history needed)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TennisGPTDbContext>();
    db.Database.EnsureCreated();
    Console.WriteLine("[DB] Schema ensured/created successfully");
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

app.Run();
