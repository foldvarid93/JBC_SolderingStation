%%

voltageRange = 0:5;
freqRange = (20000-20)/5*voltageRange+20;
plot(voltageRange,freqRange)

%%

a = arduino;
v = readVoltage(a,'A0');
f = (20000-20)/5*v+20;
playTone(a,'D3',f,0.5);

%% 

tic
while toc <10
    v = readVoltage(a,'A0');
f = (20000-20)/5*v+20;
playTone(a,'D3',f,0.5);
end

%% 

voltageRange = 0:5;
freqRange = (10000-100)/5*voltageRange+100;
FreqVoltPlot(voltageRange,freqRange)

%% 


tic
while toc <10
    v = readVoltage(a,'A0');
f = (10000-100)/5*v+100;
playTone(a,'D3',f,0.5);
end

%%

tic
while toc <10
    v = readVoltage(a,'A0');
f = 10.^(2/5*v+2);
playTone(a,'D3',f,0.5);
end