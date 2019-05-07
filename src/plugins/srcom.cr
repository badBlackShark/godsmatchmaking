require "tasker"

class GodsMatchmaking::Srcom
  include Discord::Plugin

  getter api      : SrcomApi
  getter runs     : Array(Run)
  getter! channel : Discord::Snowflake

  def initialize
    @api  = SrcomApi.new("kdkz2mgd")
    @runs = JSON.parse(@api.get_runs.body)["data"].as_a.map { |raw| Run.from_json(raw) }
    request_loop
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: Command.new("allRuns")
  )]
  def allRuns(payload, ctx)
    @runs.each do |run|
      client.create_message(payload.channel_id, "", run.to_embed)
    end
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def ensure_speedrun_channel(payload)
    # We can do this because the bot is only in one server
    @channel = (client.get_guild_channels(guild_id: payload.id).find { |c| c.name.try(&.downcase) == "speedrunning" } ||
               client.create_guild_channel(guild_id: payload.id, name: "speedrunning", type: Discord::ChannelType::GuildText, bitrate: nil, user_limit: nil)).id
  end

  def request_loop
    Tasker.instance.every() do
      all_runs = JSON.parse(@api.get_runs.body)["data"].as_a.map { |raw| Run.from_json(raw) }
      all_runs.reject { |run| !@runs.find { |r| r.id == run.id && r.status == run.status }.nil? }.each do |new_run|
        # For some reason the `getter!` wasn't enough, needs another `not_nil!`
        client.create_message(@channel.not_nil!, "", new_run.to_embed)
      end
      @runs = all_runs
    end
  end
end
