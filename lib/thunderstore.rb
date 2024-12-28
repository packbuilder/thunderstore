# frozen_string_literal: true

require_relative "thunderstore/version"
require "faraday"
require "base64"
require "zip"
require "json"

class Thunderstore
  class Error < StandardError; end
  def decode(base64)
    zip_buffer = Base64.decode64(base64)
    export = nil
  
    Tempfile.create do |tempfile|
      tempfile.binmode
      tempfile.write(zip_buffer)
      tempfile.rewind
  
      Zip::File.open(tempfile) do |zip_file|
        export = zip_file.find_entry("export.r2x").get_input_stream.read
      end
    end

    export
  end

  def get_profile(uuid) 
    begin
      response = Faraday.get("https://thunderstore.io/api/experimental/legacyprofile/get/" + uuid, nil, {
        "User-Agent": "packbuilder.io",
        "Content-Type": "application/octet-stream,text/html"
      })
    rescue Faraday::Error => e
      # You can handle errors here (4xx/5xx responses, timeouts, etc.)
      puts e.response[:status]
      puts e.response[:body]
    end
    
    if response.status < 200 || response.status > 299
      puts response.headers.to_json
      raise "Received #{response.status}"
    end

    decode(response.body)
  end
end