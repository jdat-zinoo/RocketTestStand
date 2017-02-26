{{
// Based on
// PROPELLER COMMAND SHELL - LED SHELL EXAMPLE "Human 2 Machine"
// Author: Stefan Wendler
}}

CON

  '' Clock settings

  _CLKMODE = XTAL1 + PLL16X                             ' External clock at 80MHz
  _XINFREQ = 5_000_000

  '' Serial port settings for shell
  BAUD_RATE     = 115_200

  RX_PIN                = 31
  TX_PIN                = 30

OBJ

  ps    : "propshell"

VAR

  '' none

PUB main

  ps.init(false, false, BAUD_RATE, RX_PIN, TX_PIN)

  repeat

    result := ps.prompt
    
    ''if not ps.isEmptyCmd(result)
    ''  \cmdHandler(result)
    if \cmdHandler(result) and not ps.isEmptyCmd(result)
      ps.puts(string("Unknown kommand. Use ? for help.", ps#CR, ps#LF))

PRI cmdHandler(cmdLine)

'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
'' // Command handler. All shell commands are defined here.
'' //
'' // @param                    cmdLine                 Input to parse (from promt)
'' // @return                                           ture if cmdLine was NOT handled
'' ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  '' Each command needs to have a single parameter: the result of ps.commandDef.
  '' Each ps.commandDef takes three parameters:
  '' - 1  name of command
  '' - 2  help/descriptoin for command (or false if no help)
  '' - 3  command line to check command against

  cmdList(ps.commandDef(string("l"), false, cmdLine))
  cmdDel(ps.commandDef(string("d"), false, cmdLine))
  cmdCat(ps.commandDef(string("c"), false, cmdLine))
  cmdTime(ps.commandDef(string("t"), false, cmdLine))
  return true

PRI cmdList(forMe)

  if not forMe
    return

  ' get dir list from sd card here
  ' if error listing
  '   ps.puts(string("L error:SD card error"))
  '   abort ' returns with error 
  '   
  ' and send to serial with ps.puts(string) function
  ps.puts(string("List command"))

  ps.commandHandled

PRI cmdDel(forMe)

  if not forMe
    return

  ps.parseAndCheck(1, string("D error:no file specified"), false)
  
  'filename=ps.currentPar
  ' delete file from sd card here
  ' if error deleting
  '   ps.puts(string("D error: error deleting, file not exist or SD card error"))
  '   abort ' returns with error 
  '   
  ' and send to serial with ps.puts(string) function
  ps.puts(ps.currentPar)

  ps.commandHandled

PRI cmdCat(forMe)

  if not forMe
    return

  ps.parseAndCheck(1, string("C error:no file specified"), false)
  
  'filename=ps.currentPar
  ' ps.puts(filecontents) from sd card here
  ' if error printing
  '   ps.puts(string("C error: error reading, file not exist or SD card error"))
  '   abort ' returns with error 
  '   
  ' and send to serial with ps.puts(string) function
  ps.puts(ps.currentPar)
  
  ps.commandHandled

PRI cmdTime(forMe)

  if not forMe
    return

  if \ps.parseAndCheck(1, string("ttt"), false)
  '' ps.puts(time and date string)  ' there is no parameter, return current date and time
     ps.puts(string("It's 2017-03-01 16:00:00 Wed"))
     ps.commandHandled
     return     
  'datestring=ps.currentPar
  ps.puts(ps.currentPar)
  ps.parseAndCheck(2, string("T error:time missing"), false)
  'timestring=ps.currentPar
  ps.puts(ps.currentPar)
  ps.parseAndCheck(3, string("T error:day of week"), true)
  ps.puts(ps.currentPar)
  'dayofweek=ps.currentParDec
  '
  ' set time to rtc
  ' if error listing
  '   ps.puts(string("T error:i2c error"))
  '   abort ' returns with error 
  '   
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