class GodsMatchmaking::Help
  include Discord::Plugin

  @[Discord::Handler(
    event: :message_create,
    middleware: Command.new("help")
  )]
  def help(payload, _ctx)
    bot = client.cache.try &.resolve_current_user || raise "Cache unavailable"

    embed             = Discord::Embed.new
    embed.author      = Discord::EmbedAuthor.new(name: bot.username, icon_url: bot.avatar_url)
    embed.title       = "All the commands for God's Matchmaking"

    fields = Array(Discord::EmbedField).new

    fields << Discord::EmbedField.new(
      name: "-join",
      value: "Joins you into the queue of people who are currently looking for partners.\n"\
             "Automatically removes you from the queue when you go offline."
    )
    fields << Discord::EmbedField.new(name: "-leave",   value: "Removes you from the queue.")
    fields << Discord::EmbedField.new(name: "-queue",   value: "Shows all the people currently looking for partners.")
    fields << Discord::EmbedField.new(name: "-matches", value: "Shows you everyone in the queue who can potentially play with you.")
    fields << Discord::EmbedField.new(name: "-info",    value: "Displays some info about the development of this bot.")

    embed.fields = fields
    embed.colour = 0x733430

    client.create_message(payload.channel_id, "", embed)
  end

  @[Discord::Handler(
    event: :ready
  )]
  def set_game(payload)
    # For some reason I need to send this 0, otherwise Discord refuses to update the game.
    client.status_update(game: Discord::GamePlaying.new("God's Trigger | -help", 0.to_i64))
  end
end
