defmodule Imessaged.FileManager do
  @moduledoc """
  Manages files that will be sent through iMessage, ensuring they are in the correct location
  and handling cleanup of temporary files.

  This is necessary as Messages.app has restrictions on which directories you can send files from.
  While the logic of allowed directories is not documented, we have confirmed that
  `~/Pictures` is an allowed location.
  """

  @pictures_dir Path.expand("~/Pictures")
  @root_dir Path.join(@pictures_dir, "imessaged")
  @static_dir Path.join(@root_dir, "static")
  @working_dir Path.join(@root_dir, "working")
  # 100MB in bytes
  @max_file_size 100 * 1024 * 1024

  @doc """
  Ensures the file exists in an iMessage-compatible location and returns the proper path.
  Returns error if file doesn't exist or is too large.
  """
  @spec prepare_file(Path.t()) :: {:ok, Path.t()} | {:error, String.t()}
  def prepare_file(file_path) do
    with :ok <- validate_file(file_path),
         :ok <- ensure_directories(),
         {:ok, final_path} <- get_or_copy_file(file_path) do
      {:ok, final_path}
    end
  end

  @doc """
  Creates the necessary directory structure if it doesn't exist.
  """
  def ensure_directories do
    [@root_dir, @static_dir, @working_dir]
    |> Enum.each(&File.mkdir_p!/1)

    :ok
  end

  @doc """
  Validates that the file exists and is within size limits.
  """
  def validate_file(file_path) do
    cond do
      not File.exists?(file_path) ->
        {:error, "File does not exist"}

      File.stat!(file_path).size > @max_file_size ->
        {:error, "File is larger than 100MB"}

      true ->
        :ok
    end
  end

  defp get_or_copy_file(file_path) do
    # If file is already in Pictures directory, use it directly
    if String.starts_with?(file_path, @pictures_dir) do
      {:ok, file_path}
    else
      # Otherwise, copy to working directory with hash name
      copy_to_working_dir(file_path)
    end
  end

  defp copy_to_working_dir(file_path) do
    hash = Imessaged.Utils.hash_file(file_path)
    ext = Path.extname(file_path)
    new_path = Path.join(@working_dir, hash <> ext)

    if not File.exists?(new_path) do
      File.cp!(file_path, new_path)
    end

    {:ok, new_path}
  end
end
