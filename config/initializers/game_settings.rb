module JTrainer
  GAME_SETTINGS = YAML.load_file(Rails.root.join("config", "game_settings.yml"), aliases: true)[Rails.env]

  MAX_RESPONSE_TIME = GAME_SETTINGS["max_response_time"]
  MAX_BUZZ_TIME = GAME_SETTINGS["max_buzz_time"]
  MAX_RESPONSE_TIME_IN_MILLISECONDS = MAX_RESPONSE_TIME * 1000
  MAX_BUZZ_TIME_IN_MILLISECONDS = MAX_BUZZ_TIME * 1000
end
