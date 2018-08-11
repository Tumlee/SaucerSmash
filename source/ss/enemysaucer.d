module ss.enemysaucer;

import ss.playersaucer;
import ss.saucer;
import ss.trail;
import ss.bolt;
import ss.shieldbreak;

import ss.resources;
import ss.graphics;
import ss.hud;
import ss.gamestate;

class EnemySaucer : Saucer
{
    bool bumped = false;
    int upTime = 300;        //Used for announcer taunting puposes. :)
    int dodgeDirection = 1; //Which direction enemy elite is dodging, 1 or -1.
    int dodgeTimer = 120;
    int timeAlive = 0;
    
    @property bool isElite()
    {
        return timeAlive > (15 * 60);
    }

    this(Team tm, FixCoord ppos)
    {
        pos = ppos;
        team = tm;
        shotTimer = 12;
    }

    override bool tick()
    {
        bool wasOverdrive = overdrive;
        overdrive = false;
        
        timeAlive++;
        
        if(damage > iu!1)
        {
            addScore(10);
            explode();
            return false;
        }

        if(gameState == GameState.over)
        {
            actors.spawn(new ShieldBreak(pos, vel));
            return false;
        }

        if(stallTimer)
        {
            vel *= ff!(99, 100);
            stallTimer--;
            upTime = 0;
        }
        else
        {
            damage = 0;         //Recover all damage when shields are up.
            bumped = false;     //Clear the "bumped" flag.

            if(!chaseTarget())
                return false;            
                            
            if(!wasOverdrive && overdrive)
                emitSound(sfxOverdrive);

            upTime++;

            vel *= ff!(98, 100);
        }

        if(shotTimer)
            shotTimer--;

        pos += vel;
        bounceScreen();

        //Note: Move this closer to collision detection for PlayerSaucers?
        foreach(other; actors.actorsOf!(EnemySaucer))
        {
            if(other !is this && isTouching(other))
            {
                int shipsDestroyed = 0;

                //Velocity toward one another has to be relatively high.
                auto velDiff = vel - other.vel;
                auto velAverage = (vel + other.vel) / 2;
                auto ramDamage = velDiff.mag / 7;

                //Don't damage if both have shields up.
                if(stallTimer || other.stallTimer)
                {
                    damage += ramDamage;
                    other.damage += ramDamage;
                }

                if(other.damage > 1)
                {
                    other.vel = (velAverage + other.vel) / 2;
                    shipsDestroyed++;
                }

                if(damage > 1)
                {
                    vel = (velAverage + vel) / 2;
                    shipsDestroyed++;
                }

                if(bumped || other.bumped)
                {
                    addScore(shipsDestroyed * 5);

                    if(shipsDestroyed)
                        announcer.set("Bump", 60);
                }

                if(shipsDestroyed != 2)
                {
                    pos.redistance(other.pos, radius + other.radius);
                    
                    auto tempVel = other.vel;
                    other.vel = vel;
                    vel = tempVel;

                    float volume = cast(float) (velDiff.mag < 7 ? velDiff.mag / 7 : iu!1);
                    emitSound(sfxClunk, volume);
                }
            }
        }

        rotate();
        drawSaucer();

        if(!stallTimer)
            effectLayer.add(new FCSprite(team.texShield, pos));

        if(stallTimer && stallTimer < 30 && (stallTimer / 4) & 1)
            effectLayer.add(new FCSprite(texShieldBreak[2], pos));
            
        if(timeAlive > (12 * 60) && !isElite)
            hudLayer.add(new FCSprite(team.texTarget, pos, timeAlive * -3));
            
        if(isElite)
            hudLayer.add(new FCSprite(texFadeTarget, pos, timeAlive * -6));

        return true;
    }

    bool chaseTarget()
    {
        if(actors.actorsOf!(PlayerSaucer).length)
        {
            auto target = actors.actorsOf!(PlayerSaucer)[0];
        
            if(isElite)
            {
                if(--dodgeTimer == 0)
                {
                    dodgeTimer = recorder.uniform(30, 180);
                    dodgeDirection = -dodgeDirection;
                }            
                
                auto angOff = ff!(12, 10) * dodgeDirection;
            
                if(target.stallTimer < 25)
                {
                    vel += polarCoord(ff!(17, 100), (target.pos - pos).ang + ff!(12, 10) * dodgeDirection);
                }
                else
                {
                    overdrive = true;
                    vel += polarCoord(ff!(45, 100), aimThrust(target.pos));
                }
            }
            else
            {
                vel += polarCoord(ff!(17, 100), aimThrust(target.pos));
            }

            //Shoot stun bolts at target, if you have one.
            if(shotTimer == 0 && isElite && !overdrive)
                fireBolts((target.pos - pos).ang);

            makeTrail();
        }

        //Get repelled by any nearby allied ships to avoid collision.
        foreach(other; actors.actorsOf!(EnemySaucer))
        {
            if(other is this)
                continue;

            auto diff = other.pos - pos;

            if(diff.mag < iu!64)
                vel -= polarCoord(iu!1 / 10, diff.ang);
        }

        return true;
    }
    
    void fireBolts(Fix16 angle)
    {
        auto boltOrigin = pos + polarCoord(radius, angle);
        auto boltSpread = fu!2048;

        actors.spawn(new Bolt(this, boltOrigin, polarCoord(iu!8, angle + boltSpread)));
        actors.spawn(new Bolt(this, boltOrigin, polarCoord(iu!8, angle - boltSpread)));

        emitSound(sfxBolt);
        shotTimer = 12;
    }

    override void reactBolt()
    {
        if(stallTimer == 0)
            actors.spawn(new ShieldBreak(pos, vel));

        addStall(60);
    }
}
