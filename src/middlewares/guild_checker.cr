# Checks if a command was called in a guild (as opposed to a DM channel.)
class GodsMatchmaking::GuildChecker
  class Result
    getter id : UInt64

    def initialize(@id : UInt64)
    end
  end

  def call (payload, context)
    client = context[Discord::Client]
    guild = client.cache.try &.resolve_channel(payload.channel_id).guild_id
    if guild
      context.put(Result.new(guild.to_u64))
      yield
    else
      client.create_message(payload.channel_id, "This command can only be used in a guild.")
    end
  end
end
