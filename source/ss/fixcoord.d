module ss.fixcoord;

public import ss.fix16;

import std.stdio;
import std.string;
import std.conv;

struct FixCoord
{
    Fix16 x, y;
    
    this(int xx, int yy)
    {
        x = xx;
        y = yy;
    }
    
    this(Fix16 xx, Fix16 yy)
    {
        x = xx;
        y = yy;
    }
    
    FixCoord opUnary(string op : "-")()
    {
        return FixCoord(-x, -y);
    }
    
    @property Fix16 mag()
    {        
        auto xx = x;
        auto yy = y;
        
        //Adjust any numbers that are int.min because
        //it can actually break the algorithm.
        if(xx.data == int.min)
            xx.data++;
            
        if(yy.data == int.min)
            yy.data++;
        
        //Normalize the value until it won't overflow.
        auto divFactor = iu!1;
        auto bigger = xx.abs > yy.abs ? xx.abs : yy.abs;
        
        if(bigger >= iu!64)
        {
            divFactor = bigger / iu!64;
            xx /= divFactor;
            yy /= divFactor;
        }
        
        return ((xx * xx) + (yy * yy)).sqrt * divFactor;
    }
    
    @property Fix16 ang()
    {
        return fixLiteral(fix16_atan2(y.data, x.data));
    }
    
    @property Fix16 cos()
    {
        return x / mag;
    }
    
    @property Fix16 sin()
    {
        return y / mag;
    }
    
    @property void mag(Fix16 newMag)
    {
        auto mult = newMag / mag;

        x *= mult;
        y *= mult;
    }

    @property void ang(Fix16 newAng)
    {
        //Save the magnitude.
        auto magn = mag;

        x = magn * ang.cos;
        y = magn * ang.sin;
    }

    void redistance(FixCoord anchor, Fix16 magn)
    {
        auto diff = this - anchor;
        auto mult = magn / diff.mag;

        x = anchor.x + (mult * diff.x);
        y = anchor.y + (mult * diff.y);
    }

    void reangle(FixCoord anchor, Fix16 newAngle)
    {
        //Save the distance between the two points.
        auto distance = (this - anchor).mag;

        x = anchor.x + (distance * ang.cos);
        y = anchor.y + (distance * ang.sin);
    }

    FixCoord slide(FixCoord other)
    {
        auto diffAng = other.ang - ang;
        auto newMag = mag * diffAng.cos;
        
        return FixCoord(newMag * other.cos, newMag * other.sin);
    }

    Fix16 slideMag(FixCoord other)
    {
        return mag * (other.ang - ang).cos;
    }

    FixCoord perp()
    {
        return FixCoord(-y, x);
    }

    FixCoord unit()
    {
        return FixCoord(cos, sin);
    }
    
    FixCoord opBinary(string op)(FixCoord rhs)
    {
        static if(op == "+")
            return FixCoord(x + rhs.x, y + rhs.y);
            
        else static if(op == "-")
            return FixCoord(x - rhs.x, y - rhs.y);
            
        else static assert(0, "Operator not implemented for FixCoord"); 
    }

    FixCoord opBinary(string op)(Fix16 rhs)
    {
        static if(op == "*")
            return FixCoord(x * rhs, y * rhs);
            
        else static if(op == "/")
            return FixCoord(x / rhs, y / rhs);
            
        else static assert(0, "Operator not implemented for FixCoord");
    }
    
    FixCoord opBinary(string op)(int rhs)
    {
        return opBinary!(op)(fixLiteral(rhs * 65536));
    }
    
    void opAssign(FixCoord rhs)
    {
        x = rhs.x;
        y = rhs.y;
    }
    
    void opOpAssign(string op)(FixCoord rhs)
    {
        this = opBinary!(op)(rhs);
    }
    
    void opOpAssign(string op)(Fix16 rhs)
    {
        this = opBinary!(op)(rhs);
    }
    
    void opOpAssign(string op)(int rhs)
    {
        this = opBinary!(op)(fixLiteral(rhs * 65536));
    }

    static const FixCoord origin = FixCoord(0,0);
}

FixCoord polarCoord(Fix16 mag, Fix16 ang)
{
    return FixCoord(mag * ang.cos, mag * ang.sin);
}
