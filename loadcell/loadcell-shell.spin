{{
// Based on
// PROPELLER COMMAND SHELL - LED SHELL EXAMPLE "Human 2 Machine"
// Author: Stefan Wendler
// Modified by JDat
}}
CON
  '' Clock settings
  _CLKMODE = XTAL1 + PLL16X                             ' External clock at 80MHz
  _XINFREQ = 5_000_000
  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  '' Serial port settings for shell
  BAUD_RATE     = 115_200
  RX_PIN                = 31
  TX_PIN                = 30
  
  ''SD card settings
  sdDOpin=13
  sdCLKpin=15
  sdDIpin=18
  sdCSpin=19
  sdWPpin=-1
  sdCDpin=-1
  
  rtcSDApin=4
  rtcSCLpin=3
  I2CLock=-1
  
  ''ADC setting
  ''adcSDApin=29
  ''adcSCLpin=28

  ''launch pin
  launchPin=23
  'status led
  'statusLedPin=-1
OBJ
  ps    : "propshell"
  sd    : "DS1307_SD-MMC_FATEngine"
  ''debug : "my_PBnJ_serial"
  adc   : "I2C PASM driver v1.4"
VAR
  '' none
  long shellstack[512]
  word rtbuffer[10_000]
  
PUB main | errorNumber, errorString 
    
    ''debug.Start(rx_Pin, tx_Pin, baud_Rate)
    cognew(runshell,@shellstack)        

PRI howToUseListEntries | entryName 
  sd.listEntries("W") ' Wrap around. 
  repeat while(entryName := sd.listEntries("N")) 
    ps.puts(sd.listName)
    ps.tx(9)
{
    debug.Dec(sd.listSize)     
    debug.tx(9)
    debug.Dec(sd.listCreationYear)
    debug.tx(".")
    debug.Dec(sd.listCreationMonth)
    debug.tx(".")
    debug.Dec(sd.listCreationDay)
    debug.tx(".")
    debug.tx(9)
    debug.Dec(sd.listCreationHours)     
    debug.tx(":")
    debug.Dec(sd.listCreationMinutes) 
    debug.tx(":")
    debug.Dec(sd.listCreationSeconds) 
    debug.tx(9)

    debug.Dec(sd.listAccessYear)
    debug.tx(".")
    debug.Dec(sd.listAccessMonth) 
    debug.tx(".")
    debug.Dec(sd.listAccessDay) 
    debug.tx(9)
}
    ps.putd(sd.listModificationYear)
    ps.tx(".")
    ps.putd(sd.listModificationMonth) 
    ps.tx(".")
    ps.putd(sd.listModificationDay)
    ps.tx(".")
    ps.tx(9)
    
    ps.putd(sd.listModificationHours)
    ps.tx(":")
    ps.putd(sd.listModificationMinutes)
    ps.tx(":")
    ps.putd(sd.listModificationSeconds)
    ps.tx(9)
{
    sd.listIsReadOnly 
    sd.listIsHidden 
    sd.listIsSystem 
    sd.listIsDirectory 
    sd.listIsArchive 
}
    ps.crr

pub runshell | errorNumber, errorString 
    ps.init(RX_PIN, TX_PIN, BAUD_RATE)
    
    ps.puts(string("serial init"))
    ps.crr
    ''repeat
    
    
    sd.FATEngineStart(sdDOPin, sdCLKPin, sdDIPin, sdCSPin, sdWPPin, sdCDPin, rtcSDAPin, rtcSCLPin, I2CLock) 
    errorString := \sd.mountPartition(0) ' Returns the address of the error string or null. 
    errorNumber := sd.partitionError ' Returns the error number or zero. 
    if(errorNumber) ' Light a LED if an error occurs.     
        ps.puts(string("fat engine error: "))
        ps.puts (errorstring)
        ps.tx(9)
        ps.puts (errorNumber)
        ps.crr
        repeat
    else
        ps.puts(string("RTC: "))
        ps.bin(sd.readClock,32)
        ps.crr

        ps.puts(string("SD mount complete"))
        ps.crr
        repeat
            result := ps.prompt
            if not ps.isEmptyCmd(result)
              \cmdHandler(result)

PRI cmdHandler(cmdLine)
  cmdList(ps.commandDef(string("LIST"), cmdLine))
  cmdDel(ps.commandDef(string("DEL"), cmdLine))
  cmdCat(ps.commandDef(string("CAT"), cmdLine))
  cmdTime(ps.commandDef(string("TIME"), cmdLine))
  return true
PRI cmdList(forMe)
  if not forMe
    return
  ''ps.puts(string("got"))
  ' get dir list from sd card here
  howToUseListEntries    
  ' if error listing
  '   ps.puts(string("L error:SD card error"))
  '   abort ' returns with error 
  '   
  ' and send to serial with ps.puts(string) function
  ''ps.puts(string("List command", ps#cr))
  ps.commandHandled
PRI cmdDel(forMe)
  if not forMe
    return
  ps.parseAndCheck(1, string("D error:no file specified", ps#cr), false)  
  'filename=ps.currentPar
  ' delete file from sd card here
  ' if error deleting
  '   ps.puts(string("D error: error deleting, file not exist or SD card error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))
  ps.commandHandled
PRI cmdCat(forMe)
  if not forMe
    return
  ps.parseAndCheck(1, string("C error:no file specified", ps#cr), false)  
  'filename=ps.currentPar
  ' ps.puts(filecontents) from sd card here
  ' if error printing
  '   ps.puts(string("C error: error reading, file not exist or SD card error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))  
  ps.commandHandled
PRI cmdTime(forMe)
  if not forMe
    return
  if \ps.parseAndCheck(1, false, false)
  '' ps.puts(time and date string)  ' there is no parameter, return current date and time
     ps.puts(string("It's 2017-03-01 16:00:00 Wed", ps#cr))
     ps.commandHandled
     return     
  'datestring=ps.currentPar
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))  
  ps.parseAndCheck(2, string("T error:time missing", ps#cr), false)
  'timestring=ps.currentPar
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))  
  ps.parseAndCheck(3, string("T error:day of week", ps#cr), true)
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))  
  'dayofweek=ps.currentParDec
  ' set time to rtc
  ' if error listing
  '   ps.puts(string("T error:i2c error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ps.commandHandled
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