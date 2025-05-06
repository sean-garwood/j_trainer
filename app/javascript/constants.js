// Constants loaded from Rails configuration
export const GAME_SETTINGS = JSON.parse(
  document.getElementById("game-settings-data").textContent
);
export const MAX_RESPONSE_TIME = GAME_SETTINGS.max_response_time;
export const MAX_BUZZ_TIME = GAME_SETTINGS.max_buzz_time;
