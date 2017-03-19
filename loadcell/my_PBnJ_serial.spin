{{
// Based on 
// PBnJ_serial: Precision, Basic, no Jitter serial I/O driver.
// (c) Copyright 2011 Philip C. Pilgrim
// Modified by JDat
}}
CON
  IMAX          = 32             'Input buffer size  (must be less than 512, but needn't be a power of 2).
  OMAX          = 256            'Output buffer size (ditto).
VAR
  long  timedelay,inpmask,outmask
  word  ienqueue, idequeue, oenqueue, odequeue
  byte  ibuffer[IMAX], obuffer[OMAX], cogno
PUB start(ipin, opin, baud)
'' Start the UART:
''   ipin is the input pin.
''   opin is the output pin.
''   baud is the baudrate for both xmt and rcv.
  stop
  timedelay := (clkfreq + baud * 3) / (baud * 6)
  inpmask := 1 << ipin
  outmask := 1 << opin
  long[@ienqueue]~
  long[@oenqueue]~
  return cogno := cognew(@pbj, @timedelay) + 1
PUB stop
'' Stop the UART.
  if (cogno)
    cogstop(cogno - 1)
    cogno~
PUB rxflush
'' Flush receive buffer
  idequeue := ienqueue  
PUB rxcheck : rxbyte
'' Check if byte received (never waits)
'' returns -1 if no byte received, $00..$FF if byte
  rxbyte~~
  if (idequeue <> ienqueue)
    rxbyte := rx 
PUB rxtime(ms) : rxbyte | t, limit
'' Wait ms milliseconds for a byte to be received
'' returns -1 if no byte received, $00..$FF if byte
  limit := clkfreq / 1000 * ms
  t := cnt
  repeat until (rxbyte := rxcheck) => 0 or (cnt - t) > limit  
PUB rx : rxbyte
'' Receive byte (blocks for byte)
'' Returns received byte.
  repeat while (idequeue == ienqueue)
  rxbyte := ibuffer[idequeue]
  idequeue := (idequeue + 1) // IMAX
PUB tx(txbyte) | newenq
'' Send byte (blocks for room in buffer)
  newenq := (oenqueue + 1) // OMAX
  repeat while (odequeue == newenq)
  obuffer[oenqueue] := txbyte
  oenqueue := newenq
PUB cr
  tx(13)
PUB lf
  tx(10)
pub crlf
 cr
 lf
pub lfcr
  lf
  cr
PUB space
  tx(32)  
PUB str(stringptr)
'' Send string                    
  repeat strsize(stringptr)
    tx(byte[stringptr++])
PUB rxLine(stringPtr,stringSize)|a,b,c
''    read line for data until cr or lf occures  
    b:=stringSize-2
    c:=stringPtr
    repeat while b>0
        a:=rx ''time(100)
        if ((a==13) or (a==10))
            byte[stringptr]:=a
            stringptr++
            byte[stringptr]:=0 
            return c
        byte[stringptr]:=a
        stringptr++
        b--
    byte[stringptr]:=13
    stringptr++    
    byte[stringptr]:=0    

PUB Dec(value) | i, x
''   example usage: serial.Dec(-1_234_567_890)
  x := value == NEGX                                    'Check for max negative
  if value < 0
    value := ||(value+x)                                'If negative, make positive; adjust for max negative
    Tx("-")                                             'and output sign
  i := 1_000_000_000                                    'Initialize divisor
  repeat 10                                             'Loop for 10 digits
    if value => i                                                               
      Tx(value / i + "0" + x*(i == 1))                  'If non-zero digit, output digit; adjust for max negative
      value //= i                                       'and digit from value
      result~~                                          'flag non-zero found
    elseif result or i == 1
      Tx("0")                                           'If zero digit (or only digit) output it
    i /= 10                                             'Update divisor
PUB Hex(value, digits)
{
   Transmit the ASCII string equivalent of a hexadecimal number
   Parameters: value = the numeric hex value to be transmitted
''             digits = the number of hex digits to print                 
   example usage: serial.Hex($AA_FF_43_21, 8)
   expected outcome of example usage call: Will print the string "AAFF4321" to a listening terminal.
}
  value <<= (8 - digits) << 2
  repeat digits                                         'do it for the number of hex digits being transmitted
    Tx(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))'  Transmit the ASCII value of the hex characters
PUB Bin(value, digits)
{
   Transmit the ASCII string equivalent of a binary number
   Parameters: value = the numeric binary value to be transmitted
''             digits = the number of binary digits to print                 
   return:     none
   example usage: serial.Bin(%1110_0011_0000_1100_1111_1010_0101_1111, 32)
   expected outcome of example usage call: Will print the string "11100011000011001111101001011111" to a listening terminal.
}
  value <<= 32 - digits
  repeat digits
    Tx((value <-= 1) & 1 + "0")                         'Transmit the ASCII value of each binary digit

DAT
              org 0
pbj           mov       iptr,par                'Point to timedelay and initialize a bunch of stuff.
              rdlong    sixthbit,iptr           '(This oughta keep those "language-neutral" folks happy!)
              add       iptr,#4
              rdlong    imask,iptr
              add       iptr,#4
              rdlong    omask,iptr
              add       iptr,#4
              mov       ienqaddr,iptr
              add       iptr,#2
              mov       ideqaddr,iptr
              add       iptr,#2
              mov       oenqaddr,iptr
              add       iptr,#2
              mov       odeqaddr,iptr
              add       iptr,#2
              mov       ibufaddr,iptr
              add       iptr,#IMAX
              mov       obufaddr,iptr
              or        outa,omask              'Enable output pin,
              or        dira,omask              '  and set to mark state.
              mov       iptr,sixthbit           'Make sure out bit is mark for four character times.
              shl       iptr,#8
              mov       timer,cnt
              add       timer,iptr              
              waitcnt   timer,sixthbit
              
              jmp       #rcv_char               'Start with receiver.      
