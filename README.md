# HandleContinueBlogpost

This code is used in conjunction with a blogpost I wrote about handle_continue in Elixir.  You can read it here for more information.

The four examples are each a self-contained application.  To run them, change the `mod:` in the [mix.exs](mix.exs) file to the application you want to run, and then run with `mix run --no-halt`.

The [.tool-versions](.tool-versions) file is for [ASDF](https://github.com/asdf-vm/asdf), which I use for version management of my Elixir apps.  The `handle_continue` functionality was introduced in OTP 21, and for this repo I used Elixir 1.6 along with Erlang 21.1.

If you are looking for the proper way to do asynchronous initaliztion, skip right to [application_handle_continue.ex](https://github.com/TylerPachal/handle_continue_blogpost/blob/master/lib/handle_continue_blogpost/application_handle_continue.ex)
