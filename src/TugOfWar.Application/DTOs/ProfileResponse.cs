namespace TugOfWar.Application.DTOs;

public class ProfileResponse
{
    public int Id { get; set; }

    public string Username { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string? ProfileImageUrl { get; set; }

    public int CoinBalance { get; set; }

    public DateTime CreatedAt { get; set; }

    public int FaceOffsParticipated { get; set; }

    public int CommentsCreated { get; set; }

    public string? Bio { get; set; }

    public string? Country { get; set; }

    public List<string> Roles { get; set; } = [];
}
