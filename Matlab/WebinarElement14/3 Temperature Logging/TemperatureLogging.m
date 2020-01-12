%% Acquire and analyze data from a temperature sensor

%% Connect to Arduino
% Use the arduino command to connect to an Arduino device.

%a = arduino;
clear all;
ans=instrfind;
if(ans~=0)
fclose(instrfind);
end
s = serial('COM7','BaudRate',115200,'Terminator','CR/LF');
fopen(s);

%% Take a single temperature measurement
% The datasheet for the TMP36 temperature sensor tells us that the voltage
% reading is directly proportional to temperature in Celsius with an 
% offset of 0.5V and a scale factor of 10 mV/°C (equivalent to 100 °C/V).
% Therefore the conversion can be represented as
%
% $T_C = (V-0.5)*100$
%
% We can read the output voltage, convert it to Celsius and convert the
% result to Farenheit as follows:
%v = readVoltage(a,'A0');
data=fscanf(s);
%TempC = (v - 0.5)*100;
%TempF = 9/5*TempC + 32;
%fprintf('Temperature Reading:\n  %.1f °C\n  %.1f °F\n',TempC,TempF)

%% Record and plot 10 seconds of temperature data

ii = 0;
t = zeros(1e4,1);

tic
while toc < 30
    ii = ii + 1;
    % Read current voltage value
    %v = readVoltage(a,'A0');
    data=convertCharsToStrings(fscanf(s));
    C(ii,:)=strsplit(data,'; ');
    % Calculate temperature from voltage (based on data sheet)
    %TempC = (v - 0.5)*100;
    %TempF(ii) = 9/5*TempC + 32;
    % Get time since starting
    t(ii) = toc;
end
F=str2double(C);
% Post-process and plot the data. First remove any excess zeros on the
% logging variables.
t = t(1:ii);
% Plot temperature versus time
figure
plot(t,F(:,4),'-o')
xlabel('Elapsed time (sec)')
ylabel('Temperature (\circF)')
title('Ten Seconds of Temperature Data')
set(gca,'xlim',[t(1) t(ii)])
grid on;
clear F;
clear data;
clear ii;
clear C;

%% Compute acquisition rate

timeBetweenDataPoints = diff(t);
averageTimePerDataPoint = mean(timeBetweenDataPoints);
dataRateHz = 1/averageTimePerDataPoint;
fprintf('Acquired one data point per %.3f seconds (%.f Hz)\n',...
    averageTimePerDataPoint,dataRateHz)

%% Why is my data so choppy?

measurableIncrementV = 5/1023;
measurableIncrementC = measurableIncrementV*100;
measurableIncrementF = measurableIncrementC*9/5;
fprintf('The smallest measurable increment of this sensor by the Arduino is\n %-6.4f V\n %-6.2f°C\n %-6.2f°F\n',...
    measurableIncrementV,measurableIncrementC,measurableIncrementF);

%% Acquire and display live data

figure
h = animatedline;
ax = gca;
ax.YGrid = 'on';
ax.YLim = [65 85];

stop = false;
startTime = datetime('now');
while ~stop
    % Read current voltage value
    v = readVoltage(a,'A0');
    % Calculate temperature from voltage (based on data sheet)
    TempC = (v - 0.5)*100;
    TempF = 9/5*TempC + 32;    
    % Get current time
    t =  datetime('now') - startTime;
    % Add points to animation
    addpoints(h,datenum(t),TempF)
    % Update axes
    ax.XLim = datenum([t-seconds(15) t]);
    datetick('x','keeplimits')
    drawnow
    % Check stop condition
    stop = readDigitalPin(a,'D12');
end

%% Plot the recorded data

[timeLogs,tempLogs] = getpoints(h);
timeSecs = (timeLogs-timeLogs(1))*24*3600;
figure
plot(timeSecs,tempLogs)
xlabel('Elapsed time (sec)')
ylabel('Temperature (\circF)')

%% Smooth out readings with moving average filter

smoothedTemp = smooth(tempLogs,25);
tempMax = smoothedTemp + 2*9/5;
tempMin = smoothedTemp - 2*9/5;

figure
plot(timeSecs,tempLogs, timeSecs,tempMax,'r--',timeSecs,tempMin,'r--')
xlabel('Elapsed time (sec)')
ylabel('Temperature (\circF)')
hold on 

%%
% Plot the original and the smoothed temperature signal, and illustrate the
% uncertainty.

plot(timeSecs,smoothedTemp,'r')

%% Save results to a file

T = table(timeSecs',tempLogs','VariableNames',{'Time_sec','Temp_F'});
filename = 'Temperature_Data.xlsx';
% Write table to file 
writetable(T,filename)
% Print confirmation to command line
fprintf('Results table with %g temperature measurements saved to file %s\n',...
    length(timeSecs),filename)
