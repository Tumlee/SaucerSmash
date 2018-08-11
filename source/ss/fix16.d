module ss.fix16;

int fix16_mul(int a, int b)
{
    long temp1 = a;
    long temp2 = b;
    
    long tempAnswer = temp1 * temp2;
    tempAnswer /= 65536;
    
    return cast(int) tempAnswer;
}

int fix16_div(int a, int b)
{
    if(b == 0)
        return a > 0 ? int.max : int.min;

    long temp1 = a;
    long temp2 = b;
    
    temp1 *= 65536;
    temp1 /= temp2;
    
    return cast(int) temp1;
}

immutable int fix16_pi = 205887;

//The following trigonometric functions, and fix16_sqrt(), are all adapted
//from the libfixmath library released under the MIT license.
int fix16_sin(int inAngle)
{
    int tempAngle = inAngle % (fix16_pi << 1);

    if(tempAngle > fix16_pi)
        tempAngle -= (fix16_pi << 1);
    else if(tempAngle < -fix16_pi)
        tempAngle += (fix16_pi << 1);

    int tempAngleSq = fix16_mul(tempAngle, tempAngle);

    // Most accurate version, accurate to ~2.1%
    int tempOut = tempAngle;
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 6);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut += (tempAngle / 120);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 5040);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut += (tempAngle / 362880);
    tempAngle = fix16_mul(tempAngle, tempAngleSq);
    tempOut -= (tempAngle / 39916800);

    return tempOut;
}

int fix16_cos(int inAngle)
{
    return fix16_sin(inAngle + (fix16_pi >> 1));
}

int fix16_tan(int inAngle)
{
    //NOTE: Original implementation used saturated division.
    return fix16_div(fix16_sin(inAngle), fix16_cos(inAngle));
}

int fix16_sqrt(int inValue)
{
    ubyte neg = (inValue < 0);
    uint num = (neg ? -inValue : inValue);
    uint result = 0;
    uint bit;
    ubyte n;
    
    // Many numbers will be less than 15, so
    // this gives a good balance between time spent
    // in if vs. time spent in the while loop
    // when searching for the starting value.
    if (num & 0xFFF00000)
        bit = cast(uint)1 << 30;
        
    else
        bit = cast(uint)1 << 18;
    
    while (bit > num) bit >>= 2;
    
    // The main part is executed twice, in order to avoid
    // using 64 bit values in computations.
    for (n = 0; n < 2; n++)
    {
        // First we get the top 24 bits of the answer.
        while (bit)
        {
            if (num >= result + bit)
            {
                num -= result + bit;
                result = (result >> 1) + bit;
            }
            else
            {
                result = (result >> 1);
            }
            bit >>= 2;
        }
        
        if (n == 0)
        {
            // Then process it again to get the lowest 8 bits.
            if (num > 65535)
            {
                // The remainder 'num' is too large to be shifted left
                // by 16, so we have to add 1 to result manually and
                // adjust 'num' accordingly.
                // num = a - (result + 0.5)^2
                //     = num + result^2 - (result + 0.5)^2
                //     = num - result - 0.5
                num -= result;
                num = (num << 16) - 0x8000;
                result = (result << 16) + 0x8000;
            }
            else
            {
                num <<= 16;
                result <<= 16;
            }
            
            bit = 1 << 14;
        }
    }

    // Finally, if next bit would have been 1, round the result upwards.
    if (num > result)
        result++;
    
    return (neg ? -(cast(int) result) : (cast(int) result));
}

int fix16_atan2(int inY , int inX)
{   
    int abs_inY, mask, angle, r, r_3;

    // Absolute inY
    mask = (inY >> (int.sizeof * 8 - 1));
    abs_inY = (inY + mask) ^ mask;

    if (inX >= 0)
    {
        r = fix16_div((inX - abs_inY), (inX + abs_inY));
        r_3 = fix16_mul(fix16_mul(r, r), r);
        angle = fix16_mul(0x00003240 , r_3) - fix16_mul(0x0000FB50,r) + (fix16_pi / 4);
    }
    else
    {
        r = fix16_div((inX + abs_inY), (abs_inY - inX));
        r_3 = fix16_mul(fix16_mul(r, r), r);
        angle = fix16_mul(0x00003240, r_3) - fix16_mul(0x0000FB50, r) + ((fix16_pi * 3) / 4);
    }
    
    if(inY < 0)
        angle = -angle;

    return angle;
}

struct Fix16
{
    int data;
    
    this(int value)
    {   
        data = value << 16;
    }
    
    this(Fix16 value)
    {
        data = value.data;
    }

    @property int literal()
    {
        return data;
    }
    
    Fix16 sin()
    {
        return fixLiteral(fix16_sin(data));
    }
    
    Fix16 cos()
    {
        return fixLiteral(fix16_cos(data));
    }
    
    Fix16 tan()
    {
        return fixLiteral(fix16_tan(data));
    }
    
    Fix16 sqrt()
    {
        return fixLiteral(fix16_sqrt(data));
    }

    int opCmp(Fix16 rhs)
    {            
        if(data > rhs.data)
            return 1;
            
        else if(data < rhs.data)
            return -1;
            
        else
            return 0;
    }
    
    int opCmp(int rhs)
    {   
        return opCmp(fixLiteral(rhs * 65536));
    }
    
    void opAssign(Fix16 rhs)
    {
        data = rhs.data;
    }
    
    void opAssign(int rhs)
    {
        data = rhs << 16;
    }
    
    void opOpAssign(string op)(Fix16 rhs)
    {
        this = opBinary!(op)(rhs);
    }
    
    void opOpAssign(string op)(int rhs)
    {
        this = opBinary!(op)(rhs);
    }
    
    Fix16 opUnary(string op : "-")()
    {
        return fixLiteral(-data);
    }
    
    Fix16 opBinary(string op)(Fix16 rhs)
    {       
        static if(op == "+")
        {
            return fixLiteral(data + rhs.data);
        }
        
        else static if(op == "-")
        {
            return fixLiteral(data - rhs.data);
        }
        
        else static if(op == "*")
        {
            long temp1 = data;
            long temp2 = rhs.data;
            
            long tempAnswer = temp1 * rhs.data;
            tempAnswer /= 65536;
            
            return fixLiteral(cast(int) tempAnswer);
        }
        
        else static if(op == "/")
        {
            long temp1 = data;
            long temp2 = rhs.data;
            
            temp1 *= 65536;
            temp1 /= temp2;
            
            return fixLiteral(cast(int) temp1);
        }
            
        else static assert(0, "Operator not implemented for Fix16");
    }
    
    Fix16 opBinary(string op)(int rhs)
    {
        return opBinary!(op)(fixLiteral(rhs * 65536));
    }
    
    Fix16 abs()
    {
        return fixLiteral(data > 0 ? data : -data);
    }
    
    bool opCast(T : bool)()
    {
        return data != 0;
    }
    
    float opCast(T : float)()
    {
        return cast(float)data / 65536.0;
    }
    
    @property int toInt()
    {
        return data / 65536;
    }
    
    static Fix16 pi = fu!205887;
    
    alias toInt this;
}

//Fixed units.
Fix16 fu(int value)()
{
    return fixLiteral(value);
}

//Integer units.
Fix16 iu(int value)()
{   
    return fixLiteral(value * 65536);
}

Fix16 fixLiteral(int data)
{
    Fix16 result;
    result.data = data;
    return result;
}

//Fixed fraction
Fix16 ff(int a, int b)()
{
    static assert(b != 0);
    
    return fixLiteral((a * 65536) / b);
}
