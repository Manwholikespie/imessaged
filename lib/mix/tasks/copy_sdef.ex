defmodule Mix.Tasks.CopySdef do
  use Mix.Task

  @sdef_path "/System/Applications/Messages.app/Contents/Resources/Messages.sdef"
  @target_path "c_src/Messages.sdef"

  def run(_) do
    File.mkdir_p!("c_src")

    if File.exists?(@sdef_path) do
      File.cp!(@sdef_path, @target_path)
      Mix.shell().info("Successfully copied Messages.sdef to #{@target_path}")
    else
      Mix.raise("Could not find Messages.sdef at #{@sdef_path}")
    end
  end
end
