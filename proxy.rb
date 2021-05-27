# coding: utf-8
require 'sinatra'
require 'httparty'
require 'json'

if Sinatra::Base.production?
    set :port, 80
    set :bind, '0.0.0.0'
end

get '/:video.m3u8' do

    # Captions: https://stream.mux.com/HDGj01zK01esWsWf9WJj5t5yuXQZJFF6bo.m3u8
    # Subtitles: https://stream.mux.com/L01T3l4CWmukIZ8Cr1Iq9pG7A8YF2E65z.m3u8

    playback_id = (params['video'].eql? 'tears') ? 'L01T3l4CWmukIZ8Cr1Iq9pG7A8YF2E65z' : params['video']

    autoselect = (params.key?('autoselect')) ? params['autoselect'] : 'NO'
    default = (params.key?('default')) ? params['default'] : 'NO'
    forced = (params.key?('forced')) ? params['forced'] : 'NO'

    puts "playback_id: #{playback_id}"
    puts "autoselect: #{autoselect}"
    puts "default: #{default}"
    puts "forced: #{forced}"

    manifest_response = HTTParty.get("https://stream.mux.com/#{playback_id}.m3u8").response
    manifest_body = manifest_response.body

    # Note: For now these only match the first captions/subs track in the manifest, and the regex is a little lazy.
    manifest_body.sub!(/AUTOSELECT=(YES|NO)/, "AUTOSELECT=#{autoselect}")
    manifest_body.sub!(/DEFAULT=(YES|NO)/, "DEFAULT=#{default}")
    manifest_body.sub!(/FORCED=(YES|NO)/, "FORCED=#{forced}")

    return [manifest_response.code.to_i, {'access-control-allow-origin' => '*', 'content-type' => 'application/x-mpegURL'}, manifest_body]
end

get '/rss/:video.m3u8' do

    playback_id = (params['video'].eql? 'simple') ? 'MO8XTc16a3SOWVg9QOt4rcn7ECnaZFY2' : params['video']

    manifest_response = HTTParty.get("https://stream.mux.com/#{playback_id}.m3u8?redundant_streams=true").response
    manifest_body = manifest_response.body

    lines  = manifest_body.split("\n")
    new_lines = []

    # Please don't judge this implementation. I didn't want to go modify a HLS parser...
    lines.each_with_index do |line, i|

        if line.include?('#EXT-X-INDEPENDENT-SEGMENTS')
            new_lines << line
            new_lines << '#EXT-X-CONTENT-STEERING:SERVER-URI="http://localhost:4567/steering",PATHWAY-ID="FASTLY"'
            next
        end

        if line.include?("TYPE=AUDIO")
            next
        end

        if line.include?("#EXT-X-STREAM-INF")
            new_streaminf = ""

            # Set PATHWAY_ID
            if lines[i+1].include?("cdn=fastly")
                new_streaminf = line.gsub("CLOSED-CAPTIONS=NONE", 'CLOSED-CAPTIONS=NONE,PATHWAY-ID="FASTLY"')
            end
            if lines[i+1].include?("cdn=cloudflare")
                new_streaminf = line.gsub("CLOSED-CAPTIONS=NONE", 'CLOSED-CAPTIONS=NONE,PATHWAY-ID="CLOUDFLARE"')
            end
            if lines[i+1].include?("cdn=highwinds")
                new_streaminf = line.gsub("CLOSED-CAPTIONS=NONE", 'CLOSED-CAPTIONS=NONE,PATHWAY-ID="HIGHWINDS"')
            end

            # Remove AUDIO group
            new_streaminf = new_streaminf.gsub(/AUDIO=\"[\w-]+\",/, "")

            # Remove audio codec from CODECS
            new_streaminf = new_streaminf.gsub(/mp4a(.*?,)/, "")

            new_lines << new_streaminf

            next
        end

        new_lines << line
    end

    new_manifest = new_lines.join("\n")
    return [manifest_response.code.to_i, {'access-control-allow-origin' => '*', 'content-type' => 'application/x-mpegURL'}, new_manifest]
end

get '/steering' do
    r = {'VERSION' => 1, 'TTL' => 10, 'RELOAD-URI' => 'http://localhost:4567/steering', 'PATHWAY-PRIORITY' => ['CLOUDFLARE', 'FASTLY']}
    return [200, {'access-control-allow-origin' => '*', 'content-type' => 'application/x-mpegURL'}, JSON.pretty_generate(r)]
end

not_found do
    '🤷'
end
