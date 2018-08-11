module ss.gamerecorder;

import magra.base;

import ss.playersaucer;
import ss.resources;
import ss.gamestate;

import std.exception;
import std.random;

import std.stdio;

import ss.fix16;

enum RecorderState
{
    playing,
    recording
}

void writeDatum(T)(File file, T datum)
{
    ubyte[T.sizeof] buffer;

    foreach(i; 0 .. T.sizeof)
    {
        auto shift = (T.sizeof - (i + 1)) * 8;
        buffer[i] = cast(ubyte) ((datum & (0xff << shift)) >> shift);
    }

    file.rawWrite(buffer);
}

//NOTE: Unexpected EOF should throw an error.
T readDatum(T)(File file)
{
    ubyte[T.sizeof] buffer;
    
    auto readBytes = file.rawRead(buffer);

    if(readBytes.length < T.sizeof)
        throw new Exception("Unexpected end of file");

    T retVal = 0;

    foreach(i; 0 .. T.sizeof)
    {
        auto shift = (T.sizeof - (i + 1)) * 8;
        retVal |= readBytes[i] << shift;
    }

    return retVal;
}

class GameRecorder
{
    PlayerPoll[] polls;
    int[] randoms;
    RecorderState state;
    
    int enemyTeam;
    int playerTeam;
    
    int randomPos;
    int pollPos;
    
    GameRecorder dup()
    {
        auto newRecorder = new GameRecorder;
        newRecorder.polls ~= polls;
        newRecorder.randoms ~= randoms;
        newRecorder.playerTeam = playerTeam;
        newRecorder.enemyTeam = enemyTeam;
        
        return newRecorder;
    }
    
    int uniform(int low, int high)
    {
        if(state == RecorderState.playing)
        {
            enforce(randomPos < randoms.length, "Replay error: Random stream too small");
            enforce(randoms[randomPos] >= low, "Replay error: Random value outside expected range.");  
            enforce(randoms[randomPos] < high, "Replay error: Random value outside expected range.");
            
            return randoms[randomPos++];
        }
        else
        {
            auto randVal = .uniform(low, high);
            
            if(state == RecorderState.recording)
                randoms ~= randVal;
                
            return randVal;
        }    
    }
    
    void setState(RecorderState newState)
    {
        state = newState;
        randomPos = 0;
        pollPos = 0;
        
        if(state == RecorderState.recording)
        {
            polls.length = 0;
            randoms.length = 0;
        }
    }
    
    PlayerPoll getPoll(lazy PlayerPoll poller)
    {
        if(state == RecorderState.playing)
        {  
            if(pollPos >= polls.length)
                setGameState(GameState.over);
            
            return polls[pollPos++];
        }
        else
        {
            if(state == RecorderState.recording)
                polls ~= poller;
                
            return poller;
        }
    }
    
    bool hasData()
    {
        return polls.length != 0;
    }

    //The SSR file format:
    bool save(string fileName)
    {
        File file;        

        try
        {
            file = File(fileName, "wb");
        }
        catch(std.exception.ErrnoException)
        {
            return false;
        }

        file.write("SSR");
        file.writeDatum(3);
        file.writeDatum(playerTeam);
        file.writeDatum(enemyTeam);
        file.writeDatum(cast(ulong) polls.length);
        file.writeDatum(cast(ulong) randoms.length);

        foreach(poll; polls)
        {
            file.writeDatum(poll.speed.x.literal);
            file.writeDatum(poll.speed.y.literal);

            file.writeDatum(cast(ubyte) poll.firing);

            if(poll.firing)
                file.writeDatum(poll.fireAngle.literal);
        }

        foreach(random; randoms)
            file.writeDatum(random);

        file.close();

        return true;
    }

    void load(string fileName)
    {
        polls.length = 0;
        randoms.length = 0;
    
        File file;
    
        try
        {
            file = File(fileName, "rb");
        }
        catch(std.exception.ErrnoException)
        {
            throw new Exception("Unable to open file for reading.");
        }
        
        scope(exit)
            file.close();
            
        //If there is an error, the loaded data all needs to be cleared out.
        scope(failure)
        {
            polls.length = 0;
            randoms.length = 0;
        }
        
        char[3] signature;

        foreach(ref element; signature)
            element = file.readDatum!char;

        if(signature != ['S', 'S', 'R'])
            throw new Exception("File has no SSR signature");

        int ssrVersion = file.readDatum!int;

        if(ssrVersion != 3)
            throw new Exception("Replay is from the wrong version of SaucerSmash.");

        playerTeam = file.readDatum!int;
        enemyTeam = file.readDatum!int;
        
        if(playerTeam < 0 || playerTeam >= teams.length)
            throw new Exception("Invalid player team number.");
            
        if(enemyTeam < 0 || enemyTeam >= teams.length)
            throw new Exception("Invalid enemy team number.");
        
        auto numPolls = file.readDatum!ulong;
        auto numRands = file.readDatum!ulong;

        foreach(p; 0 .. numPolls)
        {
            PlayerPoll poll;
            
            poll.speed.x = fixLiteral(file.readDatum!int);
            poll.speed.y = fixLiteral(file.readDatum!int);

            poll.firing = cast(bool) file.readDatum!ubyte;

            if(poll.firing)
                poll.fireAngle = fixLiteral(file.readDatum!int);
                
            polls ~= poll;
        }

        foreach(r; 0 .. numRands)
            randoms ~= file.readDatum!int;
    }
}
