using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TennisGPT.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFounderClaims : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FounderClaims",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "TEXT", nullable: false),
                    ClaimedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FounderClaims", x => x.UserId);
                    table.ForeignKey(
                        name: "FK_FounderClaims_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "FounderClaims");
        }
    }
}
