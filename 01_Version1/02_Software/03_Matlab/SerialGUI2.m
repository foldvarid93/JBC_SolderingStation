function varargout = SerialGUI2(varargin)
% SERIALGUI2 MATLAB code for SerialGUI2.fig
%      SERIALGUI2, by itself, creates a new SERIALGUI2 or raises the existing
%      singleton*.
%
%      H = SERIALGUI2 returns the handle to a new SERIALGUI2 or the handle to
%      the existing singleton*.
%
%      SERIALGUI2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SERIALGUI2.M with the given input arguments.
%
%      SERIALGUI2('Property','Value',...) creates a new SERIALGUI2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SerialGUI2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SerialGUI2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SerialGUI2

% Last Modified by GUIDE v2.5 28-Dec-2019 12:11:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SerialGUI2_OpeningFcn, ...
                   'gui_OutputFcn',  @SerialGUI2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SerialGUI2 is made visible.
function SerialGUI2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SerialGUI2 (see VARARGIN)

% Choose default command line output for SerialGUI2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SerialGUI2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SerialGUI2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
found = instrfind('Type', 'serial','DataBits',8,'StopBits',1);
if isempty(found)
      s = serial('COM5');  set(s,'BaudRate',4800,'Parity','none','StopBits',1,'DataBits',8,'Terminator','%');
  else
      fclose(found);
      s = found(1);
end
s.BytesAvailableFcnMode = 'terminator';
handles.s = s;
fopen(s);
guidata(hObject,handles);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
str=fscanf(handles.s);
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
