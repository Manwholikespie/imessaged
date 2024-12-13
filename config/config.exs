import Config

config :imessaged,
  enable_rest_api: true,
  rest_api_port: String.to_integer(System.get_env("PORT", "4000"))

# Conditionally import environment specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
