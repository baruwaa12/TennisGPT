using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TennisGPT.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserQuotaFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Plan",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "OnboardingCompleted",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "TacticalUsedPeriod",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "TacticalPeriodStart",
                table: "Users",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Plan",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "OnboardingCompleted",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TacticalUsedPeriod",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TacticalPeriodStart",
                table: "Users");
        }
    }
}

