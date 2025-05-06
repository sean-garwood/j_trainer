module JTrainer
  GAME_SETTINGS = YAML.load_file(Rails.root.join("config", "game_settings.yml"), aliases: true)[Rails.env]
end
