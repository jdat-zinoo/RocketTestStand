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
    adcSDApin=29
    adcSCLpin=28
    adcI2Cfreq=400_000
    launchPin = 23

    'status led
    'statusLedPin=-1

    ' protocol settings
    charEOF = $04
    charBreak = $18

dat
    errorWord   byte    "error: ",0
    dataFolder  byte    "/LOADCELL",0
''    webFolder   byte    "/WEB",0
OBJ
  ps    : "propshell"
  sd    : "DS1307_SD-MMC_FATEngine"
  ''debug : "my_PBnJ_serial"
  adc   : "I2C PASM adc"
VAR
  long shellstack[64]
  ''word rtbuffer[10_000]
  byte filename [26]
  byte filebuffer[512]
PUB main | errorNumber, errorString     
    adc.start(adcSCLpin,adcSDApin,adcI2Cfreq,launchPin)
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
{
pub createFile(forMe)| i,j,k
    if not forMe
        return

    sd.openFile(sd.newFile(string("/loadcell/a.txt")), "W")
    sd.writeString(string("Hello World!"))
    sd.closefile
    
    sd.openFile(sd.newFile(string("/loadcell/b.txt")), "W")
    sd.writeString(string("Hello World!"))
    sd.closefile
    
    sd.openFile(sd.newFile(string("/loadcell/c.txt")), "W")
    j:=0
    repeat 1000
        sd.writeString(string("Hello World! "))
        i := 1_000_000_000
        k:=j
        repeat 10
                if k => i
                        sd.writebyte(k / i + "0")
                        k //= i
                        result~~

                elseif result or i == 1
                        sd.writebyte("0")

                i /= 10
        sd.writebyte(13)
        j++
    sd.closefile
    ps.puts(string("done"))
    ps.crr
    ps.commandHandled
}
PRI cmdHandler(cmdLine)
  cmdList(ps.commandDef(string("LIST"), cmdLine))
  cmdDel(ps.commandDef(string("DEL"), cmdLine))
  cmdCat(ps.commandDef(string("CAT"), cmdLine))
  cmdTime(ps.commandDef(string("TIME"), cmdLine))
  ''createFile(ps.commandDef(string("CREATE"), cmdLine))
  return true

PUB trim(characters) '' 8 Stack Longs
  result := ignoreSpace(characters)
  characters := (result + ((strsize(result) - 1) #> 0))

  repeat
    case byte[characters]
      8 .. 13, 32, 127: byte[characters--] := 0
      other: quit
PRI ignoreSpace(characters) ' 4 Stack Longs
  result := characters
  repeat strsize(characters--)
    case byte[++characters]
      8 .. 13, 32, 127:
      other: return characters
pub printErrorWord
    ps.puts(@errorWord)
PRI ListFiles | entryName, count

  entryname:=\sd.changeDirectory(@dataFolder)
  count := sd.partitionError 
  if (count==sd#Entry_Not_Found)    'direcory no exist
      entryname:=\sd.newDirectory(@dataFolder)
      count := sd.partitionError 
      if (count)
        return
  entryname:=\sd.changeDirectory(@dataFolder)
  count := sd.partitionError 
      if (count)
        printErrorWord
        ps.puts(string("folder does not exist"))
        return
  count:=0
  sd.listEntries("W") ' Wrap around. 
  repeat while(entryName := sd.listEntries("N")) 
    if NOT sd.listIsDirectory
        count++
  ps.putd(count)
  if (count==0)
        return
  ps.crr
  repeat while(entryName := sd.listEntries("N"))     
    if NOT sd.listIsDirectory
        ps.puts(trim(sd.listName))
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
PUB concat(whereToPut, whereToGet) '' 5 Stack Longs

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Concatenates a string onto the end of another. This method can corrupt memory.
'' //
'' // Returns a pointer to the new string.
'' //
'' // WhereToPut - Address of the string to concatenate a string to.
'' // WhereToGet - Address of where to get the string to concatenate.
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  bytemove((whereToPut + strsize(whereToPut)), whereToGet, (strsize(whereToGet) + 1))
  return whereToPut

PRI cmdDel(forMe)|errorNumber, errorString
  if not forMe
    return

  ps.puts(string("DEL "))
  ps.parseAndCheck(1, string("error: no file specified", ps#lf), false)
  
  bytefill(filename,0,26)
  errorString:=concat(filename,@datafolder)
  errorString:=concat(filename,string("/"))
  errorString:=concat(filename,trim(ps.currentPar))

  errorString:=\sd.deleteEntry(filename)
  errorNumber:=sd.partitionError 
  if (errorNumber)
    printErrorWord
    ps.puts(errorString)
    ps.tx(" ")
    ps.putd(errorNumber)
    ps.crr
    ps.commandHandled
    return
  ps.puts(string("ok"))
  ps.crr
  ps.commandHandled
PRI cmdCat(forMe)| errorString,errorNumber
  if not forMe
    return
  ps.puts(string("CAT "))

  ps.parseAndCheck(1, string("error: no file specified", ps#lf), false)  

  bytefill(filename,0,26)
  errorString:=concat(filename,@datafolder)
  errorString:=concat(filename,string("/"))
  errorString:=concat(filename,trim(ps.currentPar))

  errorString:=\sd.openfile(filename,"R")
  errorNumber:=sd.partitionError 
  if (errorNumber)
    printErrorWord
    ps.puts(errorString)
    ps.tx(" ")
    ps.putd(errorNumber)
    ps.crr
    ps.tx(charEOF)
    ps.commandHandled
    return

  ps.putd(sd.fileSize)
  ps.crr
  
  repeat until(sd.fileTell == sd.fileSize)
    sd.readString(@filebuffer, 512)
    ps.puts(@filebuffer)
  'filename=ps.currentPar
  ' ps.puts(filecontents) from sd card here
  ' if error printing
  '   ps.puts(string("C error: error reading, file not exist or SD card error"))
  '   abort ' returns with error    
  ' and send to serial with ps.puts(string) function
  ''ps.puts(ps.currentPar)
  ''ps.puts(string(ps#cr))  

  ps.tx(charEOF)
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
    ps.puts(string("wrong year"))
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
    printErrorWord
    ps.puts(string("wrong day"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(4, string("error: hours missing", ps#lf), true)
  ho:=ps.currentParDec
  if (ho<0) or (ho>23)
    printErrorWord
    ps.puts(string("wrong hours"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(5, string("error: minutes missing", ps#lf), true)
  mi:=ps.currentParDec
  if (mi<0) or (mi>59)
    printErrorWord
    ps.puts(string("wrong minutes"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(6, string("error: seconds missing", ps#lf), true)
  se:=ps.currentParDec
  if (se<0) or (se>59)
    printErrorWord
    ps.puts(string("wrong seconds"))
    ps.crr
    return ps.commandHandled

  ps.parseAndCheck(7, string("error: day of week missing", ps#lf), true)
  dow:=ps.currentParDec
  if (dow<1) or (dow>7)
    printErrorWord
    ps.puts(string("wrong day of week"))
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