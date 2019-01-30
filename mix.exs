defmodule HandleContinueBlogpost.MixProject do
  use Mix.Project

  def project do
    [
      app: :handle_continue_blogpost,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],

      # To run the different applications, uncomment the corresponding mod line here
      mod: {HandleContinueBlogpost.ApplicationHandleContinue, []}
      # mod: {HandleContinueBlogpost.ApplicationSlowSync, []}
      # mod: {HandleContinueBlogpost.ApplicationSendSelf, []}
      # mod: {HandleContinueBlogpost.ApplicationSendSelfRace, []}
    ]
  end

  defp deps do
    []
  end
end
