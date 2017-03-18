{{
┌──────────────────────────────────────────┐
  │ I2C driver in PASM                       │      This routine requires the use of pull-up resistors on the SCL and SDA lines
  │ Author: Chris Gadd                       │      - Does NOT work with the EEPROM on the demo board, which only has a pull-up on SDA
  │ Copyright (c) 2012 Chris Gadd            │      - This version supports clock stretching
  │ See end of file for terms of use.        │     
  └──────────────────────────────────────────┘

  To use:
    I2C.start(28,29,100_000)                        Start the I2C driver using p28 for clock, p29 for data, at 100Kbps  (tested okay up to 769Kbps)
    I2C.write(I2C#EEPROM,$0123,$45)                 Write $45 to EEPROM address $0123 
    I2C.write_page(I2C#EEPROM,$0123,@Array,500)     Write 500 bytes from Array to EEPROM starting at address $0123
    I2C.command(I2C#Alt,$48)                        Issue command to 'convert D1' to a MS5607 altimeter (Altimeter is the only device, so far discovered, that needs this routine)
    I2C.read(I2C#EEPROM,$0123)                      Read a byte from EEPROM address $0123
    I2C.read_next(I2C#EEPROM)                       Read a byte from EEPROM address $0124 (the next address following a 'read')
    I2C.read_page(I2C#EEPROM,$0123,@Array,500)      Read 500 bytes from an EEPROM starting at address $0123 and store each byte in Array

    This routine performs ACK polling to determine when a device is ready.
    Routine will abort a transmission if no ACK is received within 10ms of polling - prevents I2C routine from stalling if a device becomes disconnected
    No other ACK testing is performed
      If transmission is successful, _command var will be set to $FF
      If transmission is aborted, _command var will be set to 0                                                      ┌──────────────────────────────────────────┐
      All methods except read and read_next return _command as the result in order to test by the calling method.    │ if not I2C.command(EEPROM,0)             │
        (read and read_next return the read values)                                                                  │   FDS.str(string("EEPROM not present"))  │
                                                                                                                     └──────────────────────────────────────────┘
    This routine automatically uses two bytes when addressing an EEPROM.  EEPROM is the only device, so far discovered, that uses two-byte addresses.
                 
'----------------------------------------------------------------------------------------------------------------------
  This object uses a four step count for every bit sent.
    T0 - Put bit to be sent on the SDA pin if writing, float if reading data or Ack/NAK
    T1 - Float SCL pin (already floating on start)
    T2 - Sample SDA pin if reading data or Ack/NAK, or set/release SDA pin for start/stop 
    T3 - Pull SCL pin low (except on stop)

        ┌─Start─┬─Bit 1─┬─Bit 0─┬─Ack(r)┬─Start─┬─Read──┬─Ack(t)┬─Read──┬──NAK──┬─Stop──┐         
    SCL          
    SDA ─────────────────────  
        0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3 0 1 2 3    
                                                                                        
                                    sample          sample          sample                 

  The command, bytes_counter, device, address, and data / data_pointer are read into the PASM cog before I2C transmission starts
         
}}                                                                                                                                                
CON
' Device codes
' Note - Requires the un-shifted 7-bit device address
'        The driver shifts the address and appends the read / write bit

  EEPROM = %101_0000            ' Device code for 24LC256 EEPROM with all chip select pins tied to ground
  RTC    = %110_1000            ' Device code for DS1307 real time clock
  ACC    = %001_1101            ' Device code for MMA7455L 3-axis accelerometer
  GYRO   = %110_1001            ' Device code for L3G4200D gyroscope (SDO to Vdd)
  ALT    = %111_0110            ' Device code for MS5607 altimeter (CS floating)

  IO     = %010_0001            ' Device code for CY8C9520A IO port expander (Strong pull-up (330Ω or less on A0))
                                '  Pull-up required when using the CY8C9520A EEPROM device, addressed at 101_000a
  MPU    = %110_1000
                           ' gyro 110_1001
  BMP085 = %111_0111        ' pressure 1110111
  HMC5883L = %001_1110      ' compass 001_1110
  ADXL345  = %001_1101
  ADXL345alt = %101_0011

'Jump table offsets  
  SINGLE_WRITE  = 1
  PAGE_WRITE    = 2
  SINGLE_READ   = 3
  REPEATED_READ = 4
  PAGE_READ     = 5
  SEND_COMMAND  = 6
                                    
VAR

  long  bit_ticks
  word  _bytes
  word  _address
  word  _data                   

  byte  _command
  byte  _device

  byte  SCL_pin
  byte  SDA_pin
  
  byte  cog                    

PUB start(clk_pin, data_pin, bitrate) : okay

  stop
  SCL_pin := clk_pin
  SDA_pin := data_pin
  bit_ticks := clkfreq / (bitrate * 4)
  
  okay := cog := cognew(@entry, @bit_ticks) + 1

PUB stop

  if cog
    cogstop(cog~ - 1)

PUB write(device,address,data)                                                  ' Write a single byte

  wait_for_ready                                                                ' Wait until completed operation                                                                               

  _device := device << 1
  _address := address
  _data := data                                                                 ' Setting _Command to other than 0 signals the PASM routine to load the _Device, _Address, and _Data values   
  _command := SINGLE_WRITE                                                      '  therefore, _Command must be set after the other parameters

  wait_for_ready
  result := _command                                                            ' Returns $FF if successful / $00 if no response from device (device not found)
  
PUB write_page(device,address,dataAddress,bytes)                                ' Write many bytes

  wait_for_ready                                                                
                                                                                
  _device := device << 1                                                        
  _address := address
  _data := dataAddress
  _bytes := bytes
  _command := PAGE_WRITE

  wait_for_ready
  result := _command

PUB command(device,comm)                                                        ' Write the device and address, no data.  Used in the altimeter

  wait_for_ready

  _device := device << 1
  _address := comm
  _command := SEND_COMMAND

  wait_for_ready
  result := _command
  
PUB read(device,address)                                                        ' Read a single byte

  wait_for_ready

  _device := device << 1
  _address := address
  _command := SINGLE_READ
  _data := 1
                    
  wait_for_ready
  result := _data

PUB read_next(device)                                                           ' Read from next address

  wait_for_ready

  _device := device << 1
  _command := REPEATED_READ

  wait_for_ready
  result := _data

PUB read_page(device,address,dataAddress,bytes)                                 ' Read many bytes

  wait_for_ready

  _device := device << 1
  _address := address
  _data := dataAddress
  _bytes := bytes
  _command := PAGE_READ

  wait_for_ready
  result := _command

PRI wait_for_ready | t

  t := cnt
  
  repeat until _Command == $00 or _Command == $FF                               ' _command is set to $FF upon success by PASM, or set to $00 if no response from device within 10ms
    if cnt - t > clkfreq / 10                                                  
      return false                                                              ' escape if no valid response from PASM routine (just in case--shouldn't ever happen)
  return true     

DAT                     org
entry
                        mov       t1,par                                        ' Load parameter addresses
                        rdlong    I2C_bit_delay,t1
                        add       t1,#4
                        mov       loops_address,t1
                        add       t1,#2
                        mov       address_address,t1
                        add       t1,#2
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
                        mov       t1,command_byte  
                        add       t1,#:jump_table                               ' Use value in Command_byte (1-6) to 
:jump_table             jmp       t1                                            '  determine which routine to jump to
                        jmp       #:write_byte
                        jmp       #:write_page
                        jmp       #:read_byte
                        jmp       #:read_next
                        jmp       #:read_page
                        jmp       #:send_command
'......................................................................................................................
:write_byte
                        mov       loop_counter,#1
                        mov       t2,data_address                               ' Retrieve the value to be sent from _data
                        jmp       #:write_entry
:write_page
                        rdword    loop_counter,loops_address
                        rdword    t2,data_address                               ' Retrieve the values to be sent from an array addressed by _data
:write_entry
                        call      #send_start                                   ' Send a start bit, device ID, and address
:write_loop
                        rdbyte    I2C_byte,t2                                   ' Read from the _data var or from an array
                        call      #I2C_write                                    '  and send the byte
                        add       t2,#1                                         '  increment the array address
          if_nc         djnz      loop_counter,#:write_loop                     ' Repeat until all bytes are sent, or stop if NAK
                        call      #I2C_stop
                        jmp       #main
'......................................................................................................................
:read_byte
                        call      #send_start                                   ' Send a start bit, device ID, and address
:read_next
                        mov       loop_counter,#1                               
                        mov       t2,data_address                               ' Store the read value in the _data var
                        jmp       #:read_entry
:read_page
                        call      #send_start                                   ' Send a start bit, device ID, and address
                        rdword    loop_counter,loops_address
                        rdword    t2,data_address                               ' Store the read values in an array addressed by the _data var
:read_entry
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
'......................................................................................................................
:send_command
                        call      #send_start
                        call      #I2C_stop
                        jmp       #main
'======================================================================================================================
send_start
                        mov       timeout,_10ms                                 ' Prepare a 10ms timeout (prevents routine from hanging if a device
                        add       timeout,cnt                                   '  becomes disconnected or unresponsive)
:loop
                        mov       t1,timeout                                    ' Check if 10ms has elapsed
                        sub       t1,cnt                                        '  Abort if it has
                        cmps      t1,#0                       wc
          if_c          jmp       #No_response
                        mov       I2C_byte,device_byte                          ' Send the start bit and device ID
                        call      #I2C_start                                    '  Device will respond with Ack or NAK if ready/not ready
                        call      #I2C_write                                      
          if_c          jmp       #:loop                                        ' Loop until device is ready (C is set if NAK)
                        mov       t1,device_byte                                ' Determine if device code is for EEPROM (%101_0xxx)
                        and       t1,#%1111_0000                                ' Clear chip select bits
                        cmp       t1,#%1010_0000              wz                ' Z is set if device is an EEPROM
          if_z          rdword    I2C_byte,address_address                      ' Send high byte of EEPROM address 
          if_z          shr       I2C_byte,#8
          if_z          call      #I2C_write
                        rdword    I2C_byte,address_address
                        call      #I2C_write
          if_c          jmp       #:loop                                        ' C is set if NAK (Some devices acknowledge the device code even when not ready)
send_start_ret          ret
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
address_address         res       1
loops_address           res       1
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