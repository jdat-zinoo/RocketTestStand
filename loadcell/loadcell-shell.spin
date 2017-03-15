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
    BAUD_RATE = 115_200
    RX_PIN = 31
    TX_PIN = 30
    
    ''SD card settings
    sdDOpin = 13
    sdCLKpin = 15
    sdDIpin = 18
    sdCSpin = 19
    sdWPpin = -1
    sdCDpin = -1
    
    rtcSDApin = 4
    rtcSCLpin = 3
    I2CLock = -1
    
    ''ADC setting
    ''adcSDApin=29
    ''adcSCLpin=28
    
    ''launch pin
    launchPin = 23
    'status led
    'statusLedPin=-1

    ' protocol settings
    charEOF = $04
    charBreak = $18

    ''dataFolder = "LOADCELL"
    ''webFolder = "WEB"
OBJ
  ps    : "propshell"
  sd    : "DS1307_SD-MMC_FATEngine"
  ''debug : "my_PBnJ_serial"
  adc   : "I2C PASM driver v1.4"
VAR
  long shellstack[128]
  word rtbuffer[10_000]
PUB main | errorNumber, errorString     
    ''debug.Start(rx_Pin, tx_Pin, baud_Rate)
    cognew(runshell,@shellstack)        

pub runshell | errorNumber, errorString 
    ps.init(RX_PIN, TX_PIN, BAUD_RATE)
    ps.crr
    sd.FATEngineStart(sdDOPin, sdCLKPin, sdDIPin, sdCSPin, sdWPPin, sdCDPin, rtcSDAPin, rtcSCLPin, I2CLock) 
    errorString := \sd.mountPartition(0) ' Returns the address of the error string or null. 
    errorNumber := sd.partitionError ' Returns the error number or zero. 
    if(errorNumber) ' error mountung SD card    
        repeat  ' stall. repeat foerver because SD card error
    else
                ' sd mount complete
                
        repeat  ' main shell loop
            result := ps.prompt
            if not ps.isEmptyCmd(result)
              \cmdHandler(result)

pub createFile
    
PRI cmdHandler(cmdLine)
  cmdList(ps.commandDef(string("LIST"), cmdLine))
  cmdDel(ps.commandDef(string("DEL"), cmdLine))
  cmdCat(ps.commandDef(string("CAT"), cmdLine))
  cmdTime(ps.commandDef(string("TIME"), cmdLine))
  return true

PRI ListFiles | entryName, count

  entryname:=\sd.changeDirectory(string("/LOADCELL"))
  count := sd.partitionError 
  if (count==sd#Entry_Not_Found)    'direcory no exist
      entryname:=\sd.newDirectory(string("/LOADCELL"))
      count := sd.partitionError 
      if (count)
        return
  entryname:=\sd.changeDirectory(string("/LOADCELL"))
  count := sd.partitionError 
      if (count)
        ps.puts(string("error: folder does not exist"))
        return
  count:=0
  sd.listEntries("W") ' Wrap around. 
  repeat while(entryName := sd.listEntries("N")) 
    if NOT sd.listIsDirectory
        count++
  ps.putd(count)
  if (count==0)
        return
  repeat while(entryName := sd.listEntries("N"))     
    if NOT sd.listIsDirectory
        ps.puts(sd.listName)
        ps.tx(" ")
    
        ps.putd(sd.listSize)     
        ps.tx(" ")
    {
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
        ps.tx(" ")
        
        ps.putd(sd.listModificationHours)
        ps.tx(":")
        ps.putd(sd.listModificationMinutes)
        ps.tx(":")
        ps.putd(sd.listModificationSeconds)
        ''ps.tx(" ")
    {
        sd.listIsReadOnly 
        sd.listIsHidden 
        sd.listIsSystem 
        sd.listIsDirectory 
        sd.listIsArchive 
    }
    ps.crr

PRI cmdList(forMe)
  if not forMe
    return
  ps.puts(string("LIST "))
  ' get dir list from sd card here
  ListFiles

  ps.tx(charEOF)
  ps.commandHandled
PRI cmdDel(forMe)|errorNumber, errorString 
  if not forMe
    return
  ps.parseAndCheck(1, string("DEL error: no file specified", ps#lf), false)
  
  ps.puts(string("DEL "))
  
  errorString:=\sd.deleteEntry(ps.currentPar)
  errorNumber:=sd.partitionError 
  if (errorNumber)
    ps.puts(string("error: "))
    ps.puts(errorString)
    ps.tx(" ")
    ps.putd(errorNumber)
    ps.crr
    ps.commandHandled
    return
  'filename=ps.currentPar
  ' delete file from sd card here
  ' if error deleting
  '   ps.puts(string("D error: error deleting, file not exist or SD card error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ps.puts(string("ok"))
  ps.crr
  ps.commandHandled
PRI cmdCat(forMe)
  if not forMe
    return
  ps.parseAndCheck(1, string("CAT error: no file specified", ps#lf), false)  
  'filename=ps.currentPar
  ' ps.puts(filecontents) from sd card here
  ' if error printing
  '   ps.puts(string("C error: error reading, file not exist or SD card error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ps.puts(ps.currentPar)
  ps.puts(string(ps#cr))  
  ps.commandHandled
PRI cmdTime(forMe)| ye, mo, de, ho, mi, se, dow, a
  if not forMe
    return
  ps.puts(string("TIME "))
  if \ps.parseAndCheck(1, false, true)  ' there is no parameter, return current date and time
     a:=sd.rtcGet
     ps.putd( 1980+( (word[a][1] & constant($ff<<9) ) >>9) ) ' year
     ps.tx(" ")
     ps.putd( (word[a][1] & constant($0f<<5) ) >>5 ) ' month
     ps.tx(" ")
     ps.putd( (word[a][1] & constant($1f) ) )       ' date

     ps.tx(" ")
     ps.putd( (word[a][0] & constant($1f<<11) ) >>11  )  ' hours
     ps.tx(" ")
     ps.putd( (word[a][0] & constant($3f<<5) ) >>5 )        ' minutes
     ps.tx(" ")
     ps.putd( (word[a][0] & constant($1f) ) <<1 )        ' seconds
     ps.crr
     ps.commandHandled
     return     

  ye:=ps.currentParDec
  if (ye<2017) or (ye>2050)
    ps.puts(string("error: wrong year"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(2, string("error: month missing", ps#lf), true)
  mo:=ps.currentParDec
  if (mo<1) or (mo>12)
    ps.puts(string("error: wrong month"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(3, string("error: date missing", ps#lf), true)
  de:=ps.currentParDec
  if (de<1) or (de>31)
    ps.puts(string("error: wrong day"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(4, string("error: hours missing", ps#lf), true)
  ho:=ps.currentParDec
  if (ho<0) or (ho>23)
    ps.puts(string("error: wrong hours"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(5, string("error: minutes missing", ps#lf), true)
  mi:=ps.currentParDec
  if (mi<0) or (mi>59)
    ps.puts(string("error: wrong minutes"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(6, string("error: seconds missing", ps#lf), true)
  se:=ps.currentParDec
  if (se<0) or (se>59)
    ps.puts(string("error: wrong seconds"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(7, string("error: day of week missing", ps#lf), true)
  dow:=ps.currentParDec
  if (dow<1) or (dow>7)
    ps.puts(string("error: wrong day of week"))
    ps.crr
    return ps.commandHandled
  
  sd.rtcWriteTime(se, mi, ho, dow, de, mo, ye)
  ps.puts(string("set"))
  ps.crr
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