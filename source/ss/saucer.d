module ss.saucer;

public import ss.ssactor;
import magra.extras.graphics;
import ss.trail;
import std.random;
import ss.resources;
import ss.graphics;
import ss.trail;

class Saucer : SSActor
{
    int shotTimer = 0;
    int stallTimer = 0;
    bool overdrive = false;
    Fix16 damage = 0;
    
    Fix16 rotation = 0;
    Fix16 rotationDelta = iu!6;

    this()
    {
        radius = 12;
    }

    void addStall(int amount)
    {
        stallTimer += amount;

        if(stallTimer > 120)
            stallTimer = 120;
    }

    void explode()
    {
        for(Fix16 a = 0; a < Fix16.pi * 2; a += fu!4096)
        {
            Fix16 percent = fixLiteral(uniform(0, 65536));

            Fix16 exMag = iu!1 + (percent * iu!3);
            actors.spawn(new Trail(team, pos, vel + polarCoord(exMag, a), 40 + uniform(0, 15), true));
        }

        emitSound(sfxExplosion);
    }

    void rotate()
    {
        auto targetRot = iu!6;
        
        if(stallTimer)
            targetRot = iu!0;
            
        if(overdrive)
            targetRot = iu!12;
        
        rotationDelta = (rotationDelta * ff!(97, 100)) + (targetRot * ff!(3, 100));

        rotation += rotationDelta;
    }
    
    Fix16 aimThrust(FixCoord target)
    {
        auto targetAngle = (target - pos).ang;

        if(vel.mag == 0)
            return targetAngle;

        auto angleDiff = vel.ang - targetAngle;

        if(angleDiff.abs > Fix16.pi / 2)
            return targetAngle;

        return targetAngle - angleDiff;
    }
    
    void drawSaucer()
    {
        solidLayer.add(new FCSprite(team.texSaucer[!stallTimer], pos, cast(float) rotation));
    }
    
    void makeTrail()
    {
        Fix16 percent1 = fixLiteral(uniform(0, 65536));
        Fix16 exMag1 = percent1 * ff!(1,5);
        Fix16 percent2 = fixLiteral(uniform(0, 65536));
        Fix16 exMag2 = percent2 * ff!(1,5);
        Fix16 randAngle1 = fixLiteral(uniform(0,65536)) * Fix16.pi * 2;
        Fix16 randAngle2 = fixLiteral(uniform(0,65536)) * Fix16.pi * 2;
    
        actors.spawn(new Trail(team, pos, polarCoord(exMag1, randAngle1), overdrive ? 20 : 10));

        if(overdrive)
            actors.spawn(new Trail(team, pos + (vel / 2), polarCoord(exMag2,randAngle2), 20));
    }
    
    void drawStallTimer()
    {
        if(stallTimer == 0)
            return;
    
        foreach(bar; 0 .. 9)
        {
            int barx = pos.x - 22 + (bar * 5);
            int bary = pos.y - 24;
            bool barOn = stallTimer > (bar * 13);
            hudLayer.add(new BasicSprite(team.texStunCounter[barOn], barx, bary));
        }
    }

    abstract void reactBolt();
};
