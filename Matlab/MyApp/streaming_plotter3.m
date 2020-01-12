function varargout = streaming_plotter3(varargin)
% STREAMING_PLOTTER3 plots streaming serial data channels from USB
%   channels are recognized using SPACE OR TAB DELIMITED values in each
%   row from a serial stream. 
%   All data is stored as FLOATING DOUBLE in MATLAB regardless of source type. 
%   Must close all other serial monitors to connect. 
%   default X-axis is channel 1 (first value in each row) - it is
%   recommended that this be a clock.
%   Features may require the instrument toolbox. 
%   When the serial port is closed, all data in the plot is saved to the 
%   workspace as a matrix 'log'
%
%   example of source-device code (arduino-flavored C):
% 
%    // STREAMING PLOTTER EXAMPLE
%    // free for non-commercial use
%    // (c) Austin Gurley 2016
%    
%    // declare variables
%    int A = 0;
%    float B = 1;
%    
%    // sample rate regulation
%    float Hz = 50;        // sample rate
%    float dt = 1000000/Hz; // sample time in microsecond
%    long loop_time = 0;
%    
%    const int led_pin = 13; // use an output pin to show sample rate
%    bool led_state = LOW;
%    
%    const int adc_pin = A0; // read an analog pin
%    
%    void setup()
%    {
%         // open serial port at 115200 BAUD
%         Serial.begin(115200);
%         delay(1000);
%         
%         pinMode(led_pin,OUTPUT);
%         pinMode(adc_pin,INPUT);
%    }
%    void loop()
%    {
%         // do some int math
%         A++;
%         if(A>100)
%           A = -100;
%           
%         // do some float math
%         B = 100*sin(2*3.14*(float)millis()/1000.0);
%    
%         // print data to serial port
%         Serial.print((float)millis()/1000.0,3);
%         Serial.print("\t");
%         Serial.print(analogRead(A0));
%         Serial.print(" ");
%         Serial.print(A);
%         Serial.print(" ");
%         Serial.println(B);
%         
%         // regulate to approximately "Hz" (max depends on BAUD and computer speed)
%         while ((micros()-loop_time)<dt)
%         {
%         }
%         loop_time = micros();
%         // blink an LED
%         led_state = !led_state;
%         digitalWrite(led_pin,led_state);
%    }
% 
%   (c) Austin Gurley 2016

% Last Modified by GUIDE v2.5 29-Dec-2019 19:08:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @streaming_plotter3_OpeningFcn, ...
                   'gui_OutputFcn',  @streaming_plotter3_OutputFcn, ...
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
function port_menu_CreateFcn(hObject, eventdata, handles)
% --- Executes just before streaming_plotter3 is made visible.
function streaming_plotter3_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to streaming_plotter3 (see VARARGIN)
% Choose default command line output for streaming_plotter3
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

create_serial_object(hObject, eventdata, handles);

% UIWAIT makes streaming_plotter3 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = streaming_plotter3_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function x_axis_menu_Callback(hObject, eventdata, handles)

function x_axis_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in y_axis_1_menu.
function y_axis_1_menu_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function y_axis_1_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in y_axis_2_menu.
function y_axis_2_menu_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function y_axis_2_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in y_axis_3_menu.
function y_axis_3_menu_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function y_axis_3_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in refresh_rate_menu.
function refresh_rate_menu_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function refresh_rate_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in num_samples_menu.
function num_samples_menu_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function num_samples_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in stream_button.
function stream_button_Callback(hObject, eventdata, handles)
%variables start
ButtonName=get(hObject, 'String');
Values = [];
global obj1
global Data
obj1;
Data;
%variables end 
if  ButtonName=="Start"
    %
    handles.obj1 = obj1;
    obj1.BytesAvailableFcn = {@getdatausart,handles};
    obj1.BytesAvailableFcnMode='terminator';
    obj1.Terminator='CR/LF';  
    if strcmp(obj1.Status,'closed')
        try(fopen(obj1));
            set(handles.port_menu,       'Enable','off');
            set(handles.num_samples_menu,'Enable','off');
            set(handles.baud_rate_menu,  'Enable','off');
            set(hObject,'String','Stop');
            fprintf(['port ' obj1.port ' opened\n'])        
            %set(handles.stream_info_text,'String',['port ' obj1.port ' streaming'])
        catch
            fprintf(['port ' obj1.port ' not available\n'])
            %set(hObject,'Value',0)
            %set(handles.stream_info_text,'String',['port ' obj1.port ' unavailable'])
        end
    end
