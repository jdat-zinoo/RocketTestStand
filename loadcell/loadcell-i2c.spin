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
    ''BAUD_RATE = 230_400
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
    ''c:=cnt
        
    repeat
      b:=word[buffhead][0]
      if b<10_000
        a:=0
        repeat while b<10_000
          repeat while a<b
            debug.tx("R")
            debug.tx(",")
            debug.dec4(a)
            debug.tx(",")
            debug.dec4(word[buffptr][a])
            debug.cr
            ''debug.lf 
            a++
            b:=word[buffhead][0]
            if b>10_000
              b:=10_000
      else                          
        adcRAW(rawptr)      
            
pub adcRAW(ptr)|a
        a:=word[ptr][0]
       if a<4096
          debug.tx("S")
          debug.dec4(a)
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