{{
// test code for realtime ADC I2C reader with hue PASM I2C modifications
// I2C PASM Author: Chris Gadd
// Modified by JDat
}}
CON
    '' Clock settings
    _CLKMODE = XTAL1 + PLL16X                             ' External clock at 80MHz
    _XINFREQ = 5_000_000
    CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
    MS_001   = CLK_FREQ / 1_000
    '' Serial port settings for shell
    BAUD_RATE = 115_200
    RX_PIN = 31
    TX_PIN = 30
      
    ''ADC setting
    adcSDApin=29
    adcSCLpin=28
    adcI2Cfreq=400_000
    ''launch pin
    launchPin = 23
    'status led
    'statusLedPin=-1

OBJ
    debug : "my_PBnJ_serial"
    adc   : "I2C PASM adc"
VAR
    ''word rtbuffer[10_000]
PUB main | i,a,b
    debug.Start(rx_Pin, tx_Pin, baud_Rate)
    adc.start(adcSCLpin,adcSDApin,adcI2Cfreq,launchPin)

    waitcnt(clkfreq/500+cnt)
        
    repeat
        a:=adc.read
        repeat while a>4096
          a:=adc.read
{       
        if (a>4096) or (a<0)
          debug.str(string("Timeout",13))
          ''waitcnt(MS_001+cnt)
          ''waitcnt(clkfreq/4000+cnt)
          waitcnt(clkfreq/10+cnt)
          next
}
        debug.dec(a)
{
        if a==0
            i++
            debug.tx(9)
            debug.dec(i)
        else
            i:=0            
}
      debug.cr
      ''debug.lf
      ''waitcnt(MS_001+cnt)
      ''waitcnt(clkfreq/4000+cnt)
      ''waitcnt(clkfreq/10+cnt)
DAT
{{
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  TERMS OF USE: MIT License
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}}