using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TugOfWar.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AllowRepeatedResolvedCommentReports : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CommentReports_CommentId_ReporterUserId",
                table: "CommentReports");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReports_CommentId_ReporterUserId",
                table: "CommentReports",
                columns: new[] { "CommentId", "ReporterUserId" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CommentReports_CommentId_ReporterUserId",
                table: "CommentReports");

            migrationBuilder.CreateIndex(
                name: "IX_CommentReports_CommentId_ReporterUserId",
                table: "CommentReports",
                columns: new[] { "CommentId", "ReporterUserId" },
                unique: true);
        }
    }
}
