class GodsMatchmaking::Matchmaking
  include Discord::Plugin

  @[Flags]
  enum Platform
    PC
    Xbox
    Ps4
  end

  @[Flags]
  enum PlayerKind
    Angel
    Demon
  end

  record(Properties, platforms : Platform, player_kind : PlayerKind)

  # User => Roles and platforms
  getter queue = Hash(Discord::Snowflake, Properties).new
  # These are all placeholders until the real values get grabbed.
  getter! angel : Discord::Snowflake
  getter! demon : Discord::Snowflake
  getter! pc    : Discord::Snowflake
  getter! xbox  : Discord::Snowflake
  getter! ps4   : Discord::Snowflake

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("join"),
      GuildChecker.new
    }
  )]
  def join(payload, ctx)
    if queue[payload.author.id]?
      client.create_message(payload.channel_id, "You're already in the queue. If you want to leave, use `-leave`.")
      return
    end

    member = client.get_guild_member(ctx[GuildChecker::Result].id, payload.author.id)
    valid = update_properties(member)

    unless valid
      client.create_message(payload.channel_id, "You need to choose at least one platform to play on.")
      return
    end

    client.create_message(payload.channel_id, "", match_embed(find_matches(member)))
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("leave"),
      GuildChecker.new
    }
  )]
  def leave(payload, ctx)
    if queue[payload.author.id]?
      queue.delete(payload.author.id)
      client.create_message(payload.channel_id, "You have successfully dequeued.")
    else
      client.create_message(payload.channel_id, "You are currently not queued.")
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("matches"),
      GuildChecker.new
    }
  )]
  def post_matches(payload, ctx)
    if queue[payload.author.id]?
      client.create_message(payload.channel_id, "", match_embed(find_matches(payload.author)))
    else
      client.create_message(payload.channel_id, "You need to be in queue to find matches. Use `-join` to queue up.")
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("queue"),
      GuildChecker.new
    }
  )]
  def post_queue(payload, ctx)
    embed = match_embed(queue)

    embed.title       = "Everyone currently in queue."
    embed.description = "Unfortunately, there are currently no players in queue." if queue.empty?

    client.create_message(payload.channel_id, "", embed)
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def fetch_roles(payload)
    # We can do this because the bot is only in one server
    update_roles(payload)
  end

  @[Discord::Handler(
    event: :presence_update
  )]
  def dequeue_on_offline(payload)
    if payload.status == "offline" && queue[payload.user.id]?
      queue.delete(payload.user.id)
    end
  end

  # Update a queued player's status when their roles change.
  # There will be false positives, but that's fine.
  @[Discord::Handler(
    event: :guild_member_update
  )]
  def update_on_change(payload)
    if queue[payload.user.id]?
      update_properties(member = client.get_guild_member(payload.guild_id, payload.user.id))
    end
  end

  # Edgecase of when someone leaves the server while queued
  @[Discord::Handler(
    event: :guild_member_remove
  )]
  def dequeue_on_leave(payload)
    if queue[payload.user.id]?
      queue.delete(payload.user.id)
    end
  end

  private def match_embed(matches : Hash(Discord::Snowflake, Properties))
    client = GodsMatchmaking.bot.client
    cache  = GodsMatchmaking.bot.cache
    embed  = Discord::Embed.new

    embed.title = "All potential co-op partners currently queued."

    if matches.empty?
      embed.description = "Unfortunately, there's currently no player queued that is compatible with you."
      embed.colour = 0xFF0000.to_u32
      return embed
    end

    fields = Array(Discord::EmbedField).new

    matches.each do |match|
      # We only really need the ID. Unfortunately, we can't use match directly, as you can only get
      # things out of a Tuple by ID, not by the symbol.
      match = match[0]

      properties = String.build do |str|
        str << "Plays "

        str << [queue[match].player_kind.angel? ? "**Harry**" : nil, queue[match].player_kind.demon? ? "**Judy**" : nil].compact.join(" and ")
        str << " on "

        if queue[match].platforms.pc? && queue[match].platforms.xbox? && queue[match].platforms.ps4?
          str << "**all platforms**."
        else
          str << [queue[match].platforms.pc? ? "**PC**" : nil, queue[match].platforms.xbox? ? "**Xbox One**" : nil, queue[match].platforms.ps4? ? "**PS4**" : nil].compact.join(" and ") << "."
        end
      end

      fields << Discord::EmbedField.new(
        name: "#{cache.resolve_user(match).username}##{cache.resolve_user(match).discriminator}",
        value: properties
      )
    end

    embed.fields = fields
    embed.colour  = 0x00FF00.to_u32

    embed
  end

  private def find_matches(user : Discord::GuildMember | Discord::User)
    user = user.user if user.is_a?(Discord::GuildMember)

    # Exclude the member itself
    filtered = queue.reject { |m| m == user.id }

    disregard_char = queue[user.id].player_kind.angel? && queue[user.id].player_kind.demon?

    matches = filtered.select do |match|
      matching_platforms  = queue[user.id].platforms.pc?   && queue[match].platforms.pc?   ||
                            queue[user.id].platforms.xbox? && queue[match].platforms.xbox? ||
                            queue[user.id].platforms.ps4?  && queue[match].platforms.ps4?

      matching_characters = disregard_char ||
                            queue[user.id].player_kind.angel? != queue[match].player_kind.angel? ||
                            queue[user.id].player_kind.demon? != queue[match].player_kind.demon?

      matching_platforms && matching_characters
    end

    matches
  end

  private def update_properties(member : Discord::GuildMember)
    player_kind = 0
    player_kind += 1 unless member.roles.find { |r| r == @angel }.nil?
    player_kind += 2 unless member.roles.find { |r| r == @demon }.nil?

    platform = 0
    platform += 1 unless member.roles.find { |r| r == @pc }.nil?
    platform += 2 unless member.roles.find { |r| r == @xbox }.nil?
    platform += 4 unless member.roles.find { |r| r == @ps4 }.nil?

    # At least one platform needs to be chosen
    return false if platform == 0

    # If they chose neither, both will be assumed
    player_kind = 3 if player_kind == 0

    properties = Properties.new(Platform.from_value(platform), PlayerKind.from_value(player_kind))

    queue[member.user.id] = properties

    return true
  end

  private def update_roles(guild)
    client = GodsMatchmaking.bot.client
    roles = guild.roles

    if role = roles.find { |r| r.name.downcase == "angel" }
      @angel = role.id
    else
      @angel = client.create_guild_role(guild_id: guild.id, name: "Angel").id
    end

    if role = roles.find { |r| r.name.downcase == "demon" }
      @demon = role.id
    else
      @demon = client.create_guild_role(guild_id: guild.id, name: "Demon").id
    end

    if role = roles.find { |r| r.name.downcase == "pc" }
      @pc = role.id
    else
      @pc = client.create_guild_role(guild_id: guild.id, name: "PC").id
    end

    if role = roles.find { |r| r.name.downcase == "xbox one" }
      @xbox = role.id
    else
      @xbox = client.create_guild_role(guild_id: guild.id, name: "Xbox One").id
    end

    if role = roles.find { |r| r.name.downcase == "ps4" }
      @ps4 = role.id
    else
      @ps4 = client.create_guild_role(guild_id: guild.id, name: "PS4").id
    end
  end
end