end
%
if ButtonName=="Stop"
    set(handles.port_menu,       'Enable','on');
    set(handles.num_samples_menu,'Enable','on');
    set(handles.baud_rate_menu,  'Enable','on');
    set(hObject,'String','Start');
    if strcmp(obj1.Status,'open')
        fclose(obj1);
        fprintf(['port ' obj1.port ' closed\n'])
        set(hObject,'String','Start');
        %clear(Data);
    end 
end
guidata(hObject, handles);

    function Serial_int_Fcn(hObject, eventdata, GUI)     %GUI is the name of my GUI.
    handles                     = guidata(GUI);
    Serial_in                   = strsplit(fscanf(handles.s),';')
    Voltage(handles.i)          = str2double(Serial_in(1,3))
    
    set(handles.AmbientT,'String',Voltage(handles.i))
    
    handles.i                   =  handles.i+1 
    guidata(GUI,handles); 
%
function getdatausart(hObject, eventdata, handles)
global obj1
global Data
obj1;
Data;
str=fscanf(obj1);
Record=strsplit(str,';');
%Data=get(handles.Data);
[DataRow,DataCol]=size(Data);
RecordDouble=str2double(Record);
Data(DataRow,:)=RecordDouble;
Data(DataRow,1)=Data(DataRow,1)-Data(1,1);
Dat=handles.Data;
handles.Data=Dat+1;
%guidata(handles.Data, handles);
% Time(1,2)=str2double(Record(2));
% Data(1,1)=str2double(Record(3));
% Data(1,2)=str2double(Record(4));
% Data(1,3)=str2double(Record(5));
% Data(1,4)=str2double(Record(6));
% Data(1,5)=str2double(Record(7));
% Data(1,6)=str2double(Record(8));
% G1 = plot(handles.axes2,0,0,'b-');

%plot(Data(0,0):Data(10,0),Data(0:4):Data(10,4));

%plot(handles.axes2,0:0.1:10,0:1:100);
plot(handles.axes2,Data(:,1),Data(:,4),Data(:,1),Data(:,5));
grid(handles.axes2,'on');
ylim(handles.axes2,[0 480]);%
%set(handles.axes2,'xdata',[1:10:length(data1)].*1/sampleFreq, 'ydata',data1(1:10:end));
if DataRow>1000
end
%guidata(hObject, handles);


