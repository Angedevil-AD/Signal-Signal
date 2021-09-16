{
M.Aek Progs Angedevil AD
unit3 : Low pass filter prototype

}
unit Unit3;

interface

uses
  Winapi.Windows,pngimage, Winapi.Messages,math, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm3 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Image1: TImage;
    NLP: TRadioButton;
    LP: TRadioButton;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;






type
Tdoplot= function(xs:pointer;ys:pointer;wd:longint;flnm:pansichar;title:pansichar;xl:pansichar;yl:pansichar;r:double;g:double;b:double;ih,iw:integer;imagedata:pointer ):longint;cdecl;

var
Form3: TForm3;
lib1: HMODULE;
doplot:Tdoplot;
Imgdata : array of byte;
implementation

{$R *.dfm}

procedure TForm3.Button1Click(Sender: TObject);
var
xx:integer;
fs:double;
wd:integer;
frequency: double; //hertz
fcut : double;// hertz
gain: double;
x_axis: array of double; // for freq
y_axis: array of double; // for amp
imagebuffer: pointer; //
imagelen:longint;
pngim: tpngimage;
iH,iW:integer;
memst:tmemorystream;
begin



setlength(x_axis,8000);
setlength(y_axis,8000);
setlength(imgdata,1500000); //max 1.5Mo





memo1.Clear;

frequency:= 4000; //hertz
fcut := 1200;// hertz
gain := 1.0;//
wd:= 100;// num of fs in frequency


if(LP.Checked) then begin
Memo1.Lines.Add('------------------------------------');
Memo1.Lines.Add('Low pass filter Prototype: ');
Memo1.Lines.Add('------------------------------------');

end

else if(NLP.Checked) then begin
Memo1.Lines.Add('------------------------------------');
Memo1.Lines.Add('NO filter : ');
Memo1.Lines.Add('------------------------------------');
memo1.Lines.Add('No Filter, output = input');
end;

for xx := 0 to WD do begin

if(LP.Checked) then begin //lowp
fs := (Frequency/WD)*xx; //  get Fs at xx


y_axis[xx] := ((gain* (1 / ( sqrt(1+ power(fs/fcut,6) )))));
x_axis[xx] := fs;

memo1.Lines.Add('Freq offset: '+inttostr(xx)+'/100' + ' fs= '+fs.ToString+  ' ,  Gain after LP: '+y_axis[xx].ToString());


if(fs < 200) then
y_axis[xx]:=1.0;

end

else begin //no lp
fs := (Frequency/WD)*xx; //  get Fs at xx
y_axis[xx] :=1.0;
x_axis[xx] := fs;


end;


end;

y_axis[0]:=1;
x_axis[0]:=0;


//do_plot
ih := image1.Height;  iw := image1.Width;
imagelen := doplot(@x_axis,@y_axis,WD,'test.png','signal','Freq (Hz)','amplitude (V)',230.0,19.0,119.0,ih,iw,@imgdata);
//showmessage(inttostr((imagelen)));
pngim:= tpngimage.Create;
memst:=tmemorystream.Create;
memst.Position:=0;
memst.Write(imgdata[0],imagelen);
memst.Position:=0;
pngim.LoadFromStream(memst);
image1.Picture.Assign(pngim);
pngim.Free;
memst.Free;
finalize(x_axis);
finalize(y_axis);
finalize(imgdata);

end;






//load lib
procedure TForm3.FormClose(Sender: TObject; var Action: TCloseAction);
begin
Freelibrary(lib1);
end;

procedure TForm3.FormCreate(Sender: TObject);
begin

lib1:=loadlibrary('PLT.dll');
if(lib1=0) then begin
showmessage('Err');
application.Terminate;
end;
doplot:= Getprocaddress(lib1,'doplot');
end;

end.




