{{
  Realtime ADC I2C reader (1000 samples/sec)
  Based on I2C driver in PASM
  I2C driver in PASM Author: Chris Gadd
  Modified by JDat
  See end of file for terms of use.
}}                                                                                                                                                
CON
' device addess shifted and read bit added
  adcChipAddress = %1001_101_1            ' Device code for MCP3221 %1001_101 
{
OBJ
  dbg : "PASDebug"
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

PUB run
  dbg.start(31,30,@entry)
  start(adcSCLpin,adcSDApin,adcI2Cfreq)
}    
VAR
  word  adcdata
  word  ptr

  ''word rtbuffer[10_000]
                     
PUB start(clk_pin, data_pin, bitrate, launch_pin)
  SCL_mask := 1<<clk_pin
  SDA_mask := 1<<data_pin
  launch_mask:=1<<launch_pin
  long[@I2C_bit_delay][0]:= clkfreq / (bitrate * 4)
  long[@_1ms][0]:=clkfreq/1000

  cognew(@entry, @adcdata)
pub read
{
  result := cnt  
  repeat while adcdata > 4096                           'if bit 15 set then PASM ADC read routine in progress
    if cnt - result > clkfreq / 100                      'wait 1000 ms                                                  
        return adcdata                                  'escape if no valid response from PASM routine (just in case--shouldn't ever happen)
}
  return  adcdata
DAT                     org     0
entry
{
                        '-- Debugger Kernel add this at Entry (Addr 0)
                        long $34FC1202,$6CE81201,$83C120B
                        long $8BC0E0A,$E87C0E03,$8BC0E0A
                        long $EC7C0E05,$A0BC1207,$5C7C0003
                        long $5C7C0003,$7FFC,$7FF8
                        '---------------------------------------
}                         
                        ''mov       t1,par                                        ' Load parameter addresses
                        {
                        add       t1,#2
                        
                        rdbyte    t2,t1
                        mov       SCL_mask,#1                                   ' Create masks for clock and data pins
                        shl       SCL_mask,t2

                        add       t1,#1
                        rdbyte    t2,t1
                        mov       SDA_mask,#1
                        shl       SDA_mask,t2
                        }
                        mov     sample_delay,_1ms
                        add     sample_delay,cnt
'----------------------------------------------------------------------------------------------------------------------
main                                
                        waitcnt   sample_delay,_1ms
                        mov     t1,#%1000_0000
                        mov     t2,par
                        add     t2,#1
                        wrbyte    t1,t2                 ' Set bit 15 to high, incicating, ADC sampling in progress
                         
                        mov       loop_counter,#2                                    ' How many bytes read form ADC?
                        mov       I2C_byte,I2C_address                               ' Set I2C dev address for write podeure
                                                        ' Variable setup before I2C process
'I2C START sending
                        mov       cnt,I2C_bit_delay                             
                        add       cnt,cnt                                       
                        andn      dira,SDA_mask                                  
                        andn      dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                              
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
'I2C START completed
'I2C address sending
                        mov       cnt,I2C_bit_delay                                  
                        add       cnt,cnt                                         
                        mov       bit_counter,#8                                  
                        shl       I2C_byte,#24                                         
:Loop                                                                               
                        rcl       I2C_byte,#1                 wc               
                        muxnc     dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask
                        waitpeq   SCL_mask,SCL_mask                             ' some devices apparently stretch the clock before the first bit
                        mov       cnt,I2C_bit_delay                             ' resync clock
                        add       cnt,cnt                                                                                                                            
                        waitcnt   cnt,I2C_bit_delay
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
                        djnz      bit_counter,#:Loop
:Read_ack_or_nak
                        andn      dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay
                        andn      dira,SCL_mask
                        waitpeq   SCL_mask,SCL_mask                             ' and some devices stretch the clock after the last bit 
                        mov       cnt,I2C_bit_delay                             ' resync clock 
                        add       cnt,cnt                                                                             
                        waitcnt   cnt,I2C_bit_delay
                        test      SDA_mask,ina                wc                ' C is set if NAK
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                                                                   
'I2C address completed

'###############################################################################################################
:read_loop
                        call      #I2C_read                                     ' Read a byte
                        wrbyte    I2C_byte,t2                                   '  and either store in _data or in an array
                        sub       t2,#1                                         '  increment the array address
                        sub       loop_counter,#1             wz
          if_nz        call      #I2C_ack                                      ' Send an ack if reading more bytes
          if_nz        jmp       #:read_loop
'###############################################################################################################

{
'###############################################################################################################
:read_loop
                        call    #I2C_read                                     ' Read a byte
                        wrbyte  I2C_byte,t2                                   '  and either store in _data or in an array
                        sub     t2,#1                                         '  increment the array address
                        call    #I2C_read
                        wrbyte  I2C_byte,t2                        
 '###############################################################################################################
}
'I2C NAK sending                           
                        mov       cnt,I2C_bit_delay                                  
                        add       cnt,cnt                                            
                        andn      dira,SDA_mask                                       
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay                             
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
'I2C NAK completed
'I2C STOP sending
                        mov       cnt,I2C_bit_delay                              
                        add       cnt,cnt                                        
                        or        dira,SDA_mask                                    
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay     
'I2C STOP completed
                        jmp       #main
'======================================================================================================================
I2C_read                                                                        '      (Read) 
                        mov       cnt,I2C_bit_delay                                   
                        add       cnt,cnt                                          
                        mov       bit_counter,#8                                   
:loop                                                                               
                        andn      dira,SDA_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask
                        waitcnt   cnt,I2C_bit_delay                                           
                        waitpeq   SCL_mask,SCL_mask                             ' wait for clock-stretching 
                        mov       cnt,I2C_bit_delay                             ' resync clock
                        add       cnt,cnt                                                     
                        test      SDA_mask,ina                wc                ' Read
                        rcl       I2C_byte,#1                                   ' Store in lsb
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
                        djnz      bit_counter,#:Loop                            ' Repeat until eight bits received
I2C_read_ret            ret                        
'----------------------------------------------------------------------------------------------------------------------
I2C_ack                                                                          
                        mov       cnt,I2C_bit_delay                              
                        add       cnt,cnt                                        
                        or        dira,SDA_mask                                   
                        waitcnt   cnt,I2C_bit_delay                              
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay   
I2C_ack_ret             ret
'----------------------------------------------------------------------------------------------------------------------
_1ms                    long    0
I2C_address             long    adcChipAddress
I2C_bit_delay           long    0

SCL_mask                long    0                                             
SDA_mask                long    0                                             
launch_mask             long    0

I2C_byte                res     1          

bufferptr               res     1
launchstate             res     1
sample_delay            res     1
bit_counter             res     1
loop_counter            res     1
t1                      res     1
t2                      res     1
                        fit
DAT                     
{{
                                                   TERMS OF USE: MIT License                                                            
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation     
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}                      