%
% num_samples_choices = cellstr(get(handles.num_samples_menu,'String'));
% num_samples_selection = num_samples_choices{get(handles.num_samples_menu,'Value')};
% too_big = str2num(num_samples_selection);
% flushinput(obj1);
% pause(0.1)
% 
% % which channels will we plot?
% 
% x1 = 1;%get(handles.x_axis_menu,'Value')-1;
% y1 = 4;%get(handles.y_axis_1_menu,'Value')-1;
% y2 = 5;%get(handles.y_axis_2_menu,'Value')-1;
% y3 = 8;%get(handles.y_axis_3_menu,'Value')-1;
% 
% num_channels_found = 0;
% values_string = fgetl(obj1);
% for i = 1:20
%       [token,values_string] = strtok(values_string);
%       if size(token)>0
%         values(i) = str2num(token);
%         num_channels_found = num_channels_found+1;
%       end
% end
% %set(handles.channel_info_text,'String',[num2str(num_channels_found) ' channels found'])
% hold off
% cla
% 
% % make sure we are plotting something...
% if num_channels_found == 0
%      fprintf('no channels found - incorrect BAUD rate?\n')
%      set(hObject,'Value',0)
%      pause(1)
% elseif x1==0 || x1>num_channels_found
%      set(handles.x_axis_menu,'ForegroundColor',[1 0 0])
%      fprintf('must select a valid channel for X-axis\n')
%      set(hObject,'Value',0)
%      pause(1)
% else
% % if we are, start organizing plots
% 
% % check for the subplot style display
% %axes(handles.axes1); % default to axes1
% %cla(handles.axes1);
% %subplot_state = get(handles.subplot_on_off,'Value');
% 
% if (y1>=1 && y1<=num_channels_found)
%      hold on
% %      if subplot_state
%           G1 = plot(handles.axes2,0,0,'b-');
%           grid(handles.axes2,'on');
%           grid(handles.axes2,'minor');
%           %set(handles.axes2,'grid','on');
%           %set(handles.axes2,'xminorgrid','on','yminorgrid','on');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes2,'on');
% %           end
% %      else
% %           G1 = plot(handles.axes1,0,0,'b-');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes1,'on');
% %           end
% %      end
%      set(G1,'XDataSource','Values(:,x1)','YDataSource','Values(:,y1)');
% %      if get(handles.grid_on_off,'Value')
% %           grid on
% %      end
% elseif y1>num_channels_found
%      set(handles.y_axis_1_menu,'ForegroundColor',[1 0 0])
% else
%      set(handles.y_axis_1_menu,'ForegroundColor',[0.5 0.5 0.5])
% end
% 
% if (y2>=1 && y2<=num_channels_found)
%      hold on
% %      if subplot_state %ha van subplot
%           G2 = plot(handles.axes3,0,0,'r-');
%         grid(handles.axes3,'on');
%         grid(handles.axes3,'minor');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes3,'on');%3 as plotba rajzoljon 
% %           end
% %      else%ha nincs subplot
% %           G2 = plot(handles.axes1,0,0,'r-');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes1,'on');%1 es plotba rajzoljon
% %           end
% %      end
%      set(G2,'XDataSource','Values(:,x1)','YDataSource','Values(:,y2)')
% %      if get(handles.grid_on_off,'Value')
% %           grid on
% %      end
% elseif y2>num_channels_found
%      set(handles.y_axis_2_menu,'ForegroundColor',[1 0 0])
% else
%      set(handles.y_axis_2_menu,'ForegroundColor',[0.5 0.5 0.5])
% end
% 
% if (y3>=1 && y3<=num_channels_found)
%      hold on
% %      if subplot_state
%           G3 = plot(handles.axes4,0,0,'g-');
%           grid(handles.axes4,'on');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes4,'on');
% %           end
% %      else
% %           G3 = plot(handles.axes1,0,0,'g-');
% %           if get(handles.grid_on_off,'Value')
% %                grid(handles.axes1,'on');
% %           end
% %      end
%      set(G3,'XDataSource','Values(:,x1)','YDataSource','Values(:,y3)')
% 
% elseif y3>num_channels_found
%      set(handles.y_axis_3_menu,'ForegroundColor',[1 0 0])
% else
%      set(handles.y_axis_3_menu,'ForegroundColor',[0.5 0.5 0.5])
% end
% 
% %monitor_plot = get(handles.monitor_on_off,'Value');
% %insert_location = 1;
% timeout = 10; % time out in seconds
% tic
% while (get(hObject,'Value')==1 && toc<timeout)
%      if obj1.BytesAvailable>0                 % run loop if there is data to act on
%           while obj1.BytesAvailable>0        % collect data until the buffer is empty
%                values_string = fgetl(obj1);
% 
%                for i = 1:num_channels_found
%                      [token,values_string] = strtok(values_string);
%                      if size(token)>0
%                        values(i) = str2num(token);
%                      end
%                end
%                [rows,columns] = size(Values);
%                
% %                if ~monitor_plot         % scrolling plot
%                     if (rows>too_big)
%                          Values = Values(2:end,:);
%                     end
%                     Values = [Values;values];
% %                end
% %                if monitor_plot          % 'heart monitor' plot
% %                     if (rows>too_big)
% %                          insert_location = insert_location+1;
% %                          if insert_location>too_big
% %                               insert_location = 2;
% %                          end
% %                     Values = [Values(1:insert_location-1,:);
% %                               values; 
% %                               Values((insert_location+1):end,:)];
% %                     else
% %                     Values = [Values;values];
% %                     end
% %                end
%           end
%                                        % update all valid plots
%           if (y1>=1 && y1<=num_channels_found)
%              refreshdata(G1,'caller')
%           end
%           if (y2>=1 && y2<=num_channels_found)
%              refreshdata(G2,'caller')
%           end
%           if (y3>=1 && y3<=num_channels_found)
%              refreshdata(G3,'caller')
%           end
%           
% %           if ~subplot_state
% %           % x axis scaling for single plot
% %                if y1>=1 || y2>=1 || y3>=1
% %                     if length(Values)>1 && (min(Values(:,x1)) ~= max(Values(:,x1)))
% %                          xlim(handles.axes1,[min(Values(:,x1)) max(Values(:,x1))])
% %                     end
% %                end
% %           else
%                if y1>=1 || y2>=1 || y3>=1
%                     if length(Values)>1 && (min(Values(:,x1)) ~= max(Values(:,x1)))
%                          xlim(handles.axes2,[min(Values(:,x1)) max(Values(:,x1))])
%                          ylim(handles.axes2,[0 480]);%
%                          xlim(handles.axes3,[min(Values(:,x1)) max(Values(:,x1))])
%                          ylim(handles.axes3,[0 480]);%
%                          xlim(handles.axes4,[min(Values(:,x1)) max(Values(:,x1))])
%                          ylim(handles.axes4,[0 100]);%
%                     end
%                end
% %           end
%           
%           tic
%           %current_status = get(handles.stream_info_text,'String');
%           %if ~strcmp(current_status,['port ' obj1.port ' streaming'])
%                %set(handles.stream_info_text,'String',['port ' obj1.port ' streaming'])
%           %end
%           pause(0.0001);
%      else
%           %message = ['port ' obj1.port ' no data in ' num2str(round(toc)) ' sec...'];
%           if toc>1.5 && ~strcmp(current_status,message)
%                %set(handles.stream_info_text,'String',message)
%           end
%           pause(0.0001);
%      end
% end
% if toc>timeout
%      fprintf('Unexpected disconnect\n')
%      set(hObject,'Value',0)
% end
% end
% 
%   fclose(obj1);
%   fprintf(['port ' obj1.port ' closed\n\n'])
%   %set(handles.stream_info_text,'String',['port ' obj1.port ' closed'])
%   %set(handles.channel_info_text,'String','# channels found')
%      %set(handles.x_axis_menu,'ForegroundColor',[0 0 0])
%      %set(handles.y_axis_1_menu,'ForegroundColor',[0 0 0])
%      %set(handles.y_axis_2_menu,'ForegroundColor',[0 0 0])
%      %set(handles.y_axis_3_menu,'ForegroundColor',[0 0 0])
%   
%   assignin('base','log',Values);
%   set(hObject,'String','Start')
%   
% 
% end

