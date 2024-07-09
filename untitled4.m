% Find the axes in the current figure
ax = gca;

% Change the scale of the axes to log-log
set(ax, 'XScale', 'log', 'YScale', 'log');

% Set the y-axis limit to 1e-6
ylim([1e-6, max(get(ax, 'YLim'))]);