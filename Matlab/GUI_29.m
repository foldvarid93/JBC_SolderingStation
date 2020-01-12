function [] = GUI_29()
% Demonstrate the use of a uicontrol to manipulate an axes from a GUI,
% and how to link two figures to close together.  
% The slider here controls the extent of the x lims up to a certain point.
%
% Suggested exercise: Alter the code so that an axes handle could be passed
% in as an argument.  Or a two-slider GUI could be made that controls both 
% the x and y limits.  Even more advanced:  Allow the GUI to replot if the
% limits go beyond current data.  This would require another input
% argument.
%
%
% Author:  Matt Fig
% Date:  7/15/2009
% First create the figure and plot to manipulate with the slider.
x = 0:.1:100;  % Some simple data.  Notice the data goes beyond xlim.
f = figure;  % This is the figure which has the axes to be controlled.
ax = axes;  % This axes will be controlled.
plot(x,sin(x));
xlim([0,pi]);  % Set the beginning x/y limits.
ylim([-1,1])
% Now create the other GUI
S.fh = figure('units','pixels',...
              'position',[400 400 220 40],...
              'menubar','none',...
              'name','GUI_29',...
              'numbertitle','off',...
              'resize','off');
S.sl = uicontrol('style','slide',...
                 'unit','pixel',...
                 'position',[10 10 200 20],...
                 'min',1,'value',pi,'max',100,...
                 'callback',{@sl_call,ax},...
                 'deletefcn',{@delete,f});
set(f,'deletef',{@delete,S.fh})  % Closing one closes the other.
 
function [] = sl_call(varargin) 
% Callback for the slider.
[h ax] = deal(varargin{[1;3]});  % Get the calling handle and structure.
set(ax,'xlim',[0 get(h,'val')],'ylim',[-1,1])