% --- Executes on selection change in port_menu.
function port_menu_Callback(hObject, eventdata, handles)

create_serial_object(hObject, eventdata, handles);



% --- Executes on button press in monitor_on_off.
function monitor_on_off_Callback(hObject, eventdata, handles)


% --- Executes on selection change in baud_rate_menu.
function baud_rate_menu_Callback(hObject, eventdata, handles)

create_serial_object(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function baud_rate_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function create_serial_object(hObject, eventdata, handles)
global obj1
global selection

     contents = cellstr(get(handles.port_menu,'String'));
     selection = contents{get(handles.port_menu,'Value')};

     try
        fclose(instrfind);
        fprintf('closing all existing ports...\n')
     catch
        fprintf('could not find existing Serial ports\n')
     end
     
     obj1 = instrfind('Type', 'serial', 'Port', selection, 'Tag', '');

     % Create the serial port object if it does not exist
     % otherwise use the object that was found.
     if isempty(obj1)
         obj1 = serial(selection);
     else
         fclose(obj1);
         obj1 = obj1(1);
     end

contents2 = cellstr(get(handles.baud_rate_menu,'String'));
BAUD  = str2double(contents2{get(handles.baud_rate_menu,'Value')});
     set(obj1, 'BaudRate', BAUD, 'ReadAsyncMode','continuous');
     set(obj1, 'Terminator','LF');
     set(obj1, 'RequestToSend', 'off');
     set(obj1, 'Timeout', 4);

    fprintf(['serial object created for ' selection ' at ' num2str(BAUD) ' BAUD\n\n']);


function Kp_editbox_Callback(hObject, eventdata, handles)
EditboxString=get(handles.Kp_editbox,'String');
Kp_editboxValidFlag=0;
if length(EditboxString)==4
    if  EditboxString(1)>='0' && EditboxString(1)<='9' && EditboxString(2)=='.' && EditboxString(3)>='0' && EditboxString(3)<='9' && EditboxString(4)>='0' && EditboxString(4)<='9'
        Kp_editboxValidFlag=1;
    end    
end
if ~Kp_editboxValidFlag
   set(handles.Kp_editbox,'String','');
   warndlg('Value Out of Range! Please Enter Again');
else
   handles.Kp_editboxValidFlag=Kp_editboxValidFlag;
   %msgbox('Got the value, On it!');
end
% hObject    handle to Kp_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Kp_editbox as text
%        str2double(get(hObject,'String')) returns contents of Kp_editbox as a double


% --- Executes during object creation, after setting all properties.
function Kp_editbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Kp_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Ki_editbox_Callback(hObject, eventdata, handles)
% hObject    handle to Ki_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EditboxString=get(handles.Ki_editbox,'String');
Ki_editboxValidFlag=0;
if length(EditboxString)==4
    if  EditboxString(1)>='0' && EditboxString(1)<='9' && EditboxString(2)=='.' && EditboxString(3)>='0' && EditboxString(3)<='9' && EditboxString(4)>='0' && EditboxString(4)<='9'
        Ki_editboxValidFlag=1;
    end    
end
if ~Ki_editboxValidFlag
   set(handles.Ki_editbox,'String','');
   warndlg('Value Out of Range! Please Enter Again');
else
   handles.Ki_editboxValidFlag=Ki_editboxValidFlag;
   %msgbox('Got the value, On it!');
end
% Hints: get(hObject,'String') returns contents of Ki_editbox as text
%        str2double(get(hObject,'String')) returns contents of Ki_editbox as a double


% --- Executes during object creation, after setting all properties.
function Ki_editbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Ki_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Kd_editbox_Callback(hObject, eventdata, handles)
% hObject    handle to Kd_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
EditboxString=get(handles.Kp_editbox,'String');
Kd_editboxValidFlag=0;
if length(EditboxString)==4
    if  EditboxString(1)>='0' && EditboxString(1)<='9' && EditboxString(2)=='.' && EditboxString(3)>='0' && EditboxString(3)<='9' && EditboxString(4)>='0' && EditboxString(4)<='9'
        Kd_editboxValidFlag=1;
    end    
end
if ~Kd_editboxValidFlag
   set(handles.Kd_editbox,'String','');
   warndlg('Value Out of Range! Please Enter Again');
else
   handles.Kd_editboxValidFlag=Kd_editboxValidFlag;
   %msgbox('Got the value, On it!');
end
% Hints: get(hObject,'String') returns contents of Kd_editbox as text
%        str2double(get(hObject,'String')) returns contents of Kd_editbox as a double


% --- Executes during object creation, after setting all properties.
function Kd_editbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Kd_editbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in SendPID_button.
function SendPID_button_Callback(hObject, eventdata, handles)
global obj1
%Kp
Kp=get(handles.Kp_editbox,'String');
%Kp_editboxValidFlag=handles.Kp_editboxValidFlag;
KpData=strcat("Kp=", Kp,",");
%Ki
Ki=get(handles.Ki_editbox,'String');
KiData=strcat("Ki=", Ki,",");
%Kd
Kd=get(handles.Kd_editbox,'String');
KdData=strcat("Kd=", Kd);
TxData=strcat("START: ",KpData, " ", KiData," ", KdData, " :END");
fprintf(obj1,TxData);
%fprintf(obj1,TxData);
%str=fgetl(obj1);
% hObject    handle to SendPID_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SendPID_button
