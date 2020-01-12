function varargout = serial_GUI_noICT(varargin)
%  	Author: Roger Yeh
%   Copyright 2010 MathWorks, Inc.
%   Version: 1.0  |  Date: 2010.01.13

% SERIAL_GUI_NOICT M-file for serial_GUI_noICT.fig
%      SERIAL_GUI_NOICT, by itself, creates a new SERIAL_GUI_NOICT or raises the existing
%      singleton*.
%
%      H = SERIAL_GUI_NOICT returns the handle to a new SERIAL_GUI_NOICT or the handle to
%      the existing singleton*.
%
%      SERIAL_GUI_NOICT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SERIAL_GUI_NOICT.M with the given input arguments.
%
%      SERIAL_GUI_NOICT('Property','Value',...) creates a new SERIAL_GUI_NOICT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before serial_GUI_noICT_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to serial_GUI_noICT_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help serial_GUI_noICT

% Last Modified by GUIDE v2.5 08-Jan-2010 16:07:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @serial_GUI_noICT_OpeningFcn, ...
                   'gui_OutputFcn',  @serial_GUI_noICT_OutputFcn, ...
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


% --- Executes just before serial_GUI_noICT is made visible.
function serial_GUI_noICT_OpeningFcn(hObject, eventdata, handles, varargin)

% serialPorts = instrhwinfo('serial');
% nPorts = length(serialPorts.SerialPorts);
set(handles.portList, 'String', ...
    [{'COM1'} ; ...
     {'COM2'} ; ...
     {'COM3'} ; ...
     {'COM4'} ; ...
     {'COM5'} ; ...
     {'COM6'} ; ...
     {'COM'} ; ...
     {'COM8'} ; ...
     {'COM9'} ; ...
     {'COM10'} ; ...
     {'COM11'} ; ...
     {'COM12'} ]);
set(handles.portList, 'Value', 2);   
set(handles.history_box, 'String', cell(1));

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes serial_GUI_noICT wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = serial_GUI_noICT_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in portList.
function portList_Callback(hObject, eventdata, handles)
% hObject    handle to portList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns portList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from portList


% --- Executes during object creation, after setting all properties.
function portList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to portList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function history_box_Callback(hObject, eventdata, handles)
% hObject    handle to history_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of history_box as text
%        str2double(get(hObject,'String')) returns contents of history_box as a double


% --- Executes during object creation, after setting all properties.
function history_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to history_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Tx_send_Callback(hObject, eventdata, handles)
TxText = get(handles.Tx_send, 'String');
fprintf(handles.serConn, TxText);

currList = get(handles.history_box, 'String');

set(handles.history_box, 'String', ...
    [currList ; ['Sent @ ' datestr(now) ': ' TxText] ]);
set(handles.history_box, 'Value', length(currList) + 1 );

set(hObject, 'String', '');



% --- Executes during object creation, after setting all properties.
function Tx_send_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Tx_send (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in rxButton.
function rxButton_Callback(hObject, eventdata, handles)
try 
    RxText = fscanf(handles.serConn);
    currList = get(handles.history_box, 'String');
    if length(RxText) < 1
        RxText = 'Timeout @ ';
        set(handles.history_box, 'String', ...
            [currList ; [RxText datestr(now)] ]);
    else
        set(handles.history_box, 'String', ...
            [currList ; ['Received @ ' datestr(now) ': ' RxText ] ]);
    end
    set(handles.history_box, 'Value', length(currList) + 1 );
catch e
    disp(e)
end

function baudRateText_Callback(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baudRateText as text
%        str2double(get(hObject,'String')) returns contents of baudRateText as a double


% --- Executes during object creation, after setting all properties.
function baudRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in connectButton.
function connectButton_Callback(hObject, eventdata, handles)    
if strcmp(get(hObject,'String'),'Connect') % currently disconnected
    serPortn = get(handles.portList, 'Value');
    
    serList = get(handles.portList,'String');
    serPort = serList{serPortn};
    serConn = serial(serPort, 'TimeOut', 1, ...
        'BaudRate', str2num(get(handles.baudRateText, 'String')));
    
    try
    fopen(serConn);
    handles.serConn = serConn;
    
    % enable Tx text field and Rx button
    set(handles.Tx_send, 'Enable', 'On');
    set(handles.rxButton, 'Enable', 'On');
    
    set(hObject, 'String','Disconnect')
    catch e
        errordlg(e.message);
    end
else
    set(handles.Tx_send, 'Enable', 'Off');
    set(handles.rxButton, 'Enable', 'Off');
    
    set(hObject, 'String','Connect')
    fclose(handles.serConn);
end
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'serConn')
    fclose(handles.serConn);
end
% Hint: delete(hObject) closes the figure
delete(hObject);
