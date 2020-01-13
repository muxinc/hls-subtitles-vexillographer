# HLS subtitles vexillographer

A simple proxy service which manipulates subtitles flags (AUTOSELECT, FORCED, and DEFAULT) in HLS manifests hosted in Mux Video.

See [Example Usage](#example-usage) for more details.

# Dependencies
* Ruby
* Gems: 
 * sinatra
 * httparty

# Deployment

Development (Starts on port 4567, binds to localhost):

```
ruby proxy.rb
```

Production (Starts on port 80, binds to all interfaces):
```
APP_ENV=production ruby proxy.rb
```

# Example Usage

If you use /tears.m3u8 as the path, we’ll serve you our test Tears of Steel manifest, with a single, English language subtitles track, otherwise, you can put any Mux public playback ID before the .m3u8 in the URL and we'll proxy that and return a version of that manifest with the _first_ subtitles track modified.

http://localhost:4567/tears.m3u8 (DEFAULT, AUTOSELECT and FORCED will be set to "NO")

http://localhost:4567/tears.m3u8?default=YES&autoselect=YES (DEFAULT, AUTOSELECT will be set to "YES". FORCED will be set to "NO")

http://localhost:4567/HDGj01zK01esWsWf9WJj5t5yuXQZJFF6bo.m3u8 (Custom playback ID. DEFAULT, AUTOSELECT and FORCED will be set to "NO")

# License

[MIT](LICENSE)
