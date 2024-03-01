// Little message from sanco, this will improve over time, I just quickly built this since all the APIs are restricted to specific domains n shit
// since this is a quick implementation for a server to retrieve Youtube data it has a lot to improve and shit
// also this is my first time using express lmao, requires further testing but its already useful enough,
// on newer versions there will be a search bar integrated to import songs automatically but for now the video id is required to be imported

const sharp = require('sharp'); // 0.27.2 is required since my Linux Server doesnt meet the cpu requirements to use SSE4.2
import fs from 'fs';
import express from 'express';
import cors from 'cors';
import ffmpeg from 'ffmpeg';
import ytdl, { videoFormat, videoInfo } from 'ytdl-core';

type ThumbnailObject = 
{
    url:string;
    width:number;
    height:number;
}

type InfoResponse =
{
    videoId:string;
    title:string;
    lengthInSeconds:number;
    author:string;
    thumbnails:ThumbnailObject[];
}

const app = express();
app.use(cors({origin: '*'}));

const port:number = 7654;
const cache:Record<number, videoInfo | null> = [];
const ttl:Record<number, NodeJS.Timeout> = []; // the first is the session id and the other one is the timer handle

const ytBase:string = "https://www.youtube.com/watch?v=";

function resetTTL(sessionID:number)
{
    if (ttl[sessionID])
    {
        clearTimeout(ttl[sessionID]);
        delete ttl[sessionID];
    }

    ttl[sessionID] = setTimeout(() =>
    {
        cache[sessionID] = null;
        delete cache[sessionID];
        delete ttl[sessionID];
    }, 300000);
}

app.get("/", (req, res) =>
{
    res.send("Hello World!");
});

// err code 1: missing query argument
// err code 2: ytdl error
// err code 3: missed ttl
// err code 4: fs error
// err code 69: missing session id
// err code 100: cant use the api

app.get('/video_info', (req, res) =>
{
    // so the session id is used in client side to identify the current session id *duh* and save the data in the server cache
    // so when the user wants to make another operation like download and it doesnt have the necessary fields for ytdl, the server retrieves the sesion id from cache
    // giving the cache a ttl (time to live) of 5min max (for memory reasons)
    // the ttl is a number randomly generated in the client side
    if (req.query.sessionID == undefined)
    {
        // 69 cuz we funny
        res.status(400).send({code: 69, message: "Missing Session ID in query"});
        return;
    }

    if (req.query.id == undefined)
    {
        // lmfao
        res.status(400).send({code: 1, message: "Missing ID in query"});
        return;
    }

    const id:string = req.query.id as string;
    const sessionID:number = Number.parseInt(req.query.sessionID as string);
    ytdl.getInfo(`${ytBase}${id}`).then((info) =>
    {
        cache[sessionID] = info;
        resetTTL(sessionID);

        var ret:InfoResponse = {
            title: info.videoDetails.title,
            author: info.videoDetails.author.name,
            videoId: info.videoDetails.videoId,
            lengthInSeconds: Number.parseFloat(info.videoDetails.lengthSeconds),
            thumbnails: info.videoDetails.thumbnails
        };

        res.status(200).send(ret);
    }).catch((err) =>
    {
        res.status(500).send({code: 2, message: `Failed to get info of video with ID of ${id}`, ytdl_error: err});
        return;
    });
});

app.get("/get_audio", (req, res) =>
{
    // check video_info for more info about sessionID
    if (req.query.sessionID == undefined)
    {
        // 69 cuz we funny
        res.status(400).send({code: 69, message: "Missing Session ID in query"});
        return;
    }

    const sessionID:number = Number.parseInt(req.query.sessionID as string);
    if (!ttl[sessionID])
    {
        res.status(400).send({code: 3, message: 'Missed Cache Time (5 Min Max) or already got audio'});
        return;
    }

    if (cache[sessionID] && cache[sessionID]!.formats != undefined)
    {
        var format:videoFormat = ytdl.chooseFormat(cache[sessionID]!.formats, {quality: 'highestaudio', filter: 'audioonly'});
        var fileName:string = `temp/${sessionID}-${cache[sessionID]!.videoDetails.videoId}.${format.container}`;
        var stream:fs.WriteStream = ytdl.downloadFromInfo(cache[sessionID]!, {quality: 'highestaudio', filter: 'audioonly'}).pipe(fs.createWriteStream(fileName));
        stream.addListener('finish', () =>
        {
            new ffmpeg(fileName).then((r) =>
            {
                r.fnExtractSoundToMP3(fileName.replace("webm", "mp3")).then((rfn) =>
                {
                    try
                    {
                        res.sendFile(rfn, {root: __dirname}, (err) =>
                        {
                            // it means it has finished sending the audio
                            if (err == undefined)
                            {
                                fs.rmSync(fileName);
                                fs.rmSync(rfn);
                            }
                        });
                    }
                    catch (err)
                    {
                        res.status(500).send({error: 4, message: 'FileSystem Error'});
                    }

                    // since the user is done with the data we can just wipe it
                    cache[sessionID] = null;
                    delete cache[sessionID];
                    delete ttl[sessionID];
                });
            });
        });

        return;
    }

    if (cache[sessionID] && cache[sessionID]!.formats == undefined)
    {
        res.status(500).send({code: 2, message: "Missing formats"});
        return;
    }
});

// this doesnt need the session id since we posting the thumbnail we need (cuz the request was made from the server and the origin is the server so the server is allowed to do that freaky thing of requesting)
// send an array of thumbnail sizes n shit for the media session api
app.get("/get_thumbnail", (req, res) =>
{
    const thumbURL:string = req.headers["thumbnail_url"] as string;
    if (thumbURL == undefined)
    {
        res.status(400).send({code: 1, message: "Missing Thumb in body"});
        return;
    }

    const { thumb } = JSON.parse(thumbURL);
    fetch(thumb).then((ures) =>
    {
        ures.arrayBuffer().then((buf) =>
        {
            const buffer:Buffer = Buffer.from(buf);
            const resized = sharp(buffer)
                .resize(512, 512)
                .png();

            var fileName:string = `temp/${crypto.randomUUID()}.png`;
            var stream:fs.WriteStream = resized.pipe(fs.createWriteStream(fileName));

            stream.addListener('finish', () =>
            {
                try
                {
                    res.sendFile(fileName, {root: __dirname}, (err) =>
                    {
                        // it means it has finished sending the audio
                        if (err == undefined)
                        {
                            fs.rmSync(fileName);
                        }
                    });
                }
                catch (err)
                {
                    res.status(500).send({error: 4, message: 'FileSystem Error'});
                }
            });

            return;
        });
    })
});

app.listen(`${port}`, () =>
{
    if (!fs.existsSync("temp/"))
    {
        fs.mkdirSync("temp/");
    }

    console.log(`Server running on http://localhost:${port}`);
});