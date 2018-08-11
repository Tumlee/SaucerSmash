module ss.playersaucer;

import ss.saucer;
import ss.resources;
import ss.trail;
import ss.bolt;
import ss.enemysaucer;
import ss.shieldbreak;

import magra.base;
import ss.graphics;
import ss.gamestate;
import ss.hud;
import ss.gamerecorder;

import std.conv;

Fix16 normalSpeed = ff!(4, 10);
Fix16 overdriveSpeed = ff!(6, 10);

auto upKey = KeyBind("keyboard", 'w');
auto downKey = KeyBind("keyboard", 's');
auto leftKey = KeyBind("keyboard", 'a');
auto rightKey = KeyBind("keyboard", 'd');
auto fireKey = KeyBind("mouse", SDL_BUTTON_LEFT);
auto dashKey = KeyBind("mouse", SDL_BUTTON_RIGHT);
auto aimDashKey = KeyBind("keyboard", SDLK_SPACE);

class PlayerSaucer : Saucer
{
    int comboCounter = 0;
        
    this(Team tm, FixCoord ppos)
    {   
        team = tm;
        pos = ppos;
    }
    
    override bool tick()
    {
        auto poll = recorder.getPoll(getPoll());
        bool wasOverdrive = overdrive;
        
        if(damage > 1)
        {
            die();
            return false;
        }
        
        if(gameState == GameState.over)
        {
            actors.spawn(new ShieldBreak(pos, vel));
            return false;
        }
        
        overdrive = false;

        if(stallTimer == 0)
        {
            auto accel = poll.speed;
            damage = 0;
            
            //Note: The +1/10 here is a fudge factor.
            if(accel.mag > normalSpeed + ff!(1, 10))
            {
                overdrive = true;
                accel.mag = overdriveSpeed;
            }
            else
            {        
                if(accel.mag > normalSpeed)
                    accel.mag = normalSpeed;
            }

            if(accel.mag)
                makeTrail();
            
            vel += accel;
            vel *= overdrive ? ff!(965, 1000) : ff!(96, 100);
        }
        else    //Ship is stalled out.
        {
            stallTimer--;
            vel *= ff!(98, 100);
        }

        if(!wasOverdrive && overdrive)
            emitSound(sfxOverdrive);

        pos += vel;
        rotate();

        if(bounceScreen() && !stallTimer)
        {
            actors.spawn(new ShieldBreak(pos, vel));
            addStall(30);
        }

        if(shotTimer)
            shotTimer--;

        if(poll.firing && !shotTimer && !overdrive && !stallTimer)
            fireBolts(poll.fireAngle);

        foreach(saucer; actors.actorsOf!(EnemySaucer))
        {
            if(isTouching(saucer))
            {
                if(bumpSaucer(saucer) == false)
                    return false;
            }
        }

        drawStallTimer();
        
        if(overdrive)
            effectLayer.add(new FCSprite(team.texTrail[1], pos - polarCoord(iu!8, vel.ang)));
        
        drawSaucer();

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
        comboCounter = 0;
    }
    
    PlayerPoll getPoll()
    {
        PlayerPoll poll;
        
        if(upKey.isDown)
            poll.speed.y -= normalSpeed;
        
        if(downKey.isDown)
            poll.speed.y += normalSpeed;
         
        if(leftKey.isDown)
            poll.speed.x -= normalSpeed;
        
        if(rightKey.isDown)
            poll.speed.x += normalSpeed;
         
        if(poll.speed.mag)
            poll.speed.mag = normalSpeed;
         
        if(aimDashKey.isDown)
            poll.speed = polarCoord(iu!5, aimThrust(FixCoord(mouse.x, mouse.y)));

        if(dashKey.isDown)
            poll.speed *= 5;
        
        if(fireKey.isDown)
        {
            poll.firing = true;
            poll.fireAngle = FixCoord(mouse.x - pos.x, mouse.y - pos.y).ang;
        }

        //Gamepad HACK!
        poll.speed.x += normalSpeed * fixLiteral(cast(int) (getGamepad(0).getAxis("leftx") * 65536));
        poll.speed.y += normalSpeed * fixLiteral(cast(int) (getGamepad(0).getAxis("lefty") * 65536));

        auto gamepadAimX = fixLiteral(cast(int) (getGamepad(0).getAxis("rightx") * 65536)) * 5;
        auto gamepadAimY = fixLiteral(cast(int) (getGamepad(0).getAxis("righty") * 65536)) * 5;

        /*foreach(di; 1 .. 8)
        {
            auto ang1 = FixCoord(gamepadAimX, gamepadAimY).ang + fu!2048;
            auto ang2 = FixCoord(gamepadAimX, gamepadAimY).ang - fu!2048;
            hudLayer.add(new FCSprite(team.texBoltTrail, pos + polarCoord(iu!40 * di, ang1)));
            hudLayer.add(new FCSprite(team.texBoltTrail, pos + polarCoord(iu!40 * di, ang2)));
        }*/

        if(getGamepad(0).getButton("leftshoulder").isDown)
            poll.speed *= 5;

        if(getGamepad(0).getButton("rightshoulder").isDown)
        {
            poll.firing = true;
            poll.fireAngle = FixCoord(gamepadAimX, gamepadAimY).ang;
        }
        //END HACK
        
        return poll;
    }
    
    override void reactBolt()
    {
        if(stallTimer == 0)
            actors.spawn(new ShieldBreak(pos, vel));

        addStall(45);
    }
    
    bool bumpSaucer(EnemySaucer saucer)
    {
        if(saucer.stallTimer == 0 && saucer.team !is team)
        {
            if(saucer.upTime <= 15)
                announcer.set("Too greedy!", 20);
                     
            if(!saucer.isElite)
                saucer.vel += (vel - saucer.vel) / 2;
                
            vel = saucer.vel;
            die();

            return false;
        }
        else
        {
            auto velDiff = vel - saucer.vel;

            //Ram into enemy during overdrive.
            if(overdrive)
                saucer.damage += velDiff.mag / 7;

            if(saucer.damage > 1)
            {        
                saucer.vel = vel;
                addScore(comboCounter * 20);

                comboCounter++;

                //Put up a cmessage telling about the combo.
                if(comboCounter == 2)
                    announcer.set("Double!", 100);

                if(comboCounter == 3)
                    announcer.set("Triple!!", 110);

                if(comboCounter == 4)
                    announcer.set("Quadruple!!!", 120);
                    
                if(comboCounter > 4)
                {
                    string compliment = "Incredible";
                    
                    foreach(i; 0 .. comboCounter)
                        compliment ~= '!';
                    
                    announcer.set(compliment, 80 + (comboCounter * 10));
                }

                if(saucer.stallTimer < 20)
                    announcer.set("Greedy!", 10);
            }
            else
            {
                //Otherwise, just push him and stall him out.
                pos.redistance(saucer.pos, radius + saucer.radius);                
                
                auto tempVel = saucer.vel;
                saucer.vel = vel;
                vel = tempVel;

                saucer.addStall(30);
                saucer.bumped = true;

                float volume = cast(float) (velDiff.mag < 7 ? velDiff.mag / 7 : iu!1);
                emitSound(sfxClunk, volume);
            }
        }

        return true;
    }
    
    void die()
    {
        explode();
        respawnTimer = 45;
        lives--;
    }
}

struct PlayerPoll
{
    //Note: If desired speed exceeds a certain threshold,
    //the ship is considered to be in "overdrive"
    FixCoord speed;
    bool firing = false;
    Fix16 fireAngle;
}
