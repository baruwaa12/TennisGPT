using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TennisGPT.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsCompedField : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsComped",
                table: "Users",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsComped",
                table: "Users");
        }
    }
}

