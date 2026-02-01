using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TennisGPT.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAppleIdField : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AppleId",
                table: "Users",
                type: "TEXT",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_AppleId",
                table: "Users",
                column: "AppleId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_AppleId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "AppleId",
                table: "Users");
        }
    }
}

