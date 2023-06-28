
% Initialize keys for input 
KbName('UnifyKeyNames');            %Always do this first before calling KbName commands.

% Defining keys of interest for input 
enterKey  = KbName('Return');       % To start the program
quitKey   = KbName('ESCAPE');       % To exit the program
leftKey   = KbName('l');            %'leftArrow');    % To answer Left
rightKey  = KbName('r');            %'rightArrow');   % To answer Right

keysOfInterest=zeros(1,256);
keysOfInterest([quitKey,leftKey,rightKey])=1;

% First ask for confirmation to continue: 
% This ensures that we go to the command window, instead of typing in the script itself. 
% This is normally prevented by ListenChar(2), but we cannot call that command because we use KbQueue functions. 
RestrictKeysForKbCheck([enterKey,quitKey]);
h = msgbox('Press ENTER to start or ESCAPE to quit');           %The messagebox remains open throughout the rest of the program and only closes at the end,
                                                                %so all key responses go towards the msgbox and not the editor (hence they do not end up in the script).     
[~, keyCode] = KbWait([],3); %Wait until button-press

if strcmpi(KbName(keyCode),'ESCAPE') %Don't run program
    
    fprintf('\n\n You have cancelled program execution, nothing happened \n\n');

elseif strcmpi(KbName(keyCode),'Return') %Start program
    
    % Make sure we're running on PTB-3
    AssertOpenGL;

    % It's a good habit to run PTB within a try-catch loop - in case an error appears there is a chance to close the windows etc. in the catch.
    try

        % Initialize Screen
        % Get the list of Screens and choose the one with the highest screen number. Screen 0 is, by definition, the display with the menu bar.
        % Often when two monitors are connected the one without the menu bar is used as the stimulus display.  
        % Choosing the display with the highest dislay number is a best guess about where you want the stimulus displayed.
        screens = Screen('Screens');
        screenNumber = max(screens);
        % Open window. 
        [w,winRect]=PsychImaging('OpenWindow',screenNumber,0);
        % Hide the cursor
        HideCursor;
        % Colours
        white = WhiteIndex(screenNumber);
        black = BlackIndex(screenNumber);
        grey = round((white + black) / 2);
        % Text Specifics
        Screen('TextFont',w,'Arial');
        Screen('TextSize',w,30);
        Screen('TextStyle',w,0);                %0=normal, 1=bold, 2=italic, 4=underline
        Screen('TextColor',w,grey);
        
        % Measure monitor refresh interval.
        % Flip three times (bug). Otherwise screen will start flickering
        Screen('Flip',w,[],black);    Screen('Flip',w,[],black);     Screen('Flip',w,[],black);
        % This will trigger a calibration loop of minimum 100 valid samples and return the estimated inter-flip-interval in 'w_ifi': interflip interval (in seconds).
        % We require an accuracy of 0.5 ms == 0.0005 secs. If this level of accuracy can't be reached, we time out after 5 seconds.  
        [w_ifi,nvalid,stddev] = Screen('GetFlipInterval',w,100,0.0005,5);
        fprintf('Measured refresh interval, as reported by "GetFlipInterval" is %3.5f ms. (nsamples = %i, stddev = %3.5f ms)\n\n',w_ifi*1000,nvalid,stddev*1000);
        %We want to flip the screen every 100 ms: how many flips is that?
        duration_in_nFlips = round(0.1/w_ifi);                                  %at 60Hz monitor this is exactly 6 flips.
        
        % Draw welcome text
        myText = 'Press left or right buttons for 10 seconds, \n\n\n';
        myText = [myText 'or press ESCAPE to quit earlier. \n\n\n'];
        myText = [myText 'now press Enter to start (the timing). \n\n\n'];
        DrawFormattedText(w, myText, 'center', 'center');
        Screen('Flip', w, [], black);
        
        % Wait for button press to start
        keyCode = [];
        pressedBool = 0;
        while pressedBool == 0
            [pressedBool,~, keyCode] = KbCheck();
        end
        
        % Start if Enter button was pressed
        if strcmpi(KbName(keyCode),'ESCAPE')
            fprintf('\n\n You have cancelled program execution, nothing happened \n\n');
        elseif strcmpi(KbName(keyCode),'Return')
        
            % Reset the key-buffer which holds the captured characters by calling ListenChar(0).
            % This is necessary in order to use KbQueue commands as well as KbWaitTrigger, KbEventFlush, KbEventAvail, and KbEventGet. 
            % Those commands are off limits after any call to ListenChar, ListenChar(1), ListenChar(2), FlushEvents, CharAvail or GetChar (which are used by KbCheck and KbWait). 
            ListenChar(0);
            % Create the queue for the default (-1) device number. The second argument 'keyList' is an optional 256-length vector of doubles (not logicals).
            % If the double value corresponding to a particular key is zero, events for that key are not added to the queue and will not be reported.
            % No events are delivered to the queue until KbQueueStart or KbQueueWait is called. KbQueueCreate can be called again at any time.
            % We restrict the operation of KbQueueCheck (et al.) to a subset of keys on the keyboard and use the default device.
            KbQueueCreate([], keysOfInterest);
            
            % Perform an initial Screen Flip
            DrawFormattedText(w, '0.0', 'center', 'center');
            [tvbl,visOnset] = Screen('Flip', w, [], black);                             
            % Video cards mark the end of each video frame by briefly reducing the voltage to the Vertical Blanking Level (VBL), which "blanks" the screen to black. 
            % Psychtoolbox does all video timing relative to the beginning of blanking (tvbl: system time in seconds). This is the onset of the exchange of front- 
            % and back drawing surfaces and it is the crucial reference value for computing the 't_deadline' presentation deadline for the next 'Flip' command.
            % visOnset is the estimated visual stimulus onset time a.k.a. the end of the VBL - This is the beginning (t = 0 ms) of the response time.
            firstVideoOnsetTime = visOnset;
            timing_video_onsets = firstVideoOnsetTime;
            
            % Start delivering keyboard events from the specified device to the queue. Note that we still execute the code below while keyboard events are registered.      
            KbQueueStart();                     
            timing_keyboard_presses = [];                   %every entry will get its own row. 1st column is keyCode. 2nd column is pressTime. 3rd column is releaseTime
            
            % Initialize timing variables (in seconds)
            maximum_time = 10;
            recorded_time = 0;
                        
            % Record keyboard entries for as long as the maximum_time allows or until ESCAPE is pressed (we read them out once every 100 ms)     
            ESCpressedBool = 0;
            while recorded_time + duration_in_nFlips*w_ifi < maximum_time && ESCpressedBool == 0
                
                % Collect keyboard events since KbQueueStart was invoked       
                [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck();
                % Register keyboard presses
                if pressed
                    pressedCodes=find(lastPress);
                    for i=1:size(pressedCodes,2)
                        pressedKey = pressedCodes(i);
                        pressTime = lastPress(pressedCodes(i))-firstVideoOnsetTime;
                        %if not the very first keyPress
                        if ~isempty(timing_keyboard_presses)
                            %see whether this key has been pressed before
                            row_position = find(timing_keyboard_presses(:,1) == pressedKey,1,'last');
                            %if another entry of this key already exists
                            if ~isempty(row_position) 
                                %but if it doesn't have the same pressTime
                                if timing_keyboard_presses(row_position,2) ~= pressTime 
                                    %then it is new input
                                    timing_keyboard_presses = [timing_keyboard_presses; pressedCodes(i) pressTime nan];   
                                end
                            %if this key has not been pressed before    
                            else
                                %then it is new input
                                timing_keyboard_presses = [timing_keyboard_presses; pressedCodes(i) pressTime nan];       
                            end
                        %if this is the first input    
                        else
                            %then it is new input
                            timing_keyboard_presses = [timing_keyboard_presses; pressedCodes(i) pressTime nan];           
                        end
                    end
                    % if escape has been pressed
                    if ismember(quitKey,pressedCodes)
                        ESCpressedBool = 1;             %stop the while loop and close the program
                    end
                end
                % Register keyboard releases
                if sum(lastRelease) > 0                 %if one or more keys have been released
                    releasedCodes=find(lastRelease);
                    for i=1:size(releasedCodes,2)
                        releasedKey = releasedCodes(i);
                        releaseTime = lastRelease(releasedCodes(i))-firstVideoOnsetTime;
                        row_position = find(timing_keyboard_presses(:,1) == releasedKey,1,'last');
                        timing_keyboard_presses(row_position,3) = releaseTime;
                    end
                end
                
                % Update timing variables
                t_deadline = tvbl + (duration_in_nFlips - 0.5)*w_ifi;                       %we substract 0.5*w_ifi so the screen gets the flip command a bit earlier and flips on the next possibility.
                recorded_time = recorded_time + duration_in_nFlips*w_ifi;                   %we add nScreenflips to timing
                recorded_time_displayed = round(recorded_time*10)/10;                       %display the recorded time rounded to tenth of seconds
                
                % Flip Screen
                DrawFormattedText(w, num2str(recorded_time_displayed), 'center', 'center'); %Draw the timer counter on the screen
                [tvbl,visOnset] = Screen('Flip',w,t_deadline,black);                        %wait until deadline to flip the screen (this is the most accurate timing mechanism)                   
                
                % Record timing of the video
                timing_video_onsets = [timing_video_onsets visOnset];
                
            end
            
            % Stop delivery of new keyboard events from the specified device to the queue. Data regarding events already queued is not cleared and can be recovered by KbQueueCheck
            KbQueueStop();
            % Remove all unprocessed events from the queue and zero out any already scored events.
            KbQueueFlush();
            % Release all queue-associated resources; once called, KbQueueCreate must be invoked before using any of the other routines.
            KbQueueRelease();                   
            
            % Sort all entries according to their pressedTimes
            [timing_keyboard_presses(:,2),indices] = sort(timing_keyboard_presses(:,2));
            timing_keyboard_presses(:,1) = timing_keyboard_presses(indices,1);
            timing_keyboard_presses(:,3) = timing_keyboard_presses(indices,3);
            
            % Compute keyPress durations as a 4th column
            timing_keyboard_presses(:,4) = timing_keyboard_presses(:,3) - timing_keyboard_presses(:,2);                 %Notice that duration == 0 if keyboard was not released yet.
            
            % Compute screenFlip times in ms
            timing_video_onsets = [timing_video_onsets; nan timing_video_onsets(2:end)-timing_video_onsets(1:end-1)];   %Flip intervals are the second row of the timing_video_onsets.
            
        end
        
        % Clean up
        ShowCursor;                         % Show cursor
        Screen('CloseAll');                 % Close display
        
    catch

        % Clean up
        ShowCursor;                         % Show cursor
        Screen('CloseAll');                 % Close display

        psychrethrow(psychlasterror);       % Show the error message

    end %end of try-catch
    
end %end of if-statement "to start or not"