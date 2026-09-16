function [lux, visibility, eoContrast, deltaT, ...
    eoHealth, irHealth] = scenario(t)

% ============================================
% ADAPTIVE EO/IR TEST SCENARIO
% ============================================

% --------------------------------------------
% AMBIENT ILLUMINATION
% Day -> sunset -> night
% --------------------------------------------

lux = 50000 * exp(-0.09*t) + 1;


% --------------------------------------------
% VISIBILITY
% Slowly changing atmospheric visibility
% --------------------------------------------

visibility = 12 ...
    - 0.035*t ...
    + 1.0*sin(0.07*t);

visibility = min(max(visibility,2),15);


% --------------------------------------------
% EO SCENE CONTRAST
% Slowly changing visible scene contrast
% --------------------------------------------

eoContrast = 0.78 ...
    - 0.0015*t ...
    + 0.05*sin(0.10*t);

eoContrast = min(max(eoContrast,0.30),1);


% --------------------------------------------
% THERMAL CONTRAST
%
% First increases during night conditions.
% Then decreases due to thermal crossover.
% --------------------------------------------

riseTerm = 5 / ...
    (1 + exp(-(t-55)/6));

fallTerm = 8 / ...
    (1 + exp(-(t-90)/4));

deltaT = 3 + riseTerm - fallTerm;

deltaT = max(deltaT,0.5);


% --------------------------------------------
% SENSOR HEALTH
% --------------------------------------------

eoHealth = 1;
irHealth = 1;

% EO sensor fault
if t >= 105
    eoHealth = 0;
end

% IR sensor fault
if t >= 114
    irHealth = 0;
end