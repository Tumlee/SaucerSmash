module magra.sound;

import derelict.sdl2.mixer;

//Volume controls from music and sound. Currently, changing these
//values does not affect currently playing music and sounds.
float musicVolume = 1.0;
float soundVolume = 1.0;

//This flag prevents sound from playing if greater than zero.
//This is useful, for example, when fast forwarding the game
//so that sounds don't play rapidly while this is happening.
private int soundLockLevel = 0;

//==============================================================
//Plays a song. Has no effect if the music passed to it is null.
//==============================================================
void playMusic(Mix_Music* music)
{
    if(music == null)
        return;

    Mix_PlayMusic(music, -1);
}

//==============================================================
//Plays a sound effect with the tiven panning and volume. Has no
//effect if the sound passed to it is null.
//==============================================================
void playSound(Mix_Chunk* sfx, float pan = .5, float volume = 1.0)
{
    if(sfx == null || soundLockLevel > 0)
        return;

    //Play the sound.
    auto channel = Mix_PlayChannel(-1, sfx, 0);
    
    if(channel != -1)    //Do all the channel panning and volume control.
    {
        //Don't let panning fall outside the range of 0.0 - 1.0
        if(pan < 0.0)
            pan = 0.0;
            
        if(pan > 1.0)
            pan = 1.0;
        
        //Mix_SetPanning() takes a left and right channel volume seperately.
        //This math ensures that centered sounds are played at full volume,
        //the left channel fades to zero as it moves to the right, and vice
        //versa.
        float lChan = pan < .5 ? 1.0 : 2.0 * (1.0 - pan);
        float rChan = pan > .5 ? 1.0 : (pan * 2.0);
        
        //Set the volume and panning.
        Mix_Volume(channel, cast(int) (MIX_MAX_VOLUME * volume * soundVolume));
        Mix_SetPanning(channel, cast(ubyte) (255 * lChan), cast(ubyte) (255 * rChan));
    }

    return;    
}

//=================================
//Stops al currently playing music.
//=================================
void stopMusic()
{
    Mix_HaltMusic();
}

//=================================================
//Locks the playing of sound effects. Should always
//be matched with a call to unlockSound()
//=================================================
void lockSound()
{
    soundLockLevel++;
}

//==================
//Unlocks the sound.
//==================
void unlockSound()
{
    soundLockLevel--;
}
