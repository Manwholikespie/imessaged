defmodule Imessaged.FileCleaner do
  @moduledoc """
  Cleans up old files in the working directory. Must be done manually.
  """

  # TODO: Figure out least annoying way to run this regularly. GenServer?
  require Logger

  @working_dir Path.join([Path.expand("~/Pictures"), "imessaged", "working"])
  # Files older than this will be deleted
  @max_age_days 7

  @doc """
  Removes files from the working directory that are older than @max_age_days
  """
  def cleanup do
    now = DateTime.utc_now()

    files_to_delete =
      File.ls!(@working_dir)
      |> Enum.map(&Path.join(@working_dir, &1))
      |> Enum.filter(&should_delete?(&1, now))

    Enum.each(files_to_delete, fn file ->
      Logger.debug("Deleting old file: #{file}")
      File.rm!(file)
    end)

    if length(files_to_delete) > 0 do
      Logger.info("Cleaned up #{length(files_to_delete)} files from working directory")
    end

    {:ok, length(files_to_delete)}
  end

  defp should_delete?(file_path, now) do
    case File.stat(file_path) do
      {:ok, stat} ->
        # Convert Erlang datetime tuple to DateTime
        {:ok, mtime} = NaiveDateTime.from_erl(stat.mtime)
        mtime = DateTime.from_naive!(mtime, "Etc/UTC")

        diff = DateTime.diff(now, mtime, :day)
        diff > @max_age_days

      {:error, _} ->
        false
    end
  end
end
