using System.Text.Json.Serialization;

namespace TennisGPT.Application.DTOs.RevenueCat;

public class RevenueCatWebhookEnvelope
{
    [JsonPropertyName("api_version")]
    public string? ApiVersion { get; set; }

    [JsonPropertyName("event")]
    public RevenueCatWebhookEvent? Event { get; set; }
}

public class RevenueCatWebhookEvent
{
    [JsonPropertyName("type")]
    public string? Type { get; set; }

    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("app_user_id")]
    public string? AppUserId { get; set; }

    [JsonPropertyName("original_app_user_id")]
    public string? OriginalAppUserId { get; set; }

    [JsonPropertyName("aliases")]
    public string[]? Aliases { get; set; }
}
