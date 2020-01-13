require 'sinatra'
require 'httparty'

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

not_found do
    '🤷'
end
