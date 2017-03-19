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
PUB main | rawptr,buffhead,buffptr,a,b,c
    debug.Start(rx_Pin, tx_Pin, baud_Rate)
    adc.start(adcSCLpin,adcSDApin,adcI2Cfreq,launchPin)

    waitcnt(clkfreq/500+cnt)

    rawptr:=adc.dataptr
    buffhead:=rawptr+2
    buffptr:=rawptr+4    
    c:=cnt
    repeat
        debug.str(string("Wait for launch!",13))
        repeat while word[buffhead][0]>10_000
        debug.str(string("Logging...",13))        
        repeat while word[buffhead][0]<10_000
        repeat a from 0 to 9_999
          b:=word[buffptr][a]
          debug.dec(b)
          debug.tx(9)
          debug.dec(a)
          debug.cr
          ''debug.lf    
                      
        ''adcRAW(a)
        ''bufferindex(b)
          ''waitcnt(c+=MS_001)
          ''waitcnt(MS_001+cnt)
          ''waitcnt(clkfreq/4000+cnt)
          ''waitcnt(clkfreq/10+cnt)
          ''waitcnt(clkfreq/100+cnt)

pub bufferindex(ptr)|a
    a:=word[ptr][0]
    if a<10_005
      debug.dec(a)
      ''debug.hex(a,4)
      debug.cr
      ''debug.lf    
pub adcRAW(ptr)|a
        a:=word[ptr][0]
       if a<4096
          debug.dec(a)
          ''debug.hex(a,4)
          debug.cr
          ''debug.lf

  
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