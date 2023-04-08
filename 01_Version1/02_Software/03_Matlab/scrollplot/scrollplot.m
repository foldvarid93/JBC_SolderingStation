function scrollHandles = scrollplot(varargin)
%SCROLLPLOT add scroll sub-window to the supplied plot handle
%
%   scrollplot adds a scroll sub-window to any supplied plot handle(s).
%   The user may specify initial view window parameters or use defaults.
%   Dragging the side-bars or central patch modifies the respective parent
%   axes limits interactively. Conversely, modifying the parent axes
%   limits (with zoom, pan or programatically) modifies the corresponding
%   scroll patch(es) accordingly. Works ok with log and reverse axes.
%   Both X & Y scrolling are possible. Custom properties provide access to
%   the scroll axes, central patch and side-bars, for user customizations.
%
%   Syntax:
%     scrollHandles = scrollplot(plotHandles, propName,propValue,...)
%
%   scrollplot(plotHandles) adds a scroll sub-window to the supplied
%   plotHandles using default property values (see below).
%   plotHandles may be any combination of axes and line/data handles.
%   If plotHandles is not supplied then the current axes (<a href="matlab:help gca">gca</a>) is used.
%
%   scrollplot(..., propName,propValue, ...) sets the property value(s)
%   for the initial scroll view window. Property specification order does
%   not matter. The following properties are supported (case-insensitive):
%     - 'Axis'       : string (default = 'X'; accepted values: 'X','Y','XY')
%     - 'Min'        : number (default = minimal value of actual plot data)
%                      sets the same value for both 'MinX' & 'MinY'
%     - 'Max'        : number (default = maximal value of actual plot data)
%                      sets the same value for both 'MaxX' & 'MaxY'
%     - 'MinX','MinY': number (same as 'Min', but only for X or Y axis)
%     - 'MaxX','MaxY': number (same as 'Max', but only for X or Y axis)
%     - 'WindowSize' : number (default = entire range  of actual plot data)
%                      sets the same value for 'WindowSizeX' & 'WindowSizeY'
%     - 'WindowSizeX': number (same as 'WindowSize' but only for X axis)
%     - 'WindowSizeY': number (same as 'WindowSize' but only for Y axis)
%
%   scrollHandles = scrollplot(...) returns handle(s) to the scroll axes.
%   The returned handles are regular axes with a few additional read-only
%   properties:
%     - 'ScrollSideBarHandles' - array of 2 handles to the scroll side-bars
%     - 'ScrollPatchHandle' - handle to the central scroll patch
%     - 'ScrollAxesHandle'  - handle to the scroll axes =double(scrollHandles)
%     - 'ParentAxesHandle'  - handle to the parent axes
%     - 'ScrollMin'         - number
%     - 'ScrollMax'         - number
%
%   Examples:
%     scrollplot;  % add scroll sub-window to the current axes (gca)
%     scrollplot(plot(xdata,ydata), 'WindowSize',50); % plot with initial zoom
%     scrollplot('Min',20, 'windowsize',70); % add x-scroll to current axes
%     scrollplot([h1,h2], 'axis','xy'); % scroll both X&Y of 2 plot axes
%     scrollplot('axis','xy', 'minx',20, 'miny',10); % separate scroll minima
%
%   Notes:
%     1. Matlab 5: scrollplot might NOT work on Matlab versions earlier than 6 (R12)
%     2. Matlab 6: scrollplot is not interactive in zoom mode (ok in Matlab 7+)
%     3. Matlab 6: warnings are disabled as a side-effect (not in Matlab 7+)
%     4. scrollplot modifies the figure's WindowButtonMotionFcn callback
%     5. scrollplot works on 3D plots, but only X & Y axis are scrollable
%
%   Warning:
%     This code relies in [small] part on undocumented and unsupported
%     Matlab functionality. It works on Matlab 6+, but use at your own risk!
%
%   Bugs and suggestions:
%     Please send to Yair Altman (altmany at gmail dot com)
%
%   Change log:
%     2007-May-13: First version posted on MathWorks file exchange: <a href="http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14984">http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=14984</a>
%     2007-May-14: Set focus on parent axes after scroll-axes creation; added special scroll props; allowed 'Axis'='xy'
%     2007-May-15: Added 'MinX' etc. params; clarified error msgs; added 'ParentAxesHandle' special prop; fixed 'xy' bugs
%     2007-Jun-14: Enabled image exploration per suggestion by Joe Lotz; improved log axis-scaling behavior per suggestion by Fredric Moisy; added scroll visibility & deletion handlers; fixed minor error handling bug
%     2010-Nov-04: Minor fix for uitab compatibility suggested by Fabian Hof
%     2013-Jun-28: Support for the upcoming HG2
%     2015-Jul-15: Fixed warning about obsolete JavaFrame; preserved figure visibility; fixed zoom/pan compatibility
%     2015-Jul-16: Fixed custom properties in HG2 (R2014b+); removed reliance on the unsupported setptr function
%
%   See also:
%     plot, gca

%   Programming notes:
%     1. Listeners are set on parent axes's properties so that whenever
%        any of them (xlim,ylim,parent,units,position) is modified, then
%        so are the corresponding scroll axes properties.
%     2. To bypass the mode managers' (zoom, pan, ...) "hijack" of the
%        WindowButtonUpFcn callback, we use the non-supported JavaFrame's
%        AxisComponent MouseReleasedCallback: this doesn't work in Matlab 6
%        so scrollplot is non-interactive in Matlab 6 during zoom mode.
%     3. To bypass the mode managers over the scroll axes (to ignore zoom/
%        pan), we use the little-known 'ButtonDownFilter' mode property.
%     4. The special read-only properties in the returned scrollHandles are
%        not viewable (only accessible) in the regular axes handle, only
%        in the handle(scrollHandles). Therefore, the latter form is returned.
%        If you need the regular (numeric) form, use either double(scrollHandles)
%        or the new 'ScrollAxesHandle' read-only prop.

% License to use and modify this code is granted freely without warranty to all, as long as the original author is
% referenced and attributed as such. The original author maintains the right to be solely associated with this work.

% Programmed and Copyright by Yair M. Altman: altmany(at)gmail.com
% $Revision: 1.7 $  $Date: 2015/07/16 12:22:32 $

    try
        % Note: on some systems with Matlab 6, an OpenGL warning is displayed due to semi-
        % transparent scroll patch. This may be safely ignored. Unfortunately, specific warning
        % disabling was not yet available in Matlab 6 so we must turn off all warnings...
        v = version;
        if v(1)<='6'
            warning off;  %#ok for Matlab 6 compatibility
        else
            % Temporarily turn off log-axis warnings
            oldWarn = warning('off','MATLAB:Axes:NegativeDataInLogAxis');
        end

        % Args check
        [plotHandles, pvPairs] = parseparams(varargin);
        if iscell(plotHandles)
            plotHandles = [plotHandles{:}];  % cell2mat is not supported on old Matlab versions...
        end
        if isempty(plotHandles)
            plotHandles = gca;
        else
            plotHandles = plotHandles(:);  % ensure 1-D array of handles
        end

        % Ensure that all supplied handles are valid HG handles
        if isempty(plotHandles) | ~all(ishandle(plotHandles))  %#ok for Matlab 6 compatibility (note that Matlab 6 did not have ishghandle())
            myError('YMA:scrollplot:invalidHandle','invalid plot handle(s) passed to scrollplot');
        end

        % Get the list of axes handles (supplied handles may be axes or axes children)
        validHandles = [];
        try
            for hIdx = 1 : length(plotHandles)
                thisHandle = plotHandles(hIdx);
                if ~strcmpi(get(thisHandle,'type'),'axes')
                    thisHandle = get(thisHandle,'Parent');  % old Matlab versions don't have ancestor()...
                end
                if ~strcmpi(get(thisHandle,'type'),'axes')
                    myError('YMA:scrollplot:invalidHandle','invalid plot handle passed to scrollplot - must be an axes or line/data handle');
                end
                validHandles = [validHandles, thisHandle];  %#ok mlint - preallocate
            end
            validHandles = unique(validHandles);
        catch
            % Probably not a valid axes/line, without a 'type' property (see isprop)
            myError('YMA:scrollplot:invalidHandle','invalid plot handle(s) passed to scrollplot - must be an axes or line/data handle');
        end

        % Pre-process args necessary for creating the scroll-plots, if supplied
        [pvPairs, axName] = preProcessArgs(pvPairs);

        % For each unique axes, add the relevant scroll sub-plot
        %try
            scrollplotHandles = handle([]);

            % Loop over all specified/inferred parent axes
            for hIdx = 1 : length(validHandles)

                % Loop over all requested scroll axes (x,y, or x&y) for this parent axes
                hAx = validHandles(hIdx);
                for axisIdx = 1 : length(axName)
                    % Add the new scroll plot axes
                    h = addScrollPlot(hAx,axName(axisIdx));  %#ok mlint - preallocate
                    try
                        scrollplotHandles(end+1) = h;
                    catch
                        scrollplotHandles = [scrollplotHandles h];
                    end

                    % Process args, if supplied
                    processArgs(pvPairs,scrollplotHandles(end));
                end

                % Set the focus on the parent axes
                try
                    % This keeps the figure visibility unchanged
                    set(gcf,'CurrentAxes',hAx)
                catch
                    % This makes the figure visible, even if it was not so previously
                    axes(hAx);
                end
            end
        %catch
            % Probably not a valid axes handle
            %myError('YMA:scrollplot:invalidHandle','invalid plot handle(s) passed to scrollplot - must be an axes or line/data handle');
        %end

        % If return scrollHandles was requested
        if nargout
            % Return the list of all scroll handles
            scrollHandles = scrollplotHandles;
        end
    catch
        v = version;
        if v(1)<='6'
            err.message = lasterr;  % no lasterror function...
        else
            err = lasterror;
        end
        try
            err.message = regexprep(err.message,'Error using ==> [^\n]+\n','');
        catch
            try
                % Another approach, used in Matlab 6 (where regexprep is unavailable)
                startIdx = findstr(err.message,'Error using ==> ');
                stopIdx = findstr(err.message,char(10));
                for idx = length(startIdx) : -1 : 1
                    idx2 = min(find(stopIdx > startIdx(idx)));  %#ok ML6
                    err.message(startIdx(idx):stopIdx(idx2)) = [];
                end
            catch
                % never mind...
            end
        end
        if isempty(findstr(mfilename,err.message))
            % Indicate error origin, if not already stated within the error message
            err.message = [mfilename ': ' err.message];
        end
        if v(1)<='6'
            while err.message(end)==char(10)
                err.message(end) = [];  % strip excessive Matlab 6 newlines
            end
            error(err.message);
        else
            rethrow(err);
        end
    end

    % Restore original warnings (if available/possible)
    try
        warning(oldWarn);
    catch
        % never mind...
    end
