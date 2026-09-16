function [activeSensor, eoScore, irScore, confidence, ...
          payloadStatus, switchReason] = ...
          sensorManager(t, lux, visibility, eoContrast, ...
                        deltaT, eoHealth, irHealth, ...
                        mode, manualSensor)

% ============================================
% ADAPTIVE EO / IR SENSOR MANAGER
% ============================================

persistent currentSensor
persistent candidateSensor
persistent candidateStart
persistent lastSwitchReason

% --------------------------------------------
% INITIALIZATION
% --------------------------------------------

if isempty(currentSensor)

    currentSensor = 1;       % Start with EO
    candidateSensor = 0;
    candidateStart = 0;
    lastSwitchReason = 0;

end


% ============================================
% PARAMETERS
% ============================================

hysteresis = 10;
confirmationTime = 2;


% ============================================
% EO PERFORMANCE MODEL
% ============================================

% Illumination normalization
L = log10(max(lux,0) + 1) / log10(10001);

L = min(max(L,0),1);


% Visibility normalization
V = visibility / 10;

V = min(max(V,0),1);


% EO contrast normalization
C = min(max(eoContrast,0),1);


% EO performance score
eoScore = 100 * ...
    (0.50*L + ...
     0.30*V + ...
     0.20*C);


% ============================================
% IR PERFORMANCE MODEL
% ============================================

% Thermal contrast normalization
T = abs(deltaT) / 10;

T = min(max(T,0),1);


% IR performance score
irScore = 100 * ...
    (0.70*T + ...
     0.30*V);


% ============================================
% MANUAL MODE
% ============================================

if mode == 1

    if manualSensor == 1 && eoHealth == 1

        currentSensor = 1;
        lastSwitchReason = 6;

    elseif manualSensor == 2 && irHealth == 1

        currentSensor = 2;
        lastSwitchReason = 6;

    elseif eoHealth == 1

        currentSensor = 1;

    elseif irHealth == 1

        currentSensor = 2;

    else

        currentSensor = 0;
        lastSwitchReason = 5;

    end

    candidateSensor = 0;
    candidateStart = t;


% ============================================
% AUTO MODE
% ============================================

else

    % ----------------------------------------
    % BOTH SENSORS FAILED
    % ----------------------------------------

    if eoHealth == 0 && irHealth == 0

        currentSensor = 0;

        candidateSensor = 0;
        candidateStart = t;

        lastSwitchReason = 5;


    % ----------------------------------------
    % EO FAILED
    % ----------------------------------------

    elseif eoHealth == 0 && irHealth == 1

        if currentSensor ~= 2

            lastSwitchReason = 3;

        end

        currentSensor = 2;

        candidateSensor = 0;
        candidateStart = t;


    % ----------------------------------------
    % IR FAILED
    % ----------------------------------------

    elseif irHealth == 0 && eoHealth == 1

        if currentSensor ~= 1

            lastSwitchReason = 4;

        end

        currentSensor = 1;

        candidateSensor = 0;
        candidateStart = t;


    % ----------------------------------------
    % BOTH SENSORS HEALTHY
    % ----------------------------------------

    else

        % ====================================
        % EO ACTIVE
        % ====================================

        if currentSensor == 1

            % Is IR significantly better?
            if irScore > eoScore + hysteresis

                if candidateSensor ~= 2

                    candidateSensor = 2;
                    candidateStart = t;

                else

                    % Has IR remained better
                    % for long enough?
                    if (t - candidateStart) >= ...
                            confirmationTime

                        currentSensor = 2;

                        candidateSensor = 0;

                        lastSwitchReason = 1;

                    end
                end

            else

                % Cancel pending switch
                candidateSensor = 0;
                candidateStart = t;

            end


        % ====================================
        % IR ACTIVE
        % ====================================

        elseif currentSensor == 2

            % Is EO significantly better?
            if eoScore > irScore + hysteresis

                if candidateSensor ~= 1

                    candidateSensor = 1;
                    candidateStart = t;

                else

                    if (t - candidateStart) >= ...
                            confirmationTime

                        currentSensor = 1;

                        candidateSensor = 0;

                        lastSwitchReason = 2;

                    end
                end

            else

                candidateSensor = 0;
                candidateStart = t;

            end


        % ====================================
        % RECOVERY FROM FAULT
        % ====================================

        else

            if eoScore >= irScore

                currentSensor = 1;

            else

                currentSensor = 2;

            end

        end
    end
end


% ============================================
% OUTPUTS
% ============================================

activeSensor = currentSensor;

switchReason = lastSwitchReason;


% --------------------------------------------
% CONFIDENCE
% --------------------------------------------

if currentSensor == 1

    confidence = eoScore;

elseif currentSensor == 2

    confidence = irScore;

else

    confidence = 0;

end


% --------------------------------------------
% PAYLOAD STATUS
%
% 0 = FAULT
% 1 = OPERATIONAL
% 2 = DEGRADED
% --------------------------------------------

if currentSensor == 0

    payloadStatus = 0;

elseif confidence >= 50

    payloadStatus = 1;

else

    payloadStatus = 2;

end