coroutine
coroutine_ret jmp       #xmt_char               'Coroutine seeded with transmitter.

'-------[ RECEIVER ]-----------------------------------------------------------

rcv_char      waitcnt   timer,sixthbit          'Sync to clock.
              test      imask,ina wc            'Is input low?
        if_nc jmp       #:start_bit             '  Yes: Maybe a start bit.

:no_start     call      #coroutine              '  No:  Come back 1/3 bit later,
              jmp       #rcv_char               '       and try again.

:start_bit    call      #coroutine              'Come back 1/3 bit later.
              waitcnt   timer,sixthbit          'Sync to clock.
              test      imask,ina wc            'Is input still low?
        if_c  jmp       #:no_start              '  No:  False alarm.

:got_start    call      #r_full                 '  Yes: Come back one full bit time later.

              mov       ibitcnt,#8              'Initialize bit count.

:bit_lp       waitcnt   timer,sixthbit          'Sync to clock.
              test      imask,ina wc            'Carry = input bit.            
              rcr       ichar,#1                'Rotate into character.
              call      #r_full                 'Come back a full bit time later.
              djnz      ibitcnt,#:bit_lp        'Back for another bit, or check stop bit.

              waitcnt   timer,sixthbit          'Sync to clock.
              test      imask,ina wc            'Valid stop bit?
        if_c  jmp       #:stop_ok               '  Yes: Go queue the character.

:fr_err_lp    call      #coroutine              '  No:  Framing error. Come back 1/3 bit later.
              waitcnt   timer,sixthbit          '       Sync to clock.
              test      imask,ina wc            '       "Stop" still low?
        if_nc jmp       #:fr_err_lp             '          Yes: Continue error loop.

              jmp       #:end_fr_err            '          No:  Framing error has passed.

:stop_ok      shr       ichar,#24               'Fix up received character.
              mov       iptr,ibufaddr           'Compute pointer to place in buffer.
              add       iptr,ienq
              mov       nxtenq,ienq             'Begin compute of next enqueue location.
              wrbyte    ichar,iptr              'Write the character to the buffer.
              call      #coroutine              'Return after 1/3 bit time.
              add       nxtenq,#1               'Finish computing next location
              cmpsub    nxtenq,#IMAX            '  modulo IMAX.
              rdword    ideq,ideqaddr           'Get the dequeue pointer.
              cmp       nxtenq,ideq wz          'Buffer full?
        if_nz mov       ienq,nxtenq             '  No:  Update enqueue pointer.
        if_nz wrword    ienq,ienqaddr

:end_fr_err   jmp       #rcv_char               'Start polling for start bit again.

r_full        call      #coroutine              'Bounce back to coroutine.
              waitcnt   timer,sixthbit          'Sync to clock.
              call      #coroutine              'Bounce back again.
              waitcnt   timer,sixthbit          'Sync to clock.
              call      #coroutine              'Bounce back a third time (or immediately).
r_full_ret    ret

'-------[ TRANSMITTER ]--------------------------------------------------------


try_again     call      #x_third                'Internal lead-in to xmt_char                

xmt_char      mov       optr,obufaddr           'Compute pointer to next character.
              add       optr,odeq
              rdword    oenq,oenqaddr           'Get the enqueue pointer.
              cmp       oenq,odeq wz            'Same as dequeue pointer?
        if_z  jmp       #try_again              '  Yes: Buffer is empty. Keep trying.

              waitcnt   timer,sixthbit          '  No:  Sync to clock.
              andn      outa,omask              '       Send start bit.
              call      #x_full                 '       Come back after one bit time.
              rdbyte    ochar,optr              '       Read the buffered character.
              add       odeq,#1                 '       Increment the dequeue pointer,
              cmpsub    odeq,#OMAX              '         modulo OMAX.       
              wrword    odeq,odeqaddr           '       Write new pointer back to hub.
              
:do_chr       mov       obitcnt,#9              'Initialize bit count (8 + stop).
              or        ochar,#$100             'Or in the stop bit.

:bit_lp       shr       ochar,#1 wc             'Shift next bit into carry
              waitcnt   timer,sixthbit          'Sync to clock.
              muxc      outa,omask              'MUX the bit to the pin.
              call      #x_full                 'Come back a full bit later.
              djnz      obitcnt,#:bit_lp        'Back for another bit, or done.

              call      #x_third                'Done: add 1/3 bit to stop for better sync.
              jmp       #xmt_char               'Check for another character.

x_full        call      #coroutine              'Bounce back to coroutine.
              waitcnt   timer,sixthbit          'Sync to clock.
              call      #coroutine              'Bounce back again.
x_third       waitcnt   timer,sixthbit          'Sync to clock.
              call      #coroutine              'Bounce back a third time (or immediately).

x_third_ret
x_full_ret    ret

'-------[ Variables ]----------------------------------------------------------

odeq          long      0
ienq          long      0

sixthbit      res       1
imask         res       1
omask         res       1
ienqaddr      res       1
ideqaddr      res       1
oenqaddr      res       1
odeqaddr      res       1
ibufaddr      res       1
obufaddr      res       1
timer         res       1
ibitcnt       res       1
obitcnt       res       1
ichar         res       1
ochar         res       1
oenq          res       1
ideq          res       1
optr          res       1
iptr          res       1
nxtenq        res       1

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