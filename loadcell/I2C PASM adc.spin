{{
  Realtime ADC I2C reader (1000 samples/sec)
  Based on I2C driver in PASM
  I2C driver in PASM Author: Chris Gadd
  Modified by JDat
  See end of file for terms of use.
}}                                                                                                                                                
CON
' device addess shifted and read bit added
  adcChipAddress = %1001_101_1  ' Device code for MCP3221 %1001_101 
  samples_count = 10_000        ' How many samples to log (watch of propeller RAM size!)
{
OBJ
  dbg : "PASDebug"
CON
    '' Clock settings
    _CLKMODE = XTAL1 + PLL16X                             ' External clock at 80MHz
    _XINFREQ = 5_000_000
    CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
    BAUD_RATE = 115_200
    RX_PIN = 31
    TX_PIN = 30
      
    ''ADC setting
    adcSDApin=29
    adcSCLpin=28
    adcI2Cfreq=400_000
    launchPin = 23

PUB run
  dbg.start(31,30,@entry)
  start(adcSCLpin,adcSDApin,adcI2Cfreq, launchPin)
'}    
VAR
  word  adcdata
  word  ptr
  word  rtbuffer[samples_count]
                     
PUB start(clk_pin, data_pin, bitrate, launch_pin)
  SCL_mask := 1<<clk_pin
  SDA_mask := 1<<data_pin
  launch_mask:=1<<launch_pin
  bufferptrmask:=1<<15
  
  long[@I2C_bit_delay][0]:= clkfreq / (bitrate * 4)
  long[@_1ms][0]:=clkfreq/1000
  long[@rt_bufferptr][0]:=@rtbuffer
  long[@bufferptradr][0]:=@ptr
  
  cognew(@entry, @adcdata)
pub dataptr
  return @adcdata
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
'}                         
                        ''mov       t1,par                                        ' parameter register points to @adcdata
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

                        wrword  bufferptrmask,par
                        mov     bufferptr,bufferptrmask            ' Initialize bufferptr=0 and set logging complete flat active
                        wrword  bufferptrmask,bufferptradr
                        mov     launchstate,#0          ' Initialize launch state to passive (Log.0 LOW)                                                 
                        
                        mov     sample_delay,_1ms       ' Initialize smaple delay t 1 ms 
                        add     sample_delay,cnt        ' Add to cnt register for correct waitcnt
'----------------------------------------------------------------------------------------------------------------------
{{
pub
  repeat
    ''timeout 1ms
    ''blockRawValue
    ''if launchpin==active and launchflag==0
    ''  launchflag:=1
    ''  bufferptr:=0
    ''if bufferptr=9_999 and launchflag==1
    ''  launchflag:=0
    ''  buffer:=buffer & (and) bufferflag=true 'launch process read complete
    ''readAdcRAW
    ''if launchflag>0
    ''  write to buffer[bufferptr]:=adcvalue
    ''  buggerptr++
    ''write to adcRAW variable (and ublock adcRAW)
}}
main                                
                        waitcnt   sample_delay,_1ms     'wait for sample delay
                        
                                                ' Set bit 15 to high, incicating, ADC sampling in progress                                                                        
{
                        mov     t1,#%1000_0000          ' Set bit 15 to Log.1 (HIGH)
                        mov     t2,par                  ' Get adcRAW HUB pointer 
                        add     t2,#1                   ' Incremet t2, to oint in HIGH byte  
                        wrbyte    t1,t2                 ' Write to adcRAW HUB value
}
                        wrword  bufferptrmask,par



                                                ' Check for launch pin
                                                ''if launchpin==active and launchflag==0
                                                ''  launchflag:=1
                                                ''  bufferptr:=0                                                 
                        ''mov     t1,ina
                        ''and     t1,launch_mask  wz
                        test    launch_mask,ina wz      ' Z flag is set if launch pin active
              if_nz      jmp     #launchNotSet          ' if Z flag=0 then skip (no launch)
                        test    launchstate,#1  wz      ' Z flag is set if launch state active
              if_nz     jmp     #launchNotSet          ' if Z flag=1 then skip (no launch)                                  
                        mov     launchstate,#1          ' Launch is active. Set launch flag to active
                        mov     bufferptr,#0            ' Launch is active. Set bufferptr to 0

                        wrword  bufferptr,bufferptradr  ' Launch is active. Send out bufferptr   
launchNotSet

                                                'check for buffer ptr overflow, meaning: measurements complete
                                                ''if bufferptr=9_999 and launchflag==1
                                                ''  launchflag:=0
                                                ''  buffer:=buffer & (and) bufferflag=true 'launch process read complete                                                 
                        test    launchstate,#1  wz      ' Z flag is set if launch state active
              if_z      jmp     #continueLog           ' if Z flag=0 then skip (continue logging)
                        
                        cmp     bufferptr,buffersize wz,wc
        if_z_or_c       jmp     #continueLog           ' skip if bufferptr less than buffersize (10_000)
                        mov     launchstate,#0          ' Loging complete. launchstate passive (Log.0 LOW) 
                        mov     bufferptr,bufferptrmask ' Loging complete. Reset bufferptr (Bufferptr=0)
 
                        wrword  bufferptr,bufferptradr            ' Loging complete. Send out bufferptr
continueLog
                        
                                                        ' Variable setup before I2C process                         
                        mov     loop_counter,#2                                 ' How many bytes read form ADC?
                        mov     I2C_byte,I2C_address                            ' Set I2C dev address for write procerure
                        mov     I2C_word,#0                                     'reset I2Cword

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
'main read loop
'read adc 2 times

read_loop
                        call      #I2C_read                                     ' Read a byte
                        and     I2C_byte,#$FF           ' mask out only low byte
                        or      I2C_word,I2C_byte       ' add to word's low byte
                        sub     loop_counter,#1 wz      'decremet adcchip read byte counter
              if_nz     call    #I2C_ack                ' Send an ack if reading more bytes
              if_nz     shl     I2C_word,#8             ' shift I2C word by 8 to make high byte if reading more bytes                    
              if_nz     jmp     #read_loop             ' loopi f reading more bytes
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

    ''if launchflag>0
    ''  write to buffer[bufferptr]:=adcvalue
    ''  bufferptr++
                        test    launchstate,#1  wz      ' Z flag is set if launch state active
              if_z     jmp     #skipbuffer            ' if Z flag=1 then skip (no write to buffer)

                        mov     t1,bufferptr
                        shl     t1,#1
                        add     t1,rt_bufferptr
                        wrword  I2C_word,t1
                        add     bufferptr,#1
                        wrword  bufferptr,bufferptradr                                                          
skipbuffer


                        wrword  I2C_word,par            'send out adcRAW to adcData for user
                        
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

bufferptradr            long    0
rt_bufferptr            long    0
buffersize              long    samples_count-1
bufferptrmask           long    0

I2C_byte                res     1          
I2C_word                res     1

bufferptr               res     1

launchstate             res     1
sample_delay            res     1
bit_counter             res     1
loop_counter            res     1
t1                      res     1
''t2                      res     1
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