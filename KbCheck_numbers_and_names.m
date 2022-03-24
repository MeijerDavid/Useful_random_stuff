%Avoid recording of the 'F9' key which is used to run this script
WaitSecs (0.3);

% Prevent keyboard presses to be executed within MATLAB (we don't want to edit this script!).           
ListenChar(2); 

KbName('UnifyKeyNames');

% % Defining keys for input 
% P.quitKey   = KbName('ESCAPE');       % To exit the program
% P.leftKey   = KbName('LeftArrow');    % To answer Left  
% P.rightKey  = KbName('RightArrow');   % To answer Right 
% P.upKey     = KbName('UpArrow');      % To answer Up  
% P.downKey   = KbName('DownArrow');    % To answer Down 
% P.leftMouseKey = KbName('left_mouse');% To answer with Left Mouse button
%     
% RestrictKeysForKbCheck([P.quitKey, P.leftKey, P.rightKey, P.upKey, P.downKey, P.leftMouseKey])

keyCodeMouse = [];
keyCode = [];

%RestrictKeysForKbCheck([KbName('left_mouse') KbName('ESCAPE')]);
MousePressed = 0;
KBpressed = 0;
while ~MousePressed && ~KBpressed
    [MousePressed, KbTimeTemp, keyCodeMouse, ~] = KbCheck(GetMouseIndices);
    [KBpressed, KbTime, keyCode] = KbCheck;
    if CharAvail
        character = GetChar;
    end
    %wheelDelta = GetMouseWheel([])                                         %This function does not work on Windows/Linux systems        
end

MouseNr = find(keyCodeMouse)
MouseName = KbName(keyCodeMouse)

if exist('character','var')
    character = character
    abs_character = abs(character)
end

KbNr = find(keyCode) 
KBName = KbName(keyCode)

RestrictKeysForKbCheck([]);

ListenChar(0); 