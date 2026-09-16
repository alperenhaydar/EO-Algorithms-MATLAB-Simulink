function [targetRange, trackConfidence, targetAz] = scenario(t, scenarioID)

% =========================================================
% IRREGULAR / PSEUDO-RANDOM EO TARGET SCENARIO
% scenarioID = 1...10
%
% All scenarios can produce WIDE <-> NARROW transitions.
% Higher IDs are generally more dynamic.
% =========================================================

persistent lastScenario
persistent nextEvent
persistent eventIndex

persistent missionState
persistent sameStateCount

persistent rangeCmd
persistent confidenceCmd
persistent azCmd

persistent rangeValue
persistent confidenceValue
persistent azValue


% =========================================================
% INITIALIZATION
% =========================================================

if isempty(lastScenario)

    lastScenario = scenarioID;

    nextEvent = 0;
    eventIndex = 0;

    % Start in conditions that favor WIDE
    missionState = 0;
    sameStateCount = 0;

    rangeValue = 4000;
    confidenceValue = 0.45;
    azValue = 0;

    rangeCmd = rangeValue;
    confidenceCmd = confidenceValue;
    azCmd = azValue;

end


% =========================================================
% RESET IF SCENARIO ID CHANGES
% =========================================================

if lastScenario ~= scenarioID

    lastScenario = scenarioID;

    nextEvent = t;
    eventIndex = 0;

    missionState = 0;
    sameStateCount = 0;

    rangeValue = 4000;
    confidenceValue = 0.45;
    azValue = 0;

    rangeCmd = rangeValue;
    confidenceCmd = confidenceValue;
    azCmd = azValue;

end


% =========================================================
% NEW RANDOM EVENT
% =========================================================

if t >= nextEvent

    eventIndex = eventIndex + 1;


    % -----------------------------------------------------
    % Repeatable pseudo-random numbers 0...1
    % -----------------------------------------------------

    x1 = sin(eventIndex*12.9898 + scenarioID*78.233) ...
        * 43758.5453;

    x2 = sin(eventIndex*37.719  + scenarioID*21.417) ...
        * 23421.6317;

    x3 = sin(eventIndex*71.137  + scenarioID*45.123) ...
        * 57324.9812;

    x4 = sin(eventIndex*18.731  + scenarioID*91.417) ...
        * 31245.1763;

    x5 = sin(eventIndex*53.927  + scenarioID*17.913) ...
        * 48153.7931;


    u1 = x1 - floor(x1);
    u2 = x2 - floor(x2);
    u3 = x3 - floor(x3);
    u4 = x4 - floor(x4);
    u5 = x5 - floor(x5);


    % =====================================================
    % RANDOM MODE CHANGE
    %
    % missionState:
    % 0 = conditions favor WIDE
    % 1 = conditions favor NARROW
    % =====================================================

    % Higher scenarioID -> higher chance of changing state
    switchProbability = ...
        0.40 + 0.035*(scenarioID-1);

    % Maximum about 0.715
    switchProbability = ...
        min(max(switchProbability,0.40),0.72);


    if u5 < switchProbability

        missionState = 1 - missionState;
        sameStateCount = 0;

    else

        sameStateCount = sameStateCount + 1;

    end


    % -----------------------------------------------------
    % Do not allow staying in same condition forever.
    % Forces diversity even in Scenario 1 and 2.
    % -----------------------------------------------------

    if sameStateCount >= 2

        missionState = 1 - missionState;
        sameStateCount = 0;

    end


    % =====================================================
    % NARROW-FAVORABLE CONDITION
    % =====================================================

    if missionState == 1

        % Target relatively close
        rangeCmd = ...
            1500 + 800*u1;       % 1500 - 2300 m

        % Good tracking confidence
        confidenceCmd = ...
            0.78 + 0.17*u2;      % 0.78 - 0.95

        % Target remains inside narrow FOV
        azCmd = ...
            -2.8 + 5.6*u3;       % -2.8 ... +2.8 deg


    % =====================================================
    % WIDE-FAVORABLE CONDITION
    % =====================================================

    else

        % Target farther away
        rangeCmd = ...
            3200 + 1600*u1;      % 3200 - 4800 m

        % Lower track confidence
        confidenceCmd = ...
            0.28 + 0.25*u2;      % 0.28 - 0.53


        % Sometimes target leaves narrow FOV.
        if u3 > 0.50

            % Positive side
            azCmd = ...
                4.3 + 2.0*u4;    % +4.3 ... +6.3 deg

        else

            % Negative side
            azCmd = ...
                -6.3 + 2.0*u4;   % -6.3 ... -4.3 deg

        end

    end


    % =====================================================
    % IRREGULAR EVENT INTERVAL
    % =====================================================

    % Scenario 1 still changes,
    % but Scenario 10 changes faster.

    minInterval = ...
        11 - 0.55*(scenarioID-1);

    maxInterval = ...
        23 - 0.85*(scenarioID-1);


    % Safety limits
    minInterval = max(minInterval,5);
    maxInterval = max(maxInterval,10);


    eventInterval = ...
        minInterval ...
        + (maxInterval-minInterval)*u4;

    nextEvent = t + eventInterval;

end


% =========================================================
% SMOOTH TRANSITIONS
% =========================================================

% These make signals move naturally instead of jumping.

alphaRange = 0.035;
alphaConfidence = 0.045;
alphaAz = 0.040;


rangeValue = ...
    rangeValue ...
    + alphaRange*(rangeCmd-rangeValue);


confidenceValue = ...
    confidenceValue ...
    + alphaConfidence*(confidenceCmd-confidenceValue);


azValue = ...
    azValue ...
    + alphaAz*(azCmd-azValue);


% =========================================================
% LIMITS
% =========================================================

rangeValue = ...
    min(max(rangeValue,1500),4800);

confidenceValue = ...
    min(max(confidenceValue,0.25),0.95);

azValue = ...
    min(max(azValue,-6.5),6.5);


% =========================================================
% OUTPUTS
% =========================================================

targetRange = rangeValue;
trackConfidence = confidenceValue;
targetAz = azValue;

end