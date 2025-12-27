# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files
COPY TennisGPT.sln .
COPY TennisGPT.Api/TennisGPT.Api.csproj TennisGPT.Api/
COPY TennisGPT.Application/TennisGPT.Application.csproj TennisGPT.Application/
COPY TennisGPT.Domain/TennisGPT.Domain.csproj TennisGPT.Domain/
COPY TennisGPT.Infrastructure/TennisGPT.Infrastructure.csproj TennisGPT.Infrastructure/

# Restore dependencies
RUN dotnet restore

# Copy everything else and build
COPY . .
RUN dotnet publish TennisGPT.Api/TennisGPT.Api.csproj -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app

# Create directory for SQLite database
RUN mkdir -p /app/data

COPY --from=build /app/publish .

# Railway uses PORT environment variable
ENV ASPNETCORE_URLS=http://+:${PORT:-8080}
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080

ENTRYPOINT ["dotnet", "TennisGPT.Api.dll"]

