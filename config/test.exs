import Mix.Config

config :auth_plug,
  api_key:
    "2PzB7PPnpuLsbWmWtXpGyI+kfSQSQ1zUW2Atz/+8PdZuSEJzHgzGnJWV35nTKRwx/dwylauth.herokuapp.com",
  httpoison_mock: true

config :phoenix, :json_library, Jason
