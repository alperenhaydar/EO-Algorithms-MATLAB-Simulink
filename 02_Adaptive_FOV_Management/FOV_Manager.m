function [activeMode, activeHFOV, pixelsOnTarget, ...
          widePixels, narrowPixels, targetInFOV] = ...
          fovManager(t, targetRange, trackConfidence, targetAz)

% =========================================================
% ADAPTIVE EO FIELD-OF-VIEW MANAGER
%
% activeMode:
% 1 = WIDE FOV
% 2 = NARROW FOV
% =========================================================


% =========================================================
% MEMORY
% =========================================================

persistent currentMode
persistent candidateMode
persistent candidateStart


% =========================================================
% INITIALIZATION
% =========================================================

if isempty(currentMode)

    currentMode = 1;        % Start in WIDE mode
    candidateMode = 0;
    candidateStart = 0;

end


% =========================================================
% EO CAMERA PARAMETERS
% =========================================================

horizontalResolution = 1920;

wideHFOV   = 30;     % degrees
narrowHFOV = 8;      % degrees

targetWidth = 2.0;   % metres


% =========================================================
% SAFETY
% =========================================================

targetRangeSafe = max(targetRange,1);


% =========================================================
% TARGET ANGULAR SIZE
% =========================================================

angularSize = ...
    2 * atan(targetWidth / (2 * targetRangeSafe)) ...
    * 180/pi;


% =========================================================
% PIXELS ON TARGET
% =========================================================

widePixels = ...
    (angularSize / wideHFOV) ...
    * horizontalResolution;

narrowPixels = ...
    (angularSize / narrowHFOV) ...
    * horizontalResolution;


% =========================================================
% TARGET INSIDE FOV?
% =========================================================

wideInFOV = ...
    abs(targetAz) <= wideHFOV/2;

narrowInFOV = ...
    abs(targetAz) <= narrowHFOV/2;


% =========================================================
% SWITCHING PARAMETERS
% =========================================================

% -------------------------
% WIDE -> NARROW
% -------------------------

enterConfidence = 0.72;

enterPixels = 3.0;

enterConfirmation = 2.0;


% -------------------------
% NARROW -> WIDE
% -------------------------

exitConfidence = 0.50;

exitPixels = 2.4;

exitConfirmation = 1.0;


% =========================================================
% WIDE MODE
% =========================================================

if currentMode == 1

    % NARROW mode is allowed only if:
    %
    % 1. Tracking confidence is high enough
    % 2. Target is large enough in WIDE image
    % 3. Target is inside NARROW FOV

    narrowCondition = ...
        trackConfidence >= enterConfidence && ...
        widePixels >= enterPixels && ...
        narrowInFOV;


    if narrowCondition

        % Start confirmation timer
        if candidateMode ~= 2

            candidateMode = 2;
            candidateStart = t;

        else

            % Condition must remain valid
            % for 2 seconds

            if (t - candidateStart) >= enterConfirmation

                currentMode = 2;

                candidateMode = 0;
                candidateStart = t;

            end

        end

    else

        % Cancel pending transition
        candidateMode = 0;
        candidateStart = t;

    end


% =========================================================
% NARROW MODE
% =========================================================

elseif currentMode == 2

    % Return to WIDE if any of these occur:
    %
    % 1. Track confidence becomes poor
    % 2. Target becomes too small / distant
    % 3. Target leaves NARROW FOV

    wideCondition = ...
        trackConfidence <= exitConfidence || ...
        widePixels <= exitPixels || ...
        ~narrowInFOV;


    if wideCondition

        % Start confirmation timer
        if candidateMode ~= 1

            candidateMode = 1;
            candidateStart = t;

        else

            % Condition must remain valid
            % for 1 second

            if (t - candidateStart) >= exitConfirmation

                currentMode = 1;

                candidateMode = 0;
                candidateStart = t;

            end

        end

    else

        % Cancel pending transition
        candidateMode = 0;
        candidateStart = t;

    end

end


% =========================================================
% OUTPUTS
% =========================================================

activeMode = currentMode;


% -------------------------
% WIDE ACTIVE
% -------------------------

if currentMode == 1

    activeHFOV = wideHFOV;

    pixelsOnTarget = widePixels;

    targetInFOV = double(wideInFOV);


% -------------------------
% NARROW ACTIVE
% -------------------------

else

    activeHFOV = narrowHFOV;

    pixelsOnTarget = narrowPixels;

    targetInFOV = double(narrowInFOV);

end

end