%end  % scrollplot  %#ok for Matlab 6 compatibility

%% Set-up a new scroll sub-plot window to the supplied axes handle
function hScroll = addScrollPlot(hAx,axName)

    % Before modifying the original axes position, we must fix the labels (esp. xlabel)
    hLabel = get(hAx, [axName 'Label']);
    set(hLabel, 'units','normalized');

    % Set a new scroll sub-plot in the bottom 10% of the original axes height
    axPos = get(hAx,'position');
    axVis = get(hAx,'visible');
    axUnits = get(hAx,'units');
    scaleStr = [axName 'Scale'];
    dirStr   = [axName 'Dir'];
    limStr   = [axName 'Lim'];
    if strcmpi(axName,'x')
        newScrollPos = axPos .* [1, 1, 1, 0.10];
        newPlotPos   = axPos .* [1, 1, 1, 0.80] + [0, 0.20*axPos(4), 0, 0];
        specialStr = {'YTick',[]};
        colStr  = 'YColor';  % =axis line to hide
        rotation = 0;
    else  % Y scroll
        newScrollPos = [axPos(1)+axPos(3)*0.85, axPos(2), axPos(3)*0.1, axPos(4)];
        newPlotPos   = axPos .* [1, 1, 0.80, 1];
        specialStr = {'XTick',[], 'YAxisLocation','right'};
        colStr  = 'XColor';  % =axis line to hide
        rotation = 90;
    end
    hScroll = axes('units',axUnits, 'Parent',get(hAx,'Parent'), 'position',newScrollPos, 'visible',axVis, scaleStr,get(hAx,scaleStr), dirStr,get(hAx,dirStr), 'NextPlot','add', 'Box','off', specialStr{:}, 'FontSize',7, 'Tag','scrollAx', 'UserData',axName, 'DeleteFcn',@deleteScrollAx);
    GRAY = 0.8 * [1,1,1];
    try
        bgColor = get(get(hAx,'parent'),'Color');
        set(hScroll, colStr,bgColor);
    catch
        % Maybe the axes is contained in something without a 'Color' property
        set(hScroll, colStr,GRAY);
    end
    %axis(hScroll, 'off');
    set(hAx, 'position',newPlotPos);

    % Store the parent axes in the scroll axes's appdata
    setappdata(hScroll, 'parent',hAx);

    % Set the scroll limits & data based on the original axes's data
    % Note: use any axes child xdata to set the scroll limits, but
    % ^^^^  only plot line children (not scatter/bar/polar etc)
    axLines = get(hAx,'children');
    %lim = [Inf, -Inf];
    lim = get(hAx,limStr);
    if isinf(lim(1)),  lim(1)=+inf;  end
    if isinf(lim(2)),  lim(2)=-inf;  end
    for lineIdx = 1 : length(axLines)
        try
            hLine = axLines(lineIdx);
            xdata = get(hLine,'XData');
            ydata = get(hLine,'YData');
            try
                name = get(hLine,'DisplayName');
            catch
                % Matlab 6 did not have 'DisplayName' property (used by legend) - never mind...
                name = '';
            end
            if strcmpi(axName,'x'),  data=xdata(1,:);  else  data=ydata(1,:);  end
            lim = [min(lim(1),min(data)), max(lim(2),max(data))];
            linType = get(hLine,'type');
            if strcmpi(linType,'line')
                % Add plot line child if and only if it's a line
                lineColor = GRAY;  %=get(hLine,'color'); %orig color looks bad in scroll axes
                hLine2 = plot(xdata, ydata, 'Parent',hScroll, 'color',lineColor, 'tag','scrollDataLine', 'HitTest','off');
                if ~isempty(name)
                    set(hLine2, 'DisplayName',name);
                end
            % 2007-Jun-14: Enabled image exploration per suggestion by Joe Lotz
            elseif strcmpi(linType,'image')
                % Add miniature version of the main image
                hLine2 = image(get(hLine,'CData'), 'Parent',hScroll);  %#ok hLine2 used for debug
                set(hScroll,'YDir','Reverse','XLim',get(hLine,'XData'),'YLim',get(hLine,'YData'));
            end
        catch
            % Probably some axes child without data - skip it...
        end
    end
    if lim(1) > lim(2)
        curLim = get(hScroll, limStr);
        if isinf(lim(1)),  lim(1) = curLim(1);  end
        if isinf(lim(2)),  lim(2) = curLim(2);  end
    end
    if ~isempty(axLines) & lim(1) < lim(2)  %#ok for Matlab 6 compatibility
        set(hScroll, limStr,lim);
    end

    % Get the figure handle
    hFig = ancestor(hAx,'figure');

    % Prevent flicker on axes update
    set(hFig, 'DoubleBuffer','on');

    % Ensure that the axis component has a handle with callbacks
    % Note: this is determined by the first invocation, so ensure we're the first...
    axisComponent = getAxisComponent(hFig);  %#ok unused

    % Set the scroll handle-bars
    xlim = get(hScroll, 'XLim');
    ylim = get(hScroll, 'YLim');
    hPatch = patch(xlim([1,1,2,2]), ylim([1,2,2,1]), 'b', 'FaceAlpha',.15, 'EdgeColor','w', 'EdgeAlpha',.15, 'ButtonDownFcn',@mouseDownCallback, 'tag','scrollPatch', 'userdata',axName);  %Note: FaceAlpha causes an OpenGL warning in Matlab 6
    commonProps = {'Parent',hScroll, 'LineWidth',3, 'ButtonDownFcn',@mouseDownCallback, 'tag','scrollBar'};
    smallDelta = 0.01 * diff(lim);  % don't use eps
    if strcmpi(axName,'x')
        hBars(1) = plot(xlim([1,1]), ylim, '-b', commonProps{:});
        hBars(2) = plot(xlim([2,2]), ylim, '-b', commonProps{:});
    else  % Y scroll
        hBars(1) = plot(xlim, ylim([1,1])+smallDelta, '-b', commonProps{:});
        hBars(2) = plot(xlim, ylim([2,2])-smallDelta, '-b', commonProps{:});
    end
    try
        set(hBars(1), 'DisplayName','Min');
        set(hBars(2), 'DisplayName','Max');
    catch
        % Matlab 6 did not have 'DisplayName' property (used by legend) - never mind...
    end
    % TODO: maybe add a blue diamond or a visual handle in center of hBars?
    set(hScroll, limStr,lim+smallDelta*[-1.2,1.2]);

    % Help messages
    msg = {'drag blue side-bars to zoom', 'drag central patch to pan'};
    xText = getCenterCoord(hScroll, 'x');
    yText = getCenterCoord(hScroll, 'y');
    hText = text(xText,yText,msg, 'Color','r', 'Rotation',rotation, 'HorizontalAlignment','center', 'FontSize',9, 'FontWeight','bold', 'HitTest','off', 'tag','scrollHelp');  %#ok ret val used for debug
    hMenu = uicontextmenu;
    set(hScroll, 'UIContextMenu',hMenu);
    uimenu(hMenu, 'Label',msg{1}, 'Callback',@moveCursor, 'UserData',hBars(2));
    uimenu(hMenu, 'Label',msg{2}, 'Callback',@moveCursor, 'UserData',hPatch);

    % Set the mouse callbacks
    winFcn = get(hFig,'WindowButtonMotionFcn');
    if ~isempty(winFcn) & ~isequal(winFcn,@mouseMoveCallback) & (~iscell(winFcn) | ~isequal(winFcn{1},@mouseMoveCallback))  %#ok for Matlab 6 compatibility
        setappdata(hFig, 'scrollplot_oldButtonMotionFcn',winFcn);
    end
    set(hFig,'WindowButtonMotionFcn',@mouseMoveCallback);

    % Fix label position(s)
    oldPos = get(hLabel, 'position');
    if strcmpi(axName,'x')
        if ~isempty(oldPos) & oldPos(2)<0  %#ok for Matlab 6 compatibility
            % Only fix if the X label is on the bottom (usually yes)
            set(hLabel, 'position',oldPos-[0,.20/.80,0]);
        end
    else  % Y scroll
        if ~isempty(oldPos) & oldPos(1)>0  %#ok for Matlab 6 compatibility
            % Only fix if the Y label is on the right side (usually not)
            set(hLabel, 'position',oldPos+[.20/.80,0,0]);
        end
    end

    % Add property listeners
    listenedPropNames = {'XLim','YLim','XDir','YDir','XScale','YScale','Position','Units','Parent'};
    listeners = addPropListeners(hFig, hAx, hScroll, hPatch, hBars, listenedPropNames);
    setappdata(hScroll, 'scrollplot_listeners',listeners);  % These will be destroyed with hScroll so no need to un-listen upon hScroll deletion

    % Add special properties
    addSpecialProps(hAx, hScroll, hPatch, hBars, axName);

    % Convert to handle object, so that the special properties become visible
    hScroll = handle(hScroll);
    return;  % debug point
%end  % addScrollPlot  %#ok for Matlab 6 compatibility

