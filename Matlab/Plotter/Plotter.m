
clear all;
ans=instrfind;
if(ans~=0)
fclose(instrfind);
end
s1 = serial('COM7','BaudRate',115200,'Terminator','CR/LF');
fopen(s1);

%%
%s1=serial('COM7','Baudrate',19200);
%fopen(s1);
accX=0;accY=0;accZ=0;
str='';
sen=0;
j=1;
x=0;

while(j<10000)
    
    str=fscanf(s1);
    sen=str2num(str);
    accX(j)=sen(4);
    accY(j)=sen(5);
    accZ(j)=sen(7);
    x(j)=j;

    if(j>1000)
        x1=x(j-1000:j);
        accX1=accX(j-1000:j);
        accY1=accY(j-1000:j);
        accZ1=accZ(j-1000:j);
        xmin=j-1000;
        xmax=j;
    else
        x1=x;
        accX1=accX;
        accY1=accY;
        accZ1=accZ;
        xmin=0;
        xmax=1000;
    end
    
    plot(x1,accX1,x1,accY1,x1,accZ1);
    grid on;
    axis([xmin xmax 0 550]);

    drawnow;
    j=j+1;

end;
