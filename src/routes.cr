require "kemal"
require "./helpers"

module Gazou
  get "/" do |env|
    send_file(env, "public/index.html")
  end

  get "/images/:filename" do |env|
    filename = env.params.url["filename"]
    filepath = File.join(["images", filename])
    
    if !File.exists?(filepath)
      env.response.status_code = 404
      next
    end

    send_file(env, filepath)
  end

  post "/api/upload" do |env|
    filepath = ""

    HTTP::FormData.parse(env.request) do |upload|
      # The image data stream has to be copied since upload.body can only be
      # read once.
      data = IO::Memory.new
      IO.copy(upload.body, data)
      data.rewind

      checksum = Helpers.get_checksum(data)

      if image = Image.find_by(checksum: checksum)
        filepath = File.join("images", image.filename)
      else
        filename = Helpers.randomize_filename(upload.filename.to_s)
        filepath = File.join("images", filename)

        Image.create!(filename: filename, checksum: checksum)

        File.open(filepath, "w") do |f|
          IO.copy(data, f)
        end
      end
    end

    filepath
  end
end