%% Add parent axes listener
function listeners = addPropListeners(hFig, hAx, hScroll, hPatch, hBars, propNames)
    % Listeners on parent axes properties
    hhAx = handle(hAx);
    for propIdx = 1 : length(propNames)
        propName = propNames{propIdx};
        callback = {@parentAxesChanged, hFig, hAx, hPatch, hBars, propName};
        prop = findprop(hhAx, propName);
        try
            listeners(propIdx) = handle.listener(hhAx, prop, 'PropertyPostSet', callback);  %#ok mlint - preallocate
        catch
            callback = @(h,e) parentAxesChanged(h,e,callback{2:end});
            listeners(propIdx) = event.proplistener(hhAx, prop, 'PostSet', callback);  %#ok mlint - preallocate
        end
    end

    % Listeners on scroll axes properties
    hhScroll = handle(hScroll);
    prop = findprop(hhScroll, 'Visible');
    try
        listeners(end+1) = handle.listener(hhScroll, prop, 'PropertyPostSet', {@updateParentPos,hScroll});
    catch
        listeners(end+1) = event.proplistener(hhScroll, prop, 'PostSet', @(h,e) updateParentPos(h,e,hScroll));
    end
%end  % addPropListeners  %#ok for Matlab 6 compatibility

%% Add special scrollplot properties to the hScroll axes
function addSpecialProps(hAx, hScroll, hPatch, hBars, axName)
    try
        hhScroll = handle(hScroll);

        % Read-only props
        addNewProp(hhScroll,'ParentAxesHandle',    hAx,1);
        addNewProp(hhScroll,'ScrollAxesHandle',    double(hScroll),1);
        addNewProp(hhScroll,'ScrollPatchHandle',   hPatch,1);
        addNewProp(hhScroll,'ScrollSideBarHandles',hBars, 1);

        % Note: setting the property's GetFunction is much cleaner but doesn't work in Matlab 6...
        dataStr = [axName,'Data'];
        addNewProp(hhScroll,'ScrollMin',unique(get(hBars(1),dataStr)),1); %,{@getBarVal,hBars(1),dataStr});
        addNewProp(hhScroll,'ScrollMax',unique(get(hBars(2),dataStr)),1); %,{@getBarVal,hBars(2),dataStr});
    catch
        % Never mind...
    end
%end  % addSpecialProps  %#ok for Matlab 6 compatibility

%% Add new property to supplied handle
function addNewProp(hndl,propName,initialValue,readOnlyFlag,getFunc,setFunc)
    try  % HG1 (UDD)
        sp = schema.prop(hndl,propName,'mxArray');
        set(hndl,propName,initialValue);
        if nargin>3 & ~isempty(readOnlyFlag) & readOnlyFlag  %#ok for Matlab 6 compatibility
            set(sp,'AccessFlags.PublicSet','off');  % default='on'
        end
        if nargin>4 & ~isempty(getFunc)  %#ok for Matlab 6 compatibility
            set(sp,'GetFunction',getFunc);  % unsupported in Matlab 6
        end
        if nargin>5 & ~isempty(setFunc)  %#ok for Matlab 6 compatibility
            set(sp,'SetFunction',setFunc);  % unsupported in Matlab 6
        end
    catch % HG2 (MCOS)
        sp = addprop(hndl,propName);
        set(hndl,propName,initialValue);
        if nargin>3 & ~isempty(readOnlyFlag) & readOnlyFlag  %#ok for Matlab 6 compatibility
            sp.SetAccess = 'private';  % default='public'
        end
        if nargin>4 & ~isempty(getFunc)  %#ok for Matlab 6 compatibility
            sp.getMethod = getFunc;
        end
        if nargin>5 & ~isempty(setFunc)  %#ok for Matlab 6 compatibility
            sp.SetMethod = setFunc;
        end
    end
%end  % addNewProp  %#ok for Matlab 6 compatibility

%% Callback for getting side-bar value
function propValue = getBarVal(object,propValue,varargin)  %#ok object & propValue are unused
    propValue = unique(get(varargin{:}));
%end  % getBarVal  %#ok for Matlab 6 compatibility

%% Pre-process args necessary for creating the scroll-plots, if supplied
function [pvPairs, axName] = preProcessArgs(pvPairs)
    % Default axes is 'X'
    axName = 'x';

    % Special check for invalid format
    if ~isempty(pvPairs) & ischar(pvPairs{end}) & any(strcmpi(pvPairs{end},{'axis','axes'}))  %#ok for Matlab 6 compatibility
        myError('YMA:scrollplot:invalidProperty','No data specified for scrollplot property ''Axis''');
    end

    % Loop over all supplied P-V pairs to pre-process the parameters
    idx = 1;
    while idx < length(pvPairs)
        paramName = pvPairs{idx};
        if ~ischar(paramName),  idx=idx+1; continue;  end
        switch lower(paramName)
            % Get the last axes requested by the user (if any)
            % Check for 'axis' or 'axes' ('axes' is a typical typo of 'axis')
            case {'axis','axes'}
                axName = pvPairs{idx+1};
                % Ensure we got a valid axis name: 'x','y','xy' or 'yx'
                if ~ischar(axName) | ~any(strcmpi(axName,{'x','y','xy','yx'}))  %#ok for Matlab 6 compatibility
                    myError('YMA:scrollplot:invalidProperty','Invalid scrollplot ''Axis'' property value: only ''x'',''y'' & ''xy'' are accepted');
                end
                % Remove from the PV pairs list and move on
                axName = lower(axName);
                pvPairs(idx:idx+1) = [];

            % Placeholder for possible future pre-processed args
            otherwise
                % Skip...
                idx = idx + 1;
        end
    end
%end  % preProcessArgs  %#ok for Matlab 6 compatibility

