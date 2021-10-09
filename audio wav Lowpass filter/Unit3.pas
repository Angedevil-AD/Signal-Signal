// By M.Aek Progs Angedevil
// Wav audio Low pass filter
unit Unit3;

interface

uses
  Winapi.Windows,math,System.VarCmplx, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, VclTee.TeeGDIPlus,
  VCLTee.TeEngine, VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;



var
Form3: TForm3;
ba,bps,brate,srate,chn:integer;
timelen,samplecount:integer;//
implementation

{$R *.dfm}








procedure TForm3.Button1Click(Sender: TObject);
var
fin:tfilestream;
fout:tfilestream;
wavinfopos:integer;
inp:array [0..255] of byte;
i,j:integer;
ascii:string;
len:integer;
af:integer;
found:integer;
f,fcut,angular_freq:double;
X:double;
flen:longint;
accu:double;
sumation:double;
retval : integer;
indata:array [0..512] of smallint;
outdata:array [0..512] of smallint;
sincdata:array [0..512] of double;
block:array [0..512] of double;
tmpdata:array [0..512] of double;
filter:array [0..512] of double;
win:array [0..512] of double;
bbb:integer;
fff: textfile;
begin
found:= 0;
ascii:='';
fin:= tfilestream.Create('test.wav',fmopenread);
//get RIFF .. rif = ascii 4byte ..len :4byte .. format ..4byte
memo1.Lines.Add('RIFF::');
memo1.Lines.Add('');
fin.Read(inp,4);
for I := 0 to 3 do
ascii := ascii + chr(inp[i]);
memo1.Lines.Add('Ascii: '+ascii);

fin.Read(inp,4);// get len
len := inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
memo1.Lines.Add('Len: '+inttostr(len));

fin.Read(inp,4);
ascii := '';
for I := 0 to 3 do
ascii := ascii+chr(inp[i]);
memo1.Lines.Add('Format: '+ascii);//

//now get FMT
//fmt : ascii: 4byte ..len:4byte ..audio format:2byte ..channel num:2byte
//samplerate:4byte..byterate: 4byte..block align :2byte .. bps: 2byte
memo1.Lines.Add('FMT::');
found:=-1;
memo1.Lines.Add('');
fin.Read(inp,4);
ascii := '';
for I := 0 to 3 do
ascii := ascii+chr(inp[i]);
if(ascii<>'fmt ') then begin // if ascii not equal to fmt then we must loop
//until we find the fmt
found := 0;
while(fin.Position < fin.Size-4) do begin
ascii :='';
fin.Read(inp,4); // get len
len := inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
// here ... if pos + len > size break;
if(fin.Position+len>fin.Size) then
break;
fin.Read(inp,len); // bypass this ...
fin.Read(inp,4);// get ascii again
for I := 0 to 3 do
ascii := ascii+chr(inp[i]);
if(ascii = 'fmt ') then begin
found := 1;
break;
end;
end;

end;

if (found = 0) then begin

fin.Free;
exit;
end;

memo1.Lines.Add('Ascii: '+ascii); // fmt ok
fin.Read(inp,4); // get len
len := inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
memo1.Lines.Add('Len: '+inttostr(len));


//get audio format
fin.Read(inp,2);// get af
af := inp[1] shl 8 or inp[0];
memo1.Lines.Add('Audio format: '+inttostr(af));

//get number of channels
fin.Read(inp,2);
chn := inp[1] shl 8 or inp[0];
memo1.Lines.Add('Num channels: '+inttostr(chn));

//get samplerate
fin.Read(inp,4); //get srate
srate :=inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
memo1.Lines.Add('Samplerate: '+inttostr(srate));

//get byterate
fin.Read(inp,4);
brate :=inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
memo1.Lines.Add('Byterate: '+inttostr(brate));

//get block align
fin.Read(inp,2);//
ba:= inp[1] shl 8 or inp[0];
memo1.Lines.Add('Blockalign: '+inttostr(ba));

//get bps
fin.Read(inp,2);
bps := inp[1] shl 8 or inp[0];
memo1.Lines.Add('Bps: '+inttostr(bps));//


//we done with fmt
//now get DATA Section

memo1.Lines.Add('DATA::');
memo1.Lines.Add('');
ascii := '';
fin.Read(inp,4);
found := -1; //
for I := 0 to 3 do
ascii := ascii +chr(inp[i]);

if(ascii<>'data') then begin // its like the loop above
found := 0;
while(fin.Position<fin.Size-4) do begin
ascii :=   '';
fin.Read(inp,4);//getlen
len :=inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];
if fin.Position+len>fin.Size then break;

fin.Read(inp,len);// bypass
fin.Read(inp,4);//ascii again
for I := 0 to 3 do
ascii := ascii+chr(inp[i]);
if(ascii='data') then begin
found := 1;
break;
end;
end;
end;

//check
if(found =0) then begin
fin.Free;
exit;
end;

memo1.Lines.Add('Ascii: '+ascii);
//get len .....
fin.Read(inp,4);//
len :=  inp[3] shl 24 or inp[2] shl 16 or inp[1] shl 8 or inp[0];//
memo1.Lines.Add('Len: '+inttostr(len));

