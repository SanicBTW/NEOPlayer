# legacy_ytapi

This is the legacy Youtube REST API for NEOPlayer

You might want to take a look into the [new API]() instead of this one.

It's pretty basic to keep it simple so lets get into some funky docs!!

# Libraries
- `sharp [0.27.2]` this library is needed to manipulate images, you can find it being used on `/get_thumbnail`.
    - The reason behind choosing `sharp [0.27.2]` is because my host server doesn't have support for SSE4.2, which is required after 0.27.2.
- `express` the classic one, used to serve the whole REST API.
- `cors` a middleware to cors on express, without this the REST API wouldn't work at all lmao
- `ffmpeg` used to convert webm formats to mp3, you can find it being used on `/get_audio`.
    - On the first versions of the API, this wasn't needed since the browser could play webm audios perfectly fine but iOS coulnd't really process webm blobs or sum shit
- `ytdl-core` the goat, the whole youtube functionality comes from this big boi, kind of easy to use lib, I recommend it

Well that's all for the libraries now let's get to work with the routes!

# Routes

`*` = required

- `/` left it there for placeholder lmao
- `/video_info` this is used to get the info of a youtube video through its id, the response is cached (check functionality to know more about this) for 5 min to avoid memory overflow
    - query parameters 
        - sessionID* (check functionality to know more about this), the session id where to save the cache
        - id*, the youtube video id
    - returns a fixed struct with needed fields for NEOPlayer
- `/get_audio` (first call `video_info` to function properly) this is used to get the audio of the youtube video, gets the cache from the previous call to function properly
    - query parameters
        - sessionID*, the session id where to get the cache from
    - returns a mp3 blob (passed a webm through ffmpeg to convert it into mp3)
- `/get_thumbnail` this is used to retrieve an image file through an url, is passed through sharp in order to resize it to fit NEOPlayer (512x512, coould go for more but nah)
    - required headers
        - `thumbnail_url`* the thumbnail url, obviously used for Youtube thumbnails
    - returns a png blob

That's all for the routes, pretty basic as I said, now for the final part, functionality!

# Functionality

Now that we are here, thanks for reading through the documentation of my first REST API, it wasn't that hard but it required some doc reading, anyways, lets finish this off with the most exciting part!

To make the API function properly and avoiding sending huge loads of data back to the client (with unnecessary fields) we save the internal ytdl-core info response on a record with a session ID

The sesion ID is a random integer number generated on the client and passed through the requests of `/video_info` and `/get_audio`, the ones that need the previously saved yt info

The cache has a time-to-live (ttl) of 5 minutes, to avoid having a lot of saved memory, the cache key is the session ID previously passed through one of the get routes

Processed files are saved to the temp folder (which is created on first run) and once the file is saved onto the fs, it gets sent back to the client, this way reducing memory usage and taking advantage of the fs capabilities

# The End ...?

Well that's pretty much what this legacy api has to offer, the reason behind why I changed to a WebSocket server is pretty much Cloudflare itself, if you don't know I'm hosting a Cloudflare Tunnel from my home server that has routes to all my exposed services

Everytime the API was accessed it returned a 502 Bad Gateway error and sometimes it would work without any issue, which is really weird and had to purge the cache every now and then

I got tired of it and I decided to make a WebSocket API for the new services that could lead to easier implementations and more, please look into the new API once you're done reading with this

# The End

If you're hosting your own ytapi server for NEOPlayer, I will add an option to choose between using the Legacy API or the new WebSocket API, both will have downsides but it'll keep the essence from each one of 'em

That's it, see you next time!