%% Process P-V argument pairs
function processArgs(pvPairs,hScroll)
    try
        minLim = [];
        maxLim = [];
        hScroll = double(hScroll);  % Matlab 6 could not use findall with handle objects...
        axName = get(hScroll, 'userdata');
        if strcmpi(axName,'x')
            otherAxName = 'y';  %#ok mlint mistaken warning - used below
        else  % Y scroll
            otherAxName = 'x';  %#ok mlint mistaken warning - used below
        end
        dataStr = [axName 'Data'];
        limStr  = [axName 'Lim'];
        while ~isempty(pvPairs)
            % Ensure basic format is valid
            paramName = '';
            if ~ischar(pvPairs{1})
                myError('YMA:scrollplot:invalidProperty','Invalid property passed to scrollplot');
            elseif length(pvPairs) == 1
                myError('YMA:scrollplot:invalidProperty',['No data specified for property ''' pvPairs{1} '''']);
            end

            % Process parameter values
            paramName  = pvPairs{1};
            paramValue = pvPairs{2};
            pvPairs(1:2) = [];
            hScrollBars    = unique(findall(hScroll, 'tag','scrollBar'));
            hScrollPatches = unique(findall(hScroll, 'tag','scrollPatch'));
            switch lower(paramName)
                case {'min',['min' axName]}
                    set(hScrollBars(1:2:end), dataStr,paramValue([1,1]));
                    for patchIdx = 1 : length(hScrollPatches)
                        thisPatch = hScrollPatches(patchIdx);
                        data = get(thisPatch, dataStr);
                        if strcmpi(axName,'x')
                            set(thisPatch, dataStr,[paramValue([1;1]); data([4,4])]);
                        else  % Y scroll
                            set(thisPatch, dataStr,[paramValue(1); data([2,2]); paramValue(1)]);
                        end

                        % Update the parent axes with the new limit
                        hAx = getappdata(get(thisPatch,'Parent'), 'parent');
                        lim = get(hAx, limStr);
                        set(hAx, limStr,[paramValue,lim(2)]);
                    end
                    minLim = paramValue;

                case {'max',['max' axName]}
                    set(hScrollBars(2:2:end), dataStr,paramValue([1,1]));
                    for patchIdx = 1 : length(hScrollPatches)
                        thisPatch = hScrollPatches(patchIdx);
                        data = get(thisPatch, dataStr);
                        if strcmpi(axName,'x')
                            set(thisPatch, dataStr,[data([1,1]); paramValue([1;1])]);
                        else  % Y scroll
                            set(thisPatch, dataStr,[data(1); paramValue([1;1]); data(1)]);
                        end

                        % Update the parent axes with the new limit
                        hAx = getappdata(get(thisPatch,'Parent'), 'parent');
                        lim = get(hAx, limStr);
                        set(hAx, limStr,[lim(1),paramValue]);
                    end
                    maxLim = paramValue;

                case {'windowsize',['windowsize' axName]}
                    if isempty(pvPairs)
                        % No min,max after this param, so act based on data so far
                        if ~isempty(minLim)
                            if ~isempty(maxLim) & abs(maxLim-minLim-paramValue(1))>eps  %#ok for Matlab 6 compatibility
                                myError('YMA:scrollplot:invalidWindowSize','Specified WindowSize value conflicts with earlier values specified for Min,Max');
                            end
                            pvPairs = {'Max', minLim+paramValue(1), pvPairs{:}};  % note: can't do [...,pvPairs] because of a Matlab6 bug when pvPairs={}
                        elseif ~isempty(maxLim)  % Only max was specified...
                            pvPairs = {'Min', maxLim-paramValue(1), pvPairs{:}};
                        else
                            % No min,max: act based on actual min for each axes seperately
                            for scrollIdx = 1 : length(hScroll)
                                % Update the right side bar
                                thisScroll = hScroll(scrollIdx);
                                hScrollBars = unique(findall(thisScroll, 'tag','scrollBar'));
                                maxLim = get(hScrollBars(1), dataStr) + paramValue(1);
                                set(hScrollBars(2), dataStr,maxLim);

                                % Now update the patch
                                thisPatch = unique(findall(thisScroll, 'tag','scrollPatch'));
                                data = get(thisPatch, dataStr);
                                if strcmpi(axName,'x')
                                    set(thisPatch, dataStr,[data([1,1]); maxLim']);
                                else  % Y scroll
                                    set(thisPatch, dataStr,[data(1); maxLim'; data(1)]);
                                end

                                % Finally, update the parent axes with the new limit
                                hAx = getappdata(thisScroll, 'parent');
                                lim = get(hAx, limStr);
                                set(hAx, limStr,[lim(1),maxLim(1)]);
                            end
                        end
                    else
                        % Push this P-V pair to the end of the params list (after min,max)
                        pvPairs = {pvPairs{:}, paramName, paramValue(1)};
                    end

                % Not a good idea to let users play with position so easily...
                %case 'position'
                %    set(hScroll, 'position',paramValue);

                case {'axis','axes'}
                    % Do nothing (should never get here: should have been stripped by preProcessArgs()!)

                case {['min' otherAxName], ['max' otherAxName], ['windowsize' otherAxName]}
                    % Do nothing (pass to other axes for processing)

                otherwise
                    myError('YMA:scrollplot:invalidProperty','Unsupported property');

            end  % switch paramName
        end  % loop pvPairs
    catch
        if ~isempty(paramName),  paramName = [' ''' paramName ''''];  end
        myError('YMA:scrollplot:invalidHandle',['Error setting scrollplot property' paramName ':' char(10) lasterr]);
    end
%end  % processArgs  %#ok for Matlab 6 compatibility

%% Internal error processing
function myError(id,msg)
    v = version;
    if (v(1) >= '7')
        error(id,msg);
    else
        % Old Matlab versions do not have the error(id,msg) syntax...
        error(msg);
    end
%end  % myError  %#ok for Matlab 6 compatibility

%% Get ancestor figure - used for old Matlab versions that don't have a built-in ancestor()
function hObj = ancestor(hObj,type)
    if ~isempty(hObj) & ishandle(hObj)  %#ok for Matlab 6 compatibility
        %if ~isa(handle(hObj),type)  % this is best but always returns 0 in Matlab 6!
        if ~strcmpi(get(hObj,'type'),type)
            hObj = ancestor(get(handle(hObj),'parent'),type);
        end
    end
%end  % ancestor  %#ok for Matlab 6 compatibility

%% Helper function to extract first data value(s) from an array
function data = getFirstVals(vals)
    if isempty(vals)
        data = [];
    elseif iscell(vals)
        for idx = 1 : length(vals)
            thisVal = vals{idx};
            data(idx) = thisVal(1);  %#ok mlint - preallocate
        end
    else
        data = vals(:,1);
    end
%end  % getFirstVal  %#ok for Matlab 6 compatibility

%% Mouse movement outside the scroll patch area
function mouseOutsidePatch(hFig,inDragMode,hAx)  %#ok Hax is unused
    try
        % Restore the original figure pointer (probably 'arrow', but not necessarily)
        % On second thought, it should always be 'arrow' since zoom/pan etc. are disabled within hScroll
        %if ~isempty(hAx)
            % Only modify this within hScroll (outside the patch area) - not in other axes
            set(hFig, 'Pointer','arrow');
        %end
        oldPointer = getappdata(hFig, 'scrollplot_oldPointer');
        if ~isempty(oldPointer)
            %set(hFig, oldPointer{:});  % see comment above
            drawnow;
            rmappdataIfExists(hFig, 'scrollplot_oldPointer');
            if isappdata(hFig, 'scrollplot_mouseUpPointer')
                setappdata(hFig, 'scrollplot_mouseUpPointer',oldPointer);
            end
        end

        % Restore the original ButtonUpFcn callback
        if isappdata(hFig, 'scrollplot_oldButtonUpFcn')
            oldButtonUpFcn = getappdata(hFig, 'scrollplot_oldButtonUpFcn');
            axisComponent  = getappdata(hFig, 'scrollplot_oldButtonUpObj');
            if ~isempty(axisComponent)
                set(axisComponent, 'MouseReleasedCallback',oldButtonUpFcn);
            else
                set(hFig, 'WindowButtonUpFcn',oldButtonUpFcn);
            end
            rmappdataIfExists(hFig, 'scrollplot_oldButtonUpFcn');
        end

        % Additional cleanup
        rmappdataIfExists(hFig, 'scrollplot_mouseDownPointer');
        if ~inDragMode
            rmappdataIfExists(hFig, 'scrollplot_originalX');
            rmappdataIfExists(hFig, 'scrollplot_originalLimits');
        end
    catch
        % never mind...
        disp(lasterr);
    end
%end  % outsideScrollCleanup  %#ok for Matlab 6 compatibility

%% Mouse movement within the scroll patch area
function mouseWithinPatch(hFig,inDragMode,hAx,scrollPatch,cx,isOverBar)
    try
        % Separate actions for X,Y scrolling
        axName = get(hAx, 'userdata');
        if strcmpi(axName,'x')
            shapeStr = 'lrdrag';
        else
            shapeStr = 'uddrag';
        end
        dataStr = [axName 'Data'];
        limStr  = [axName 'Lim'];

        % If we have entered the scroll patch area for the first time
        axisComponent = getAxisComponent(hFig);
        if ~isempty(axisComponent)
            winUpFcn = get(axisComponent,'MouseReleasedCallback');
        else
            winUpFcn = get(hFig,'WindowButtonUpFcn');
        end
        if isempty(winUpFcn) | (~isequal(winUpFcn,@mouseUpCallback) & (~iscell(winUpFcn) | ~isequal(winUpFcn{1},@mouseUpCallback)))  %#ok for Matlab 6 compatibility
            % Set the ButtonUpFcn callbacks
            if ~isempty(winUpFcn)
                setappdata(hFig, 'scrollplot_oldButtonUpFcn',winUpFcn);
                setappdata(hFig, 'scrollplot_oldButtonUpObj',axisComponent);
            end
            if ~isempty(axisComponent)
                set(axisComponent, 'MouseReleasedCallback',{@mouseUpCallback,hFig});
            else
                oldWarn = warning('off','MATLAB:modes:mode:InvalidPropertySet');
                set(hFig, 'WindowButtonUpFcn',@mouseUpCallback);
                warning(oldWarn);
            end

            % Clear up potential junk that might confuse us later
            if ~inDragMode
                rmappdataIfExists(hFig, 'scrollplot_clickedBarIdx');
            end
        end

        % If this is a drag movement (i.e., mouse button is clicked)
        if inDragMode

            % Act according to the dragged object
            if isempty(scrollPatch)
                scrollPatch = findobj(hAx, 'tag','scrollPatch');
            end
            scrollBarIdx = getappdata(hFig, 'scrollplot_clickedBarIdx');
            scrollBars = sort(findobj(hAx, 'tag','scrollBar'));
            %barsXs = cellfun(@(c)c(1),get(scrollBars,dataStr));  % cellfun is very limited on Matlab 6...
            barsXs = getFirstVals(get(scrollBars,dataStr));
            if barsXs(1)>barsXs(2)  % happens after dragging one bar beyond the other
                scrollBarIdx = 3 - scrollBarIdx;  % []=>[], 1=>2, 2=>1
                scrollBars = scrollBars([2,1]);
            end
            oldPatchXs = get(scrollPatch, dataStr);
            axLimits = get(hAx, limStr);
            cx = min(max(cx,axLimits(1)),axLimits(2));
            if isempty(scrollBarIdx)  % patch drag
                originalX = getappdata(hFig, 'scrollplot_originalX');
                originalLimits = getappdata(hFig, 'scrollplot_originalLimits');
                if ~isempty(originalLimits)
                    allowedDelta = [min(0,axLimits(1)-originalLimits(1)), max(0,axLimits(2)-originalLimits(2))];
                    deltaX = min(max(cx-originalX, allowedDelta(1)), allowedDelta(2));
                    if strcmpi(get(hAx,[axName 'Scale']), 'log')
                        newLimits = 10.^(log10(originalLimits) + deltaX);
                    else  % linear axis scale
                        newLimits = originalLimits + deltaX;
                    end
                    %fprintf('%.3f ',[cx-originalX, deltaX, originalLimits(1), newLimits(1), allowedDelta])
                    %fprintf('\n');
                    if strcmpi(axName,'x')
                        set(scrollPatch,   dataStr,newLimits([1,1,2,2]));
                    else
                        set(scrollPatch,   dataStr,newLimits([1,2,2,1]));
                    end
                    set(scrollBars(1), dataStr,newLimits([1,1]));
                    set(scrollBars(2), dataStr,newLimits([2,2]));
                    setappdata(hFig, 'scrollplot_originalLimits', newLimits);
                    setappdata(hFig, 'scrollplot_originalX', cx);
                    if deltaX ~= 0
                        delete(findall(0,'tag','scrollHelp'));
                    end
                end
            elseif (scrollBarIdx == 1)  % left/bottom bar drag
                set(scrollBars(scrollBarIdx), dataStr,[cx,cx]);
                if strcmpi(axName,'x')
                    set(scrollPatch, dataStr,[cx,cx, max(oldPatchXs)*[1,1]]);
                else
                    set(scrollPatch, dataStr,[cx, max(oldPatchXs)*[1,1], cx]);
                end
                delete(findall(0,'tag','scrollHelp'));
            else  % right/top bar drag
                set(scrollBars(scrollBarIdx), dataStr,[cx,cx]);
                if strcmpi(axName,'x')
                    set(scrollPatch, dataStr,[min(oldPatchXs)*[1,1], cx,cx]);
                else
                    set(scrollPatch, dataStr,[cx, min(oldPatchXs)*[1,1], cx]);
                end
                delete(findall(0,'tag','scrollHelp'));
            end

            % Modify the parent axes accordingly
            parentAx = getappdata(hAx, 'parent');
            newXLim = unique(get(scrollPatch,dataStr));
            if length(newXLim) == 2  % might be otherwise if bars merge!
                if size(newXLim,1)==2,  newXLim = newXLim';  end  % needs to be a column array
                set(parentAx, limStr,newXLim);
            end

            % Mode managers (zoom/pan etc.) modify the cursor shape, so we need to force ours...
            newPtr = getappdata(hFig, 'scrollplot_mouseDownPointer');
            if ~isempty(newPtr)
                setptr(hFig, newPtr);
            end

        else  % Normal mouse movement (no drag)

            % Modify the cursor shape
            oldPointer = getappdata(hFig, 'scrollplot_oldPointer');
            if isempty(oldPointer)
                % Preserve original pointer shape for future use
                setappdata(hFig, 'scrollplot_oldPointer',getptr(hFig));
            end
            if isOverBar
                setptr(hFig, shapeStr);
                setappdata(hFig, 'scrollplot_mouseDownPointer',shapeStr);
            else
                setptr(hFig, 'hand');
                setappdata(hFig, 'scrollplot_mouseDownPointer','closedhand');
            end
        end
        drawnow;
    catch
        % never mind...
        disp(lasterr);
    end
%end  % mouseWithinPatch  %#ok for Matlab 6 compatibility

%% Mouse movement callback function
function mouseMoveCallback(varargin)
    try
        try
            % Temporarily turn off log-axis warnings
            oldWarn = warning('off','MATLAB:Axes:NegativeDataInLogAxis');
        catch
            % never mind...
        end

        % Get the figure's current axes
        hFig = gcbf;
        if isempty(hFig) | ~ishandle(hFig),  return;  end  %#ok just in case..
        %hAx = get(hFig,'currentAxes');
        hAx = getCurrentScrollAx(hFig);
        inDragMode = isappdata(hFig, 'scrollplot_clickedBarIdx');

        % Exit if already in progress - don't want to mess everything...
        if isappdata(hFig,'scrollBar_inProgress'),  return;  end

        % Fix case of Mode Managers (pan, zoom, ...)
        try
            modeMgr = get(hFig,'ModeManager');
            hMode = modeMgr.CurrentMode;
            set(hMode,'ButtonDownFilter',@shouldModeBeInactiveFcn);
        catch
            % Never mind - either an old Matlab (no mode managers) or no mode currently active
        end

        % If mouse pointer is not currently over any scroll axes
        if isempty(hAx) %& ~inDragMode  %#ok for Matlab 6 compatibility
            % Perform cleanup
            mouseOutsidePatch(hFig,inDragMode,hAx);
        else

            % Check whether the curser is over any side bar
            scrollPatch = findobj(hAx, 'tag','scrollPatch');
            isOverBar = 0;
            cx = [];
            if ~isempty(scrollPatch)
                scrollPatch = scrollPatch(1);
                axName = get(hAx,'userdata');
                cp = get(hAx,'CurrentPoint');
                cx = cp(1,1);
                cy = cp(1,2);
                xlim = get(hAx,'Xlim');
                ylim = get(hAx,'Ylim');
                limits = get(hAx,[axName 'Lim']);
                barXs = unique(get(scrollPatch,[axName 'Data']));
                if strcmpi(get(hAx,[axName 'Scale']), 'log')
                    fuzz = 0.01 * diff(log(abs(limits)));  % tolerances (1%) in axes units
                    barXs = log10(barXs);
                    if strcmpi(axName,'x')
                        cx = log10(cx);
                    else
                        cy = log10(cy);
                    end
                else
                    fuzz = 0.01 * diff(limits);  % tolerances (1%) in axes units
                end
                if isempty(barXs),  return;  end
                %disp(abs(cy-barXs)')
                if strcmpi(axName,'x')
                    inXTest = any(barXs-fuzz < cx) & any(cx < barXs+fuzz);
                    inYTest = (ylim(1) < cy) & (cy < ylim(2));
                    isOverBar = any(abs(cx-barXs)<fuzz); %(barXs-fuzz < cx) & (cx < barXs+fuzz));
                else  % Y scroll
                    inXTest = (xlim(1) < cx) & (cx < xlim(2));
                    inYTest = any(barXs-fuzz < cy) & any(cy < barXs+fuzz);
                    isOverBar = any(abs(cy-barXs)<fuzz); %(barXs-fuzz < cy) & (cy < barXs+fuzz));
                    cx = cy;  % for use in mouseWithinPatch below
                end
                scrollPatch = scrollPatch(inXTest & inYTest);
                if strcmpi(get(hAx,[axName 'Scale']), 'log')
                    cx = 10^cx;  % used below
                end
            end

            % From this moment on, don't allow any interruptions
            setappdata(hFig,'scrollBar_inProgress',1);

            % If we're within the scroll patch area
            if ~isempty(scrollPatch) | inDragMode  %#ok for Matlab 6 compatibility
                mouseWithinPatch(hFig,inDragMode,hAx,scrollPatch,cx,isOverBar);
            else
                % Perform cleanup
                mouseOutsidePatch(hFig,inDragMode,hAx);
            end
        end

        % Try to chain the original WindowButtonMotionFcn (if available)
        try
            hgfeval(getappdata(hFig, 'scrollplot_oldButtonMotionFcn'));
        catch
            % Never mind...
        end
    catch
        % Never mind...
        disp(lasterr);
    end
    rmappdataIfExists(hFig,'scrollBar_inProgress');

    % Restore original warnings (if available/possible)
    try
        warning(oldWarn);
    catch
        % never mind...
    end
%end  % mouseMoveCallback  %#ok for Matlab 6 compatibility

%% Mouse click down callback function
function mouseDownCallback(varargin)
    try
        % Modify the cursor shape (close hand)
        hFig = gcbf;  %varargin{3};
        if isempty(hFig) & ~isempty(varargin)  %#ok for Matlab 6 compatibility
            hFig = ancestor(varargin{1},'figure');
        end
        if isempty(hFig) | ~ishandle(hFig),  return;  end  %#ok just in case..
        setappdata(hFig, 'scrollplot_mouseUpPointer',getptr(hFig));
        newPtr = getappdata(hFig, 'scrollplot_mouseDownPointer');
        if ~isempty(newPtr)
            setptr(hFig, newPtr);
        end

        % Determine the clicked object: patch, left bar or right bar
        hAx = get(hFig,'currentAxes');
        if isempty(hAx),  return;  end
        axName = get(hAx,'userdata');
        limits = get(hAx,[axName 'Lim']);
        cp = get(hAx,'CurrentPoint');

        % Check whether the cursor is over any side bar
        barXs = [-inf,inf];
        scrollBarIdx = [];
        scrollPatch = findobj(hAx, 'tag','scrollPatch');
        if ~isempty(scrollPatch)
            scrollPatch = scrollPatch(1);
            dataStr = [axName 'Data'];
            barXs = unique(get(scrollPatch,dataStr));
            if isempty(barXs),  return;  end
            if strcmpi(axName,'x')
                cx = cp(1,1);
            else  % Y scroll
                cx = cp(1,2);  % actually, this gets the y value...
            end
            if strcmpi(get(hAx,[axName 'Scale']), 'log')
                fuzz = 0.01 * diff(log(abs(limits)));  % tolerances (1%) in axes units
                barXs = log10(barXs);
                cx = log10(cx);
            else
                fuzz = 0.01 * diff(limits);  % tolerances (1%) in axes units
            end
            inTest = abs(cx-barXs)<fuzz; %(barXs-fuzz < cx) & (cx < barXs+fuzz);
            scrollBarIdx = find(inTest);
            scrollBarIdx = scrollBarIdx(min(1:end));  %#ok - find(x,1) is unsupported on Matlab 6!
            if strcmpi(get(hAx,[axName 'Scale']), 'log')
                cx = 10^cx;       % used below
                barXs = 10.^barXs; % used below
            end

            % Re-sort side bars (might have been dragged one over the other...)
            scrollBars = sort(findobj(hAx, 'tag','scrollBar'));
            %barsXs = cellfun(@(c)c(1),get(scrollBars,'xdata'));  % cellfun is very limited on Matlab 6...
            barsXs = getFirstVals(get(scrollBars,dataStr));
            if barsXs(1)>barsXs(2)  % happens after dragging one bar beyond the other
                set(scrollBars(1), dataStr,barsXs(2)*[1,1]);
                set(scrollBars(2), dataStr,barsXs(1)*[1,1]);
            end
        end
        setappdata(hFig, 'scrollplot_clickedBarIdx',scrollBarIdx);
        setappdata(hFig, 'scrollplot_originalX',cx);
        setappdata(hFig, 'scrollplot_originalLimits',barXs);
    catch
        % Never mind...
        disp(lasterr);
    end
%end  % mouseDownCallback  %#ok for Matlab 6 compatibility

%% Mouse click up callback function
function mouseUpCallback(varargin)
    try
        % Restore the previous (pre-click) cursor shape
        hFig = gcbf;  %varargin{3};
        if isempty(hFig) & ~isempty(varargin)  %#ok for Matlab 6 compatibility
            hFig = varargin{3};
            if isempty(hFig)
                hFig = ancestor(varargin{1},'figure');
            end
        end
        if isempty(hFig) | ~ishandle(hFig),  return;  end  %#ok just in case..
        if isappdata(hFig, 'scrollplot_mouseUpPointer')
            mouseUpPointer = getappdata(hFig, 'scrollplot_mouseUpPointer');
            set(hFig,mouseUpPointer{:});
            rmappdata(hFig, 'scrollplot_mouseUpPointer');
        end

        % Cleanup data no longer needed
        rmappdataIfExists(hFig, 'scrollplot_clickedBarIdx');
        rmappdataIfExists(hFig, 'scrollplot_originalX');
        rmappdataIfExists(hFig, 'scrollplot_originalLimits');

        % Try to chain the original WindowButtonUpFcn (if available)
        oldFcn = getappdata(hFig, 'scrollplot_oldButtonUpFcn');
        if ~isempty(oldFcn) & ~isequal(oldFcn,@mouseUpCallback) & (~iscell(oldFcn) | ~isequal(oldFcn{1},@mouseUpCallback))  %#ok for Matlab 6 compatibility
            try
                hgfeval(oldFcn);
            catch
                %hgfeval(oldFcn,hFig,[]);
            end
        end
    catch
        % Never mind...
        disp(lasterr);
    end
%end  % mouseUpCallback  %#ok for Matlab 6 compatibility

%% Remove appdata if available
function rmappdataIfExists(handle, name)
    if isappdata(handle, name)
        rmappdata(handle, name)
    end
%end  % rmappdataIfExists  %#ok for Matlab 6 compatibility

%% Get the figure's java axis component
function axisComponent = getAxisComponent(hFig)
    try
        if isappdata(hFig, 'scrollplot_axisComponent')
            axisComponent = getappdata(hFig, 'scrollplot_axisComponent');
        else
            axisComponent = [];
            try oldWarn = warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'); catch, end
            javaFrame = get(hFig,'JavaFrame');
            axisComponent = get(javaFrame,'AxisComponent');
            axisComponent = handle(axisComponent, 'CallbackProperties');
            if ~isprop(axisComponent,'MouseReleasedCallback')
                axisComponent = [];  % wrong axisComponent...
            else
                setappdata(hFig, 'scrollplot_axisComponent',axisComponent);
            end
        end
    catch
        % never mind...
    end
    try warning(oldWarn); catch, end
%end  % getAxisComponent  %#ok for Matlab 6 compatibility

%% Get the scroll axes that the mouse is currently over
function hAx = getCurrentScrollAx(hFig)
    try
        hAx = [];
        scrollAxes = findall(hFig, 'tag','scrollAx');
        if isempty(scrollAxes),  return;  end  % should never happen...
        for axIdx = 1 : length(scrollAxes)
            scrollPos(axIdx,:) = getPixelPos(scrollAxes(axIdx));  %#ok mlint - preallocate
        end
        cp = get(hFig, 'CurrentPoint');  % in Matlab pixels
        inXTest = (scrollPos(:,1) <= cp(1)) & (cp(1) <= scrollPos(:,1)+scrollPos(:,3));
        inYTest = (scrollPos(:,2) <= cp(2)) & (cp(2) <= scrollPos(:,2)+scrollPos(:,4));
        hAx = scrollAxes(inXTest & inYTest);
        hAx = hAx(min(1:end));  % ensure we return no more than asingle hAx!
    catch
        % never mind...
        disp(lasterr);
    end
%end  % getCurrentScrollAx  %#ok for Matlab 6 compatibility

%% Get pixel position of an HG object
function pos = getPixelPos(hObj)
    try
        % getpixelposition is unvectorized unfortunately! 
        pos = getpixelposition(hObj);
    catch
        % Matlab 6 did not have getpixelposition nor hgconvertunits so use the old way...
        pos = getPos(hObj,'pixels');
    end
%end  % getPixelPos  %#ok for Matlab 6 compatibility

%% Get position of an HG object in specified units
function pos = getPos(hObj,units)
    % Matlab 6 did not have hgconvertunits so use the old way...
    oldUnits = get(hObj,'units');
    if strcmpi(oldUnits,units)  % don't modify units unless we must!
        pos = get(hObj,'pos');
    else
        set(hObj,'units',units);
        pos = get(hObj,'pos');
        set(hObj,'units',oldUnits);
    end
%end  % getPos  %#ok for Matlab 6 compatibility

%% Temporary setting property value for a read-only property
function setOnce(hndl,propName,propValue)
    try
        try  % HG1 UDD
            prop = findprop(hndl,propName);
            oldSetState = get(prop,'AccessFlags.PublicSet');
            set(prop,'AccessFlags.PublicSet','on');
            set(hndl,propName,propValue);
            set(prop,'AccessFlags.PublicSet',oldSetState);
        catch  % HG2 MCOS
            oldSetState = prop.SetAccess;
            prop.SetAccess = 'public';
            set(hndl,propName,propValue);
            prop.SetAccess = oldSetState;
        end
    catch
        % Never mind...
    end
%end  % setOnce  %#ok for Matlab 6 compatibility

%% Callback for parent axes property changes
function parentAxesChanged(schemaProp, eventData, hFig, hAx, hScrollPatch, hScrollBars, propName)  %#ok - first 2 are unused
    try
        if isempty(hFig) | ~ishandle(hFig),  return;  end  %#ok just in case..
        newPropVal = get(hAx,propName);
        hScroll = get(hScrollPatch, 'Parent');
        axName  = get(hScroll, 'userdata');
        if isappdata(hFig,'scrollBar_inProgress')
            % Update the special prop values
            if strcmpi(propName,[axName,'Lim'])
                setOnce(handle(hScroll),'ScrollMin',newPropVal(1));
                setOnce(handle(hScroll),'ScrollMax',newPropVal(2));
            end
            return;
        end
        switch propName
            case 'XLim'
                if strcmpi(axName,'x')
                    set(hScrollPatch,   'XData',newPropVal([1,1,2,2]));
                    set(hScrollBars(1), 'Xdata',newPropVal([1,1]));
                    set(hScrollBars(2), 'Xdata',newPropVal([2,2]));
                    setOnce(handle(hScroll),'ScrollMin',newPropVal(1));
                    setOnce(handle(hScroll),'ScrollMax',newPropVal(2));
                end

            case 'YLim'
                if strcmpi(axName,'y')
                    set(hScrollPatch,   'YData',newPropVal([1,2,2,1]));
                    set(hScrollBars(1), 'Ydata',newPropVal([1,1]));
                    set(hScrollBars(2), 'Ydata',newPropVal([2,2]));
                    setOnce(handle(hScroll),'ScrollMin',newPropVal(1));
                    setOnce(handle(hScroll),'ScrollMax',newPropVal(2));
                end

            case 'Position'
                if strcmpi(axName,'x')
                    newScrollPos = newPropVal .* [1, 1, 1, 0.10/0.80];
                    newScrollPos = newScrollPos - [0, 0.20/0.80*newPropVal(4), 0, 0];
                else  % Y scroll
                    newScrollPos = newPropVal .* [1, 1, 0.10/0.80, 1];
                    newScrollPos = newScrollPos + [(1+0.05/0.80)*newPropVal(3), 0, 0, 0];
                end
                axUnits = get(hAx, 'Units');  % units might be modified by Mode Managers bypassing listeners!
                set(hScroll, 'Units',axUnits, 'Position',newScrollPos);

            case {'Units','Parent','XDir','YDir','XScale','YScale'}
                set(hScroll, propName,newPropVal);

            otherwise
                % Do nothing...
        end
    catch
        % never mind...
        disp(lasterr);
    end
%end  % parentAxesChanged  %#ok for Matlab 6 compatibility

%% Determine whether a current mode manager should be active or not (filtered)
function shouldModeBeInactive = shouldModeBeInactiveFcn(hObj, eventData)  %#ok - eventData is unused
    try
        shouldModeBeInactive = 0;
        hFig = ancestor(hObj,'figure');
        hScrollAx = getCurrentScrollAx(hFig);
        shouldModeBeInactive = ~isempty(hScrollAx);
    catch
        % never mind...
        disp(lasterr);
    end
%end  % shouldModeBeActiveFcn  %#ok for Matlab 6 compatibility

%% hgfeval replacement for Matlab 6 compatibility
function hgfeval(fcn,varargin)
    if isempty(fcn),  return;  end
    if iscell(fcn)
        feval(fcn{1},varargin{:},fcn{2:end});
    elseif ischar(fcn)
        evalin('base', fcn);
    else
        feval(fcn,varargin{:});
    end
%end  % hgfeval  %#ok for Matlab 6 compatibility

%% Axis to screen coordinate transformation
function T = axis2Screen(ax)
%   computes a coordinate transformation T = [xo,yo,rx,ry] that
%   relates the normalized axes coordinates [xa,ya] of point [xo,yo]
%   to its screen coordinate [xs,ys] (in the root units) by:
%       xs = xo + rx * xa
%       ys = yo + ry * ya
%
%   See also SISOTOOL
%
%   Note: this is a modified internal function within moveptr()

    % Get axes normalized position in figure
    T = getPos(ax,'normalized');

    % Loop all the way up the hierarchy to the root
    % Note: this fixes a bug in Matlab 7's moveptr implementation
    parent = get(ax,'Parent');
    while ~isempty(parent)
        % Transform norm. axis coord -> parent coord.
        if isequal(parent,0)
            parentPos = get(0,'ScreenSize');  % Preserve screen units
        else
            parentPos = getPos(parent, 'normalized');  % Normalized units
        end
        T(1:2) = parentPos(1:2) + parentPos(3:4) .* T(1:2);
        T(3:4) = parentPos(3:4) .* T(3:4);
        parent = get(parent,'Parent');
    end
%end  % axis2Screen  %#ok for Matlab 6 compatibility

%% Get centran axis location
function axisCoord = getCenterCoord(hAx, axName)
    limits = get(hAx, [axName 'Lim']);
    if strcmpi(get(hAx,[axName 'Scale']), 'log')
        axisCoord = sqrt(abs(prod(limits)));  %=10^mean(log10(abs(limits)));
    else
        axisCoord = mean(limits);
    end
%end  %getCenterCoord  %#ok for Matlab 6 compatibility

%% Get normalized axis coordinates
function normCoord = getNormCoord(hAx, axName, curPos)
    limits = get(hAx, [axName 'Lim']);
    if strcmpi(get(hAx,[axName 'Scale']), 'log')
        normCoord = (log2(curPos) - log2(limits(1))) / diff(log2(limits));
    else
        normCoord = (curPos-limits(1)) / diff(limits);
    end
%end  % getNormCoord %#ok for Matlab 6 compatibility

%% moveptr replacement for Matlab 6 compatibility
function moveptr(hAx, x, y)
    % Compute normalized axis coordinates
    NormX = getNormCoord(hAx, 'x', x);
    NormY = getNormCoord(hAx, 'y', y);

    % Compute the new coordinates in screen units
    Transform = axis2Screen(hAx);
    NewLoc = Transform(1:2) + Transform(3:4) .* [NormX NormY];

    % Move the pointer
    set(0,'PointerLocation',NewLoc);
%end  % moveptr  %#ok for Matlab 6 compatibility

%% UiContextMenu callback - Move cursor to center of requested element
function moveCursor(varargin)
    try
        % Get the x,y location of the center of the requested object
        hScroll = handle(gca);
        hObj = get(gcbo,'UserData');
        x = mean(get(hObj,'XData'));
        y = mean(get(hObj,'YData'));

        % Move the mouse pointer to that location
        % Note: Matlab 6 did not have moveptr() so we use a local version above
        %moveptr(hScroll, 'init');
        %moveptr(hScroll, 'move', x, y);
        moveptr(hScroll, x, y);

        % Call mouseMoveCallback to update the pointer shape
        mouseMoveCallback;
        drawnow;
    catch
        % Never mind...
        disp(lasterr);
    end
%end  % moveCursor  %#ok for Matlab 6 compatibility

%% Callback when scroll axes are deleted
function deleteScrollAx(varargin)
    try
        % Update the parent Axes position
        hScroll = varargin{1};
        updateParentPos([],[],hScroll,'off');
        % Note: no need to remove hAx listeners since these are destroyed along with hScroll
    catch
        % Never mind - continue deletion process...
    end
%end  % deleteScrollAx  %#ok for Matlab 6 compatibility

%% Update parent figure position based on scroll axes visibility
function updateParentPos(schemaProp, eventData, hScroll,scrollVisibility)  %#ok first 2 params are unused
    try
        if nargin<4
            scrollVisibility = get(hScroll, 'visible');
        end

        % Update the parent Axes position
        hAx = get(hScroll, 'ParentAxesHandle');
        axPos = get(hAx,'position');
        axName = get(hScroll, 'userdata');
        hLabel = get(hAx, [axName 'Label']);
        set(hLabel, 'units','normalized');
        oldPos = get(hLabel, 'position');  % Get the label position before the axes change

        if strcmpi(scrollVisibility,'off')
            ax_dy1 =  1/0.80;
            ax_dy2 = -1/0.80;
            label_delta = 0.20/0.80;
        else  %'on'
            ax_dy1 = 0.80;
            ax_dy2 = 1;
            label_delta = -0.20/0.80;
        end

        if strcmpi(axName,'x')
            newPlotPos   = axPos .* [1, 1, 1, ax_dy1] + [0, 0.20*axPos(4)*ax_dy2, 0, 0];
        else  % Y scroll
            newPlotPos   = axPos .* [1, 1, ax_dy1, 1];
        end
        set(hAx, 'Position',newPlotPos);

        % Fix label position(s)
        if strcmpi(axName,'x')
            if ~isempty(oldPos) & oldPos(2)<0  %#ok for Matlab 6 compatibility
                % Only fix if the X label is on the bottom (usually yes)
                set(hLabel, 'position',oldPos+[0,label_delta,0]);
            end
        else  % Y scroll
            if ~isempty(oldPos) & oldPos(1)>0  %#ok for Matlab 6 compatibility
                % Only fix if the Y label is on the right side (usually not)
                set(hLabel, 'position',oldPos-[label_delta,0,0]);
            end
        end

        % Show/hide all the axes children (scroll patch, side-bars, text)
        set(findall(hScroll), 'Visible',scrollVisibility);

        % axisComponent gets re-created, so clear the cache
        hFig = ancestor(hScroll,'figure');
        rmappdata(hFig, 'scrollplot_axisComponent');
    catch
        % Never mind...
    end
%end  % updateParentPos  %#ok for Matlab 6 compatibility

%% Set mouse pointer
% this is a copy of setptr.m, copied here to remove reliance on this unsupported external function
function varargout = setptr(fig,curs,fname)
%SETPTR Set figure pointer.
%   SETPTR(FIG,CURSOR_NAME) sets the cursor of the figure w/ handle FIG 
%   according to the cursor_name:
%      'hand'    - open hand for panning indication
%      'hand1'   - open hand with a 1 on the back
%      'hand2'   - open hand with a 2 on the back
%      'closedhand' - closed hand for panning while mouse is down
%      'glass'   - magnifying glass
%      'glassplus' - magnifying glass with '+' in middle
%      'glassminus' - magnifying glass with '-' in middle
%      'lrdrag'  - left/right drag cursor
%      'ldrag'   - left drag cursor
%      'rdrag'   - right drag cursor
%      'uddrag'  - up/down drag cursor
%      'udrag'   - up drag cursor
%      'ddrag'   - down drag cursor
%      'add'     - arrow with + sign
%      'addzero' - arrow with 'o'
%      'addpole' - arrow with 'x'
%      'eraser'  - eraser
%      'help'    - arrow with question mark ?
%      'modifiedfleur' - modified fleur
%      'datacursor' - modified fleur with a hole in the center
%      'rotate' - modified fleur
%      [ crosshair | fullcrosshair | {arrow} | ibeam | watch | topl | topr ...
%      | botl | botr | left | top | right | bottom | circle | cross | fleur ]
%           - standard figure cursors
%
%   SetData=setptr(CURSOR_NAME) returns a cell array containing 
%   the Property Value pairs which correctly set the pointer to 
%   the CURSOR_NAME specified. 
%   
%   Example:
%       f = figure;
%       SetData=setptr('hand');set(f,SetData{:})
%
%   See also GETPTR
 
%   Author: T. Krauss, 10/95
%   Copyright 1984-2012 The MathWorks, Inc.

    % now for custom cursors:
    stringflag=0;
    if ischar(fig),
      if nargin==2,fname=curs;end
      curs=fig;fig=[];
      stringflag=1;
    end

    mac_curs = 1;
    switch curs
       case 'hand'
            cdata = [...
               NaN   NaN   NaN   NaN   NaN   NaN   NaN     1     1   NaN   NaN   NaN   NaN   NaN   NaN   NaN
               NaN   NaN   NaN     1     1   NaN     1     2     2     1     1     1   NaN   NaN   NaN   NaN
               NaN   NaN     1     2     2     1     1     2     2     1     2     2     1   NaN   NaN   NaN
               NaN   NaN     1     2     2     1     1     2     2     1     2     2     1   NaN     1   NaN
               NaN   NaN   NaN     1     2     2     1     2     2     1     2     2     1     1     2     1
               NaN   NaN   NaN     1     2     2     1     2     2     1     2     2     1     2     2     1
               NaN     1     1   NaN     1     2     2     2     2     2     2     2     1     2     2     1
                 1     2     2     1     1     2     2     2     2     2     2     2     2     2     2     1
                 1     2     2     2     1     2     2     2     2     2     2     2     2     2     1   NaN
               NaN     1     2     2     2     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN     1     2     2     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN     1     2     2     2     2     2     2     2     2     2     2     1   NaN   NaN
               NaN   NaN   NaN     1     2     2     2     2     2     2     2     2     2     1   NaN   NaN
               NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     2     1   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     1   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     1   NaN   NaN   NaN
               ];
           hotspot = [10 9];
           mac_curs = 0;
       case 'closedhand'
           cdata = [
               NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN   NaN
               NaN   NaN   NaN   NaN     1     1   NaN     1     1   NaN     1     1   NaN   NaN   NaN   NaN
               NaN   NaN   NaN     1     2     2     1     2     2     1     2     2     1     1   NaN   NaN
               NaN   NaN   NaN     1     2     2     2     2     2     2     2     2     1     2     1   NaN
               NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN   NaN     1     1     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN     1     2     2     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN     1     2     2     2     2     2     2     2     2     2     2     2     1   NaN
               NaN   NaN     1     2     2     2     2     2     2     2     2     2     2     1   NaN   NaN
               NaN   NaN   NaN     1     2     2     2     2     2     2     2     2     2     1   NaN   NaN
               NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     2     1   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     1   NaN   NaN   NaN
               NaN   NaN   NaN   NaN   NaN     1     2     2     2     2     2     2     1   NaN   NaN   NaN
               ];
           hotspot = [10 9];
           mac_curs = 0;
       case 'hand1'
         d = ['01801A702648264A124D1249680998818982408220822084108409C804080408'...
              '01801BF03FF83FFA1FFF1FFF6FFFFFFFFFFE7FFE3FFE3FFC1FFC0FF807F807F8'...
              '00090008']';
       case 'hand2'
         d = ['01801A702648264A124D1249680998C18922402220422084110409E804080408'...
              '01801BF03FF83FFA1FFF1FFF6FFFFFFFFFFE7FFE3FFE3FFC1FFC0FF807F807F8'...
              '00090008']';
       case 'glass'
         d = ['0F0030C04020402080108010801080104020402030F00F38001C000E00070002'...
              '0F0035C06AA05560AAB0D550AAB0D5506AA055703AF80F7C003E001F000F0007'...
              '00060006']';
       case 'glassplus'
            o=NaN; w=2; k=1;
            cdata = [...
                o o o o k k k k o o o o o o o o
                o o k k o w o w k k o o o o o o
                o k w o w k k o w o k o o o o o
                o k o w o k k w o w k o o o o o
                k o w o w k k o w o w k o o o o
                k w k k k k k k k k o k o o o o
                k o k k k k k k k k w k o o o o
                k w o w o k k w o w o k o o o o
                o k w o w k k o w o k o o o o o
                o k o w o k k w o w k w o o o o
                o o k k w o w o k k k k w o o o
                o o o o k k k k o w k k k w o o
                o o o o o o o o o o w k k k w o
                o o o o o o o o o o o w k k k w
                o o o o o o o o o o o o w k k k
                o o o o o o o o o o o o o w k w
                ];
           hotspot = [6 6];
           mac_curs = 0;
       case 'glassminus'
            o=NaN; w=2; k=1;
            cdata = [...
                o o o o k k k k o o o o o o o o
                o o k k o w o w k k o o o o o o
                o k w o w o w o w o k o o o o o
                o k o w o w o w o w k o o o o o
                k o w o w o w o w o w k o o o o
                k w k k k k k k k k o k o o o o
                k o k k k k k k k k w k o o o o
                k w o w o w o w o w o k o o o o
                o k w o w o w o w o k o o o o o
                o k o w o w o w o w k w o o o o
                o o k k w o w o k k k k w o o o
                o o o o k k k k o w k k k w o o
                o o o o o o o o o o w k k k w o
                o o o o o o o o o o o w k k k w
                o o o o o o o o o o o o w k k k
                o o o o o o o o o o o o o w k w
                ];
           hotspot = [6 6];
           mac_curs = 0;
       case 'lrdrag'
         d = ['00000280028002800AA01AB03EF87EFC3EF81AB00AA002800280028000000000'...
              '07C007C007C00FE01FF03FF87FFCFFFE7FFC3FF81FF00FE007C007C007C00000'...
              '00070007']';
       case 'ldrag'
         d = ['00000200020002000A001A003E007E003E001A000A0002000200020000000000'...
              '0700070007000F001F003F007F00FF007F003F001F000F000700070007000000'...
              '00070007']';
       case 'rdrag'
         d = ['000000800080008000A000B000F800FC00F800B000A000800080008000000000'...
              '00C000C000C000E000F000F800FC00FE00FC00F800F000E000C000C000C00000'...
              '00070007']';
       case 'uddrag'
         d = ['000000000100038007C00FE003807FFC00007FFC03800FE007C0038001000000'...
              '00000100038007C00FE01FF0FFFEFFFEFFFEFFFEFFFE1FF00FE007C003800100'...
              '00080007']';
       case 'udrag'
         d = ['000000000100038007C00FE003807FFC00000000000000000000000000000000'...
              '00000100038007C00FE01FF0FFFEFFFEFFFE0000000000000000000000000000' ...
              '00080007']';
       case 'ddrag'
         d = ['0000000000000000000000000000000000007FFC03800FE007C0038001000000'...
              '00000000000000000000000000000000FFFEFFFEFFFE1FF00FE007C003800100'...
              '00080007']';
       case 'add'
         cdata=[...
           2   2 NaN NaN NaN NaN NaN NaN NaN NaN   2 NaN NaN NaN NaN NaN
           2   1   2 NaN NaN NaN NaN NaN NaN   2   1   2 NaN NaN NaN NaN
           2   1   1   2 NaN NaN NaN NaN   2   2   1   2   2 NaN NaN NaN
           2   1   1   1   2 NaN NaN   2   1   1   1   1   1   2 NaN NaN
           2   1   1   1   1   2 NaN NaN   2   2   1   2   2 NaN NaN NaN
           2   1   1   1   1   1   2 NaN NaN   2   1   2 NaN NaN NaN NaN
           2   1   1   1   1   1   1   2 NaN NaN   2 NaN NaN NaN NaN NaN
           2   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   2   2   2   2   2 NaN NaN NaN NaN NaN
           2   1   1   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN NaN
           2   1   2 NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2   2 NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2 NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN NaN   2   2   2 NaN NaN NaN NaN NaN NaN NaN
        ];
           hotspot = [1 1];
           mac_curs = 0;
       case 'addpole'
         cdata=[...
           2   2 NaN NaN NaN NaN NaN   2   2   2 NaN NaN   2   2 NaN NaN
           2   1   2 NaN NaN NaN NaN   2   1   2 NaN   2   1   2 NaN NaN
           2   1   1   2 NaN NaN NaN NaN   2   1   2   1   2   2 NaN NaN
           2   1   1   1   2 NaN NaN NaN NaN   2   1   2 NaN NaN NaN NaN
           2   1   1   1   1   2 NaN NaN   2   1   2   1   2   2 NaN NaN
           2   1   1   1   1   1   2   2   1   2 NaN   2   1   2 NaN NaN
           2   1   1   1   1   1   1   2   2 NaN NaN NaN   2   2 NaN NaN
           2   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   2   2   2   2   2 NaN NaN NaN NaN NaN
           2   1   1   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN NaN
           2   1   2 NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2   2 NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2 NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN NaN   2   2   2 NaN NaN NaN NaN NaN NaN NaN
        ];
           hotspot = [1 1];
           mac_curs = 0;
       case 'addzero'
         cdata=[...
           2   2 NaN NaN NaN NaN NaN NaN   2   2   2   2   2 NaN NaN NaN
           2   1   2 NaN NaN NaN NaN   2   2   1   1   1   2   2 NaN NaN
           2   1   1   2 NaN NaN NaN   2   1   2   2   2   1   2 NaN NaN
           2   1   1   1   2 NaN NaN   2   1   2 NaN   2   1   2 NaN NaN
           2   1   1   1   1   2 NaN   2   1   2   2   2   1   2 NaN NaN
           2   1   1   1   1   1   2   2   2   1   1   1   2   2 NaN NaN
           2   1   1   1   1   1   1   2   2   2   2   2   2 NaN NaN NaN
           2   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   1   1   1   2 NaN NaN NaN NaN NaN NaN
           2   1   1   1   1   1   2   2   2   2   2 NaN NaN NaN NaN NaN
           2   1   1   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN NaN
           2   1   2 NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2   2 NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN NaN
           2 NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN   2   1   1   2 NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN NaN   2   2   2 NaN NaN NaN NaN NaN NaN NaN
        ];
           hotspot = [1 1];
           mac_curs = 0;
       case 'eraser'
         cdata = [...  
         NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
           1   1   1   1   1   1   1 NaN NaN NaN NaN NaN NaN NaN NaN NaN
           1   1   2   2   2   2   2   1 NaN NaN NaN NaN NaN NaN NaN NaN
           1   2   1   2   2   2   2   2   1 NaN NaN NaN NaN NaN NaN NaN
           1   2   2   1   2   2   2   2   2   1 NaN NaN NaN NaN NaN NaN
         NaN   1   2   2   1   2   2   2   2   2   1 NaN NaN NaN NaN NaN
         NaN NaN   1   2   2   1   2   2   2   2   2   1 NaN NaN NaN NaN
         NaN NaN NaN   1   2   2   1   2   2   2   2   2   1 NaN NaN NaN
         NaN NaN NaN NaN   1   2   2   1   2   2   2   2   2   1 NaN NaN
         NaN NaN NaN NaN NaN   1   2   2   1   2   2   2   2   2   1 NaN
         NaN NaN NaN NaN NaN NaN   1   2   2   1   1   1   1   1   1   1
         NaN NaN NaN NaN NaN NaN NaN   1   2   1   2   2   2   2   2   1
         NaN NaN NaN NaN NaN NaN NaN NaN   1   1   1   1   1   1   1   1
         NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
         NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN
        ];
           hotspot = [2 1];
           mac_curs = 0;
       case 'modifiedfleur'
          cdata = [...
          NaN NaN NaN NaN NaN NaN NaN 1   NaN NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN 1   1   1   1   1   1   2   1   1   1   1   1   1   1   NaN
          1   2   2   2   2   2   2   2   2   2   2   2   2   2   2   1
          NaN 1   1   1   1   1   1   2   1   1   1   1   1   1   1   NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN NaN 1   NaN NaN NaN NaN NaN NaN NaN NaN
          ];
          hotspot = [8,8];
          mac_curs = 0;
       case 'datacursor'
          cdata = [...
          NaN NaN NaN NaN NaN NaN NaN 1   NaN NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN 1   1   1   1   1   NaN NaN NaN 1   1   1   1   1   1   NaN
          1   2   2   2   2   2   NaN NaN NaN 2   2   2   2   2   2   1
          NaN 1   1   1   1   1   NaN NaN NaN 1   1   1   1   1   1   NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN 1   2   1   NaN NaN NaN NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN NaN 1   NaN NaN NaN NaN NaN NaN NaN NaN
          ];
          hotspot = [8,8];
          mac_curs = 0;      
       case 'rotate'
          cdata = [...
          NaN NaN NaN NaN NaN   2 NaN NaN NaN NaN NaN NaN  NaN NaN NaN NaN
          NaN NaN NaN NaN   2   1   2   1   1   1   1 NaN  NaN NaN NaN NaN
          NaN NaN NaN   2   1   1   1   2   2   2   2   1    1 NaN NaN NaN
          NaN NaN   2   1   1   1   1   2 NaN NaN NaN   2    2   1 NaN NaN
          NaN NaN   2   2   2   2   2 NaN NaN NaN NaN NaN  NaN   1 NaN NaN
          NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN   2 NaN NaN
          NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN NaN   1 NaN
          NaN NaN   1 NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN NaN   2 NaN
          NaN NaN   2 NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN NaN   1 NaN
          NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN NaN   2 NaN
          NaN NaN NaN   1 NaN NaN NaN NaN NaN NaN NaN NaN  NaN   1 NaN NaN
          NaN NaN NaN   2 NaN NaN NaN NaN NaN NaN NaN NaN  NaN   2 NaN NaN
          NaN NaN NaN NaN NaN   1 NaN NaN NaN NaN NaN   1  NaN NaN NaN NaN
          NaN NaN NaN NaN NaN   2 NaN NaN   1 NaN NaN   2  NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN NaN NaN   2 NaN NaN NaN  NaN NaN NaN NaN
          NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN NaN  NaN NaN NaN NaN
          ];
          hotspot = [8,8];
          mac_curs = 0;
       case 'help'
         d = ['000040006000707C78FE7CC67EC67F0C7F987C306C3046000630033003000000'...
              'C000E000F07CF8FEFDFFFFFFFFEFFFDEFFFCFFF8FE78EF78CF7887F807F80380'...
              '00010001']';
       case 'file'
           f=fopen(fname);
           d=fread(f);
           if length(d)~=137
               error(message('MATLAB:setptr:WrongLengthFile'))
           end
           d(length(d))=[];
       case 'forbidden'
           d=['07C01FF03838703C607CC0E6C1C6C386C706CE067C0C781C38381FF007C00000'...
              '1FF03FF87FFCF87EF0FFE1FFE3EFE7CFEF8FFF0FFE1FFC3E7FFC3FF81FF00FE0'...
              '00070007']'; 
       otherwise
           Data={'Pointer',curs};
           if ~stringflag, set(fig,Data{:});end
           if nargout>0,varargout{1}=Data;end
           return
    end

    if mac_curs
        ind = find(d<='9');
        d(ind)=d(ind)-'0';
        ind = find(d>='A');
        d(ind)=d(ind)-'A'+10;
        bitmap = d(1:64);
        bitmap = dec2bin(bitmap,4)-'0';
        bitmap = reshape(bitmap',16,16)';
        mask = d(65:128);
        mask = dec2bin(mask,4)-'0';
        mask = reshape(mask',16,16)';
        ind = mask==0;
        mask(ind) = NaN;

        cdata = -(-mask+bitmap-1);

        hotspot_h = d(129:132);
        hotspot_h = 16.^(3:-1:0)*hotspot_h;
        hotspot_v = d(133:136);
        hotspot_v = 16.^(3:-1:0)*hotspot_v;

        hotspot = [hotspot_h, hotspot_v]+1;
    end

    Data={'Pointer'            ,'custom' , ...
          'PointerShapeCData'  ,cdata    , ...
          'PointerShapeHotSpot',hotspot    ...
         };
    if ~stringflag, set(fig,Data{:}); end
    if nargout>0, varargout{1}=Data; end
%end  % setptr  %#ok for Matlab 6 compatibility

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  TODO  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - maybe add a blue diamond or a visual handle in center of side-bars?
% - fix or bypass Matlab 6 OpenGL warning due to patch FaceAlpha property
