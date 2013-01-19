function simpleGUI(y, fs, recordTime, audioMode)

    global buttonVals done
%     recordTime = 3;

    hFig = figure('Visible','off', 'Menu','none', 'Name','Calculator', 'Resize','on', 'Position',[100 100 500 200]);
    movegui(hFig,'center')          %# Move the GUI to the center of the screen

    errorBtnGrp = uibuttongroup('Position',[0 0 .4 1], 'Units','Normalized','Title','ACCURACY');
    uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15 150 135 30], 'String','Accurate', 'Tag','accurate')
    uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15 120 135 30], 'String','Silence', 'Tag','silence')
    uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  90 135 30], 'String','Error, Use', 'Tag','error_use')
    uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  60 135 30], 'String','Error, Unrecognizable', 'Tag','error_unrecog')
    uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  30 135 30], 'String','Error, Unfinished', 'Tag','error_unfinish')

    
    fluentBtnGrp = uibuttongroup('Position',[.4 0 .4 1], 'Units','Normalized','Title','FLUENCY');
    uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15 150 135 30], 'String','Fluent', 'Tag','fluent')
    uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15 120 135 30], 'String','Stutter, Rep', 'Tag','st_rep')
    uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  90 135 30], 'String','Stutter, Prolong', 'Tag','st_pro')
    uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  60 135 30], 'String','Stutter, Mid-word block', 'Tag','st_block')
    uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  30 135 30], 'String','Stutter, Cluster', 'Tag','st_clust')
    
	uicontrol('Style','pushbutton', 'String','Play', 'Position',[420 120 60 50], 'Callback',{@button2_callback, audioMode})
    uicontrol('Style','pushbutton', 'String','Submit', 'Position',[420 35 60 50], 'Callback',{@button_callback})
    
    set(hFig, 'Visible','on')        %# Make the GUI visible

    %# callback function
    function [returnVars] = button_callback(src, ev)
        a = get(get(errorBtnGrp,'SelectedObject'),'Tag');
        b = get(get(fluentBtnGrp,'SelectedObject'),'Tag');

        switch a
            case 'accurate'
                buttonVals{1} = 1;
            case 'silence'
                buttonVals{1} = 2;
            case 'error_use'
                buttonVals{1} = 3;
            case 'error_unrecog'
                buttonVals{1} = 4;
            case 'error_unfinish'
                buttonVals{1} = 5;
        end
        
        switch b
            case 'fluent'
                buttonVals{2} = 1;
            case 'st_rep'
                buttonVals{2} = 2;
            case 'st_pro'
                buttonVals{2} = 3;
            case 'st_block'
                buttonVals{2} = 4;
            case 'st_clust'
                buttonVals{2} = 5;
        end

        display('Submitting...');
        done = 1;
        close(gcbf);
    end

    %play sound
    function [returnVars] = button2_callback(src, ev, audioMode)
%         if ~isempty(strfind(lower(getenv('OS')), 'windows'))
        if isequal(audioMode, 'soundsc')
            soundsc(y(1:round(recordTime*fs)), fs);
        elseif isequal(audioMode, 'wavplay')
            wavplay(y(1:round(recordTime*fs)), fs);
        else
            ap = audioplayer(y(1:round(recordTime*fs)), fs);
            play(ap, 1);
        end
    end
end