function ArduinoInputOutputApp

% Define constants for Arduino hardware setup
pin.Button = 'D12';
pin.Pot = 'A0';
pin.LED = 'D6';
pin.Piezo = 'D3';

% Build app for interacting with Arduino
h = buildGraphics;

% Connect to Arduino device
prompt = {'Port:','Board name:'};
dlgtitle = 'Arduino';
answer = inputdlg(prompt,dlgtitle);
hMessage = msgbox('Connecting to Arduino...');
if isempty(answer{1}) && isempty(answer{2})
    h.a = arduino;
else
    h.a = arduino(answer{1},answer{2});
end
delete(hMessage)

% Set up timer for updating figure
h.Timer = timer;
h.Timer.TimerFcn = @(~,~) UpdateFigure(h);
h.Timer.ExecutionMode = 'fixedRate';
h.Timer.Period = 0.05;

% Store initial values of UI objects
initial.ActiveRadioButton = 'toggle';
initial.ToggleValue = 0;
initial.LedSliderValue = 0;
initial.PlayToneSliderValue = 0;

% Update all necessary application data
setappdata(h.Figure,'handles',h)
setappdata(h.Figure,'pins',pin)
setappdata(h.Figure,'oldValues',initial)

% Handle closing the figure
h.Figure.CloseRequestFcn = @(~,~) CloseFigure(h);

% Start execution
start(h.Timer)

function UpdateFigure(h)
pin = getappdata(h.Figure,'pins');
old = getappdata(h.Figure,'oldValues');

% Update button input
buttonStatus = readDigitalPin(h.a,pin.Button);
if buttonStatus
    h.ButtonPositionText.String = 'DOWN';
else
    h.ButtonPositionText.String = 'UP';
end

% Update potentiometer input
potVoltage = readVoltage(h.a,pin.Pot);
potVoltageStr = sprintf('%.2f V',potVoltage);
h.PotentiometerVoltageText.String = potVoltageStr;

% Update stored values
new.ActiveRadioButton = h.LedButtonGroup.SelectedObject.Tag;
new.ToggleValue = h.LedToggle.Value;
new.LedSliderValue = h.LedSlider.Value;
new.PlayToneSliderValue = h.PlayToneSlider.Value;
setappdata(h.Figure,'oldValues',new)

% Update LED (if changed)
if ~strcmp(new.ActiveRadioButton,old.ActiveRadioButton)
    switch new.ActiveRadioButton
        case 'toggle'
            writeDigitalPin(h.a,pin.LED,new.ToggleValue)
        case 'pwm'
            writePWMVoltage(h.a,pin.LED,new.LedSliderValue)
    end
elseif strcmp(new.ActiveRadioButton,'toggle') && new.ToggleValue ~= old.ToggleValue
    writeDigitalPin(h.a,pin.LED,new.ToggleValue)
elseif strcmp(new.ActiveRadioButton,'pwm') && new.LedSliderValue ~= old.LedSliderValue
    writePWMVoltage(h.a,pin.LED,new.LedSliderValue)
end

% Update speaker tone (if changed)
if old.PlayToneSliderValue ~= new.PlayToneSliderValue
    f = 100*10^(5/3*new.PlayToneSliderValue); % range: 100-4642 Hz
    playTone(h.a,pin.Piezo,f,1)
end

drawnow

function CloseFigure(h)
stop(h.Timer)
delete(h.Timer)
clear h.a
delete(h.Figure)
