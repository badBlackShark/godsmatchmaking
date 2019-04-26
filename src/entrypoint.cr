require "./gods_matchmaking"

config = GodsMatchmaking::Config.load("./src/config.yml")
GodsMatchmaking.run(config)
sleep
