
fh = figure('color','white');
hold on
% Default color ordering
ColOrd = get(gca,'ColorOrder');
[m,n] = size(ColOrd);

for i=1:length(DATA)
    % Get color
    ColRow = rem(i,m);
    if ColRow == 0   % Will cycle through colors in order, 1...m
        ColRow = m;
    end
    thiscolor = ColOrd(ColRow,:);
    
    % Draw path
    plot(DATA(i).Trackables.Position(:,1), ...
         DATA(i).Trackables.Position(:,3), ...
         'Color', thiscolor, 'LineWidth',2);
    % Draw starting marker
    plot(DATA(i).Trackables.Position(1,1), ...
         DATA(i).Trackables.Position(1,3), ...
         '.','Color', thiscolor, 'MarkerSize',30);
    % Draw ending marker
    plot(DATA(i).Trackables.Position(end,1), ...
         DATA(i).Trackables.Position(end,3), ...
         'o','Color', thiscolor, 'MarkerSize',10);
end

% Plotting options, change for your application
%axis equal
xrange = [-0.5 0.5];   %Example
yrange = [-0.65 0.65]; %Example
xlim(xrange); ylim(yrange);
pbaspect( [ (xrange(2)-xrange(1)) (yrange(2) - yrange(1)) 1 ] );
%daspect([1 1 1]);
xlabel('X Position [m]','FontSize',14);
ylabel('Z Position [m]','FontSize',14);
set(gca,'FontSize',14);
hold off