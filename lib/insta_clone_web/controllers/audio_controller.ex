defmodule InstaCloneWeb.AudioController do
  use InstaCloneWeb, :controller

  def upload(conn, %{"audio" => upload}) do
    ext = Path.extname(upload.filename)
    uuid = Ecto.UUID.generate()
    filename = "#{uuid}#{ext}"
    dest_dir = Path.join([:code.priv_dir(:insta_clone), "uploads", "voice_notes"])
    dest = Path.join(dest_dir, filename)

    File.mkdir_p!(dest_dir)
    File.cp!(upload.path, dest)

    url = "/uploads/voice_notes/#{filename}"
    json(conn, %{url: url})
  end
end
