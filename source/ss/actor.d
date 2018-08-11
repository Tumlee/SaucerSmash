module ss.ssactor;

public import magra.base;
public import ss.fixcoord;
public import ss.team;

class SSActor : Actor
{
    FixCoord pos;
    FixCoord vel;
    Fix16 radius;
    Team team;
    
    bool isTouching(SSActor other)
    {
        return (pos - other.pos).mag < radius + other.radius;
    }

    bool bounceScreen()
    {
        bool bounced = false;

        if(pos.x > 800 - radius)
        {
            pos.x = 800 - radius;
            vel.x /= -2;
            bounced = true;
        }

        if(pos.x < radius)
        {
            pos.x = radius;
            vel.x /= -2;
            bounced = true;
        }

        if(pos.y > 600 - radius)
        {
            pos.y = 600 - radius;
            vel.y /= -2;
            bounced = true;
        }

        if(pos.y < radius)
        {
            pos.y = radius;
            vel.y /= -2;
            bounced = true;
        }

        return bounced;
    }
    
    void emitSound(Mix_Chunk* sfx, float volume = 1.0)
    {
        playSound(sfx, cast(float)(pos.x / 800), volume);
    }
}