// get Sample count
//sample count = samplerate * time
//time:= len / (chn * bps/8)  /sample rate ...
// so :
timelen := len div (chn * (bps div 8)) div srate  ;//
samplecount := srate * timelen;

memo1.Lines.Add('Timelen : '+inttostr(timelen));
memo1.Lines.Add('Sample count: '+inttostr(samplecount));

// so far so good ...
// we done with wave struct & info
// all next data (after len) called samples
// sample = 4byte;
//first 2byte: L (left channel)
//second 2byte: R (Right channel)
// all of those sample make an audio signal ()
//after we get signal we can add a filter to it .. like lowpass high pass
// .......ext


wavinfopos := fin.Position;
//firstofall we need to compute filter
// filter = sinc function * window function
//sinc fgunction ::
// sinc = sin(X)/X
// we need fcut : cuttoff frequency && flen .. flen <=40 flen must be odd number
fcut := 90;// hz
Flen := 31;//

//

f  := fcut / srate;// get factor
angular_freq := 2*PI*f;
memo1.Lines.Add(floattostr(angular_freq));
// for -I/2 <i< I/2
for I := 0 to flen-1 do begin
X:= angular_freq *(i-(flen-1)/2.0); //corrected
if(X=0) then sincdata[i] := 1.0
else

sincdata[i] := (sin(X))/X; //corrected
end;


{
/////////////////////////////////////////////////////
assignfile(fff,'log.txt');
rewrite(fff);
writeln(fff,'SINC:');
for I := 0 to flen-1 do begin
if (i>2) and (i mod 8 = 0) then
writeln(fff,' ');
write(fff,floattostr(round(sincdata[i]*100000)/100000)+' ');

end;
}

//now calcul Window..
//hann window is the most popular
for I := 0 to flen-1 do begin
win[i] := 0.5-(0.5*cos(2*PI*i/(flen-1)));
end;


{
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,'Hann:');
for I := 0 to flen-1 do begin
if (i>2) and (i mod 8 = 0) then
writeln(fff,' ');
write(fff,floattostr(round(win[i]*100000)/100000)+' ');
end;
}


//filter
for I := 0 to flen-1 do begin
filter[i] := sincdata[i] * win[i];
end;

//accumulate & normaliz

accu := 0;
for I := 0 to flen-1 do begin
accu := accu + filter[i];
end;


for I := 0 to flen-1 do begin
filter[i] :=filter[i] / accu;
end;



{
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,'Filter = Hann * SINC:');
for I := 0 to flen-1 do begin
if (i>2) and (i mod 8 = 0) then
writeln(fff,' ');
write(fff,floattostr(round(filter[i]*100000)/100000)+' ');
end;
}



for I := 0 to 511 do begin
block[i] :=0;
end;



//


//after we get filter ... now aplly this filter on the audio signal

fout := tfilestream.Create('filtred.wav',fmcreate);

//save information to fout
fin.Position :=0;
fin.Read(indata,wavinfopos);
fout.Write(indata,wavinfopos);
//read audio block by block
retval := 1;//
memo1.Lines.Add('Start Filtring...');



bbb:=0;
while(retval > 0) do begin
retval := fin.Read(indata,512);
//copy block to tmpdata


{
if(bbb<1) then begin
//saveshift
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,'BLOCK :'+inttostr(i));
for j := 0 to 255 do begin
if (j>2) and (j mod 8 = 0) then
writeln(fff,' ');
write(fff,inttostr(indata[j])+' ');
end;

end;
}

//there isan error here ........
// for all sample
for I := 0 to 255 do begin
// we have some data on tmp
// shift and reverse those data

// tmpdata must filled inside the (i) loop for get the shitfing and reversed data
for j := 0 to 255 do begin
tmpdata[j] := block[j];
end;


// and here is the shift
for j := 1 to flen-1 do begin
block[j] := tmpdata[j-1];
end;

block[0] := indata[i];
 {
if(bbb<1) then begin
//saveshift
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,'reverse and shift :'+inttostr(i));
for j := 0 to flen-1 do begin
if (j>2) and (j mod 8 = 0) then
writeln(fff,' ');
write(fff,floattostr(round(block[j]*100000)/100000)+' ');
end;

end;
 }

// convolution
sumation :=0;
for j := 0 to flen-1 do begin
sumation := sumation + (Filter[j] * block[j]);
end;

{
if(bbb<1) then begin
writeln(fff,' ');
writeln(fff,'sumation:');
writeln(fff,floattostr(round(sumation*100000)/100000)+' ');

end;
}


outdata[i] := trunc(sumation);// output filtred

end;
// before going to the next block weneed to save the filtred block
fout.Write(outdata,retval);


{
if(bbb<1) then begin
writeln(fff,' ');
writeln(fff,' ');
writeln(fff,'output (filtred block):');
for j := 0 to 255 do begin
if (j>2) and (j mod 8 = 0) then
writeln(fff,' ');
write(fff,floattostr(round(outdata[j]*100000)/100000)+' ');
end;

end;
}

bbb:= bbb+1;
end;


memo1.Lines.Add('Op end');

// ok let listen to the generated wav file (filtred)



//closefile(fff);
fin.Free;
fout.Free;


end;












end.


















