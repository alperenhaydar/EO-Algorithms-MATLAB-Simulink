function [trueAngle, trueRate, measuredAngle] = losScenario(t)

% =========================================================
% EO LINE-OF-SIGHT TEST SCENARIO
%
% trueAngle     = Actual target LOS angle [deg]
% trueRate      = Actual angular rate [deg/s]
% measuredAngle = Noisy camera measurement [deg]
% =========================================================


% ---------------------------------------------------------
% TRUE TARGET ANGLE
% ---------------------------------------------------------

trueAngle = ...
    5.0*sin(0.35*t) ...
    + 2.5*sin(0.11*t + 0.8) ...
    + 1.2*sin(0.75*t);


% ---------------------------------------------------------
% TRUE ANGULAR RATE
%
% Analytical derivative of trueAngle
% ---------------------------------------------------------

trueRate = ...
    5.0*0.35*cos(0.35*t) ...
    + 2.5*0.11*cos(0.11*t + 0.8) ...
    + 1.2*0.75*cos(0.75*t);


% ---------------------------------------------------------
% CAMERA / SENSOR MEASUREMENT NOISE
% ---------------------------------------------------------

noise = ...
    0.45*sin(13.7*t) ...
    + 0.22*sin(29.3*t + 1.1) ...
    + 0.12*sin(47.5*t + 0.4);


% ---------------------------------------------------------
% SHORT SENSOR DISTURBANCES
% ---------------------------------------------------------

glitch1 = 0.8 * exp(-((t-18)/0.12)^2);

glitch2 = -1.0 * exp(-((t-37)/0.10)^2);

glitch3 = 0.7 * exp(-((t-51)/0.15)^2);


% ---------------------------------------------------------
% CAMERA MEASUREMENT
% ---------------------------------------------------------

measuredAngle = ...
    trueAngle ...
    + noise ...
    + glitch1 ...
    + glitch2 ...
    + glitch3;

end