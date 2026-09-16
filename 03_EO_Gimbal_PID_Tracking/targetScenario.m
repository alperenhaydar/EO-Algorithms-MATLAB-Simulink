function targetDeg = targetScenario(t)

% Main target motion
motion = ...
    4.0*sin(0.35*t) ...
    + 2.0*sin(0.83*t) ...
    + 1.2*sin(0.17*t);

% Smooth startup envelope
startup = 1 - exp(-t/2);

targetDeg = startup * motion;

% Limit
targetDeg = min(max(targetDeg,-8),8);

end