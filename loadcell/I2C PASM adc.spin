{{
// realtime ADC I2C reader
// based on I2C driver in PASM
// I2C driver in PASM Author: Chris Gadd
// Modified by JDat
// See end of file for terms of use.
}}                                                                                                                                                
CON
' Requires the un-shifted 7-bit device address
' The driver shifts the address and appends the read / write bit
  ADC = %1001_101            ' Device code for MCP3221

' command to start ADC reading
VAR
  long  bit_ticks
  word  _data                   
  byte  _command
  byte  _device
  byte  SCL_pin
  byte  SDA_pin  
PUB start(clk_pin, data_pin, bitrate)
  SCL_pin := clk_pin
  SDA_pin := data_pin
  bit_ticks := clkfreq / (bitrate * 4)  
  cognew(@entry, @bit_ticks)
PUB read    'read 12 bit value from ADC
  waitForReady
  _device := constant(ADC << 1)
  _command := 1         ' activate reading
  waitForReady
  result := _data
pri waitForReady
  result := cnt  
  repeat until _Command == $00 or _Command == $FF       ' _command is set to $FF upon success by PASM, or set to $00 if no response from device within 10ms
    if cnt - result > clkfreq / 10                                                  
        quit                                            ' escape if no valid response from PASM routine (just in case--shouldn't ever happen)
DAT                     org
entry
                        mov       t1,par                                        ' Load parameter addresses
                        rdlong    I2C_bit_delay,t1
                        add       t1,#4
                        mov       data_address,t1
                        add       t1,#2
                        mov       command_address,t1
                        add       t1,#1
                        mov       device_address,t1
                        add       t1,#1
                        
                        rdbyte    t2,t1
                        mov       SCL_mask,#1                                   ' Create masks for clock and data pins
                        shl       SCL_mask,t2
                        add       t1,#1
                        rdbyte    t2,t1
                        mov       SDA_mask,#1
                        shl       SDA_mask,t2
'----------------------------------------------------------------------------------------------------------------------
main                                
                        rdbyte    command_byte,command_address wz               ' Loop until command is set by a Spin routine
          if_z          jmp       #main
                        cmp       command_byte,#$FF           wz
          if_e          jmp       #main
                        rdbyte    device_byte,device_address
'......................................................................................................................
:read_next
                        mov       loop_counter,#2                               
                        mov       t2,data_address                               ' Store the read value in the _data var
                        call      #I2C_start                                    ' Send a start / restart
                        mov       I2C_byte,device_byte
                        or        I2C_byte,#1
                        call      #I2C_write                                    ' Send the device ID with the read bit set
:read_loop
                        call      #I2C_read                                     ' Read a byte
                        wrbyte    I2C_byte,t2                                   '  and either store in _data or in an array
                        add       t2,#1                                         '  increment the array address
                        sub       loop_counter,#1             wz
          if_nz         call      #I2C_ack                                      ' Send an ack if reading more bytes
          if_nz         jmp       #:read_loop
                        call      #I2C_nak                                      ' Otherwise send a NAK
                        call      #I2C_stop                                     '  and stop
                        jmp       #main
'======================================================================================================================
I2C_start
                        mov       cnt,I2C_bit_delay                             ' SCL 
                        add       cnt,cnt                                       ' SDA 
                        andn      dira,SDA_mask                                 '     0 1 2 3 
                        andn      dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                              
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay
I2C_start_ret           ret
'----------------------------------------------------------------------------------------------------------------------
I2C_write                                                                        '   (Write)      (Read ACK or NAK)
                        mov       cnt,I2C_bit_delay                              '                      
                        add       cnt,cnt                                        ' SCL    
                        mov       bit_counter,#8                                 ' SDA  ───────  
                        shl       I2C_byte,#24                                   '     0 1 2 3  0 1 2 3       
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
I2C_write_ret           ret
'----------------------------------------------------------------------------------------------------------------------
I2C_read                                                                        '      (Read) 
                        mov       cnt,I2C_bit_delay                             '               
                        add       cnt,cnt                                       ' SCL    
                        mov       bit_counter,#8                                ' SDA ───────   
:loop                                                                           '     0 1 2 3    
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
                        mov       cnt,I2C_bit_delay                             ' SCL  
                        add       cnt,cnt                                       ' SDA  
                        or        dira,SDA_mask                                 '     0 1 2 3  
                        waitcnt   cnt,I2C_bit_delay                              
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay
                        waitcnt   cnt,I2C_bit_delay
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay   
I2C_ack_ret             ret
'----------------------------------------------------------------------------------------------------------------------
I2C_nak                                                                         '                           
                        mov       cnt,I2C_bit_delay                             ' SCL      
                        add       cnt,cnt                                       ' SDA      
                        andn      dira,SDA_mask                                 '     0 1 2 3      
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay                             
                        or        dira,SCL_mask                                 
                        waitcnt   cnt,I2C_bit_delay                             
I2C_nak_ret             ret
'----------------------------------------------------------------------------------------------------------------------
I2C_stop
                        mov       cnt,I2C_bit_delay                             ' SCL  
                        add       cnt,cnt                                       ' SDA  
                        or        dira,SDA_mask                                 '     0 1 2 3  
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SCL_mask                                                                   
                        waitcnt   cnt,I2C_bit_delay                             
                        andn      dira,SDA_mask
                        waitcnt   cnt,I2C_bit_delay                             
                        waitcnt   cnt,I2C_bit_delay
                        mov       t1,#$FF
                        wrbyte    t1,command_address
I2C_Stop_ret            ret
'----------------------------------------------------------------------------------------------------------------------
no_response
                        mov       t1,#0
                        wrbyte    t1,command_address
                        jmp       #main
'----------------------------------------------------------------------------------------------------------------------

_10ms                   long      800_000

command_address         res       1
device_address          res       1
data_address            res       1
command_byte            res       1
device_byte             res       1
SCL_mask                res       1                                             
SDA_mask                res       1                                             
I2C_bit_delay           res       1                                           
bit_counter             res       1
I2C_byte                res       1
loop_counter            res       1
t1                      res       1
t2                      res       1
timeout                 res       1
                        fit

DAT                     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                      