function [median_sum_diffs,CI95_sum_diffs] = bootstrapFFX(LLs,refModelNr,nBootstrap,displayBool,colors)
%Perform a bootstrap fixed effects model comparison analysis and plot

%Find number of subjects and models
[nSubjects,nModels] = size(LLs);

%Set some defaults
if nargin < 2
    refModelNr = 1;
end
if nargin < 3
    nBootstrap = 10000;
end
if nargin < 4
    displayBool = 1;
end
if nargin < 5
    colors = [];
end

%Bootstrap the mean differences
rng('shuffle');
diffWithRef = LLs-repmat(LLs(:,refModelNr),[1 nModels]);                    %Subtract the LLs of the reference model from all other models
bootstrap_sum_diffs = nan(nBootstrap,nModels);
for b=1:nBootstrap
    idxB = randsample(nSubjects,nSubjects,true);                            %Pick at random nSubjects subjIDs (with replacement) 
    bootstrap_sum_diffs(b,:) = sum(diffWithRef(idxB,:),1);                  %Sum the differences (fixed effects analysis)
end
median_sum_diffs = median(bootstrap_sum_diffs,1);                           %Compute the median
CI95_sum_diffs = prctile(bootstrap_sum_diffs,[2.5;97.5],1);                 %Compute the 95% confidence interval

%Plot the results?
if displayBool
    if isempty(colors)
        colors = distinguishable_colors(nModels);
        %colors = distinguishable_colors(15);
        %colors = colors([12 5 6 7 9 11],:);            %--> I prefer these six model colors 
        %colormap(colors); figure; colorbar()           %--> Take a quick look at the colors
    end
    
    %Plot the results
    barWidth = 0.85;
    figure; clf; hold on; box on;
    %Plot reference model as thick line
    plot([0.5 nModels+0.5],[0 0],'-','linewidth',3,'Color',colors(1,:));
    for i=1:nModels
        %Plot CI as a bar
        xTemp = [i-barWidth/2 i-barWidth/2 i+barWidth/2 i+barWidth/2];                                  %[L L R R]
        yTemp = [CI95_sum_diffs(1,i) CI95_sum_diffs(2,i) CI95_sum_diffs(2,i) CI95_sum_diffs(1,i)];      %[B T T B]
        patch(xTemp,yTemp,1,'Parent',gca,'EdgeColor',colors(i,:),'LineStyle','-','Linewidth',1.5,'FaceColor',colors(i,:),'FaceAlpha',0.2); 

        %Add median as a colored line
        plot([i-barWidth/2 i+barWidth/2],[median_sum_diffs(i) median_sum_diffs(i)],'-','linewidth',1.5,'Color',colors(i,:));
    end
    xlim([0.5 nModels+0.5]); title('fixed effects analysis'); xlabel('model nr'); ylabel(['summed LL-LLm' num2str(refModelNr)]);
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%

function colors = distinguishable_colors(n_colors,bg,func)
% DISTINGUISHABLE_COLORS: pick colors that are maximally perceptually distinct
%
% When plotting a set of lines, you may want to distinguish them by color.
% By default, Matlab chooses a small set of colors and cycles among them,
% and so if you have more than a few lines there will be confusion about
% which line is which. To fix this problem, one would want to be able to
% pick a much larger set of distinct colors, where the number of colors
% equals or exceeds the number of lines you want to plot. Because our
% ability to distinguish among colors has limits, one should choose these
% colors to be "maximally perceptually distinguishable."
%
% This function generates a set of colors which are distinguishable
% by reference to the "Lab" color space, which more closely matches
% human color perception than RGB. Given an initial large list of possible
% colors, it iteratively chooses the entry in the list that is farthest (in
% Lab space) from all previously-chosen entries. While this "greedy"
% algorithm does not yield a global maximum, it is simple and efficient.
% Moreover, the sequence of colors is consistent no matter how many you
% request, which facilitates the users' ability to learn the color order
% and avoids major changes in the appearance of plots when adding or
% removing lines.
%
% Syntax:
%   colors = distinguishable_colors(n_colors)
% Specify the number of colors you want as a scalar, n_colors. This will
% generate an n_colors-by-3 matrix, each row representing an RGB
% color triple. If you don't precisely know how many you will need in
% advance, there is no harm (other than execution time) in specifying
% slightly more than you think you will need.
%
%   colors = distinguishable_colors(n_colors,bg)
% This syntax allows you to specify the background color, to make sure that
% your colors are also distinguishable from the background. Default value
% is white. bg may be specified as an RGB triple or as one of the standard
% "ColorSpec" strings. You can even specify multiple colors:
%     bg = {'w','k'}
% or
%     bg = [1 1 1; 0 0 0]
% will only produce colors that are distinguishable from both white and
% black.
%
%   colors = distinguishable_colors(n_colors,bg,rgb2labfunc)
% By default, distinguishable_colors uses the image processing toolbox's
% color conversion functions makecform and applycform. Alternatively, you
% can supply your own color conversion function.
%
% Example:
%   c = distinguishable_colors(25);
%   figure
%   image(reshape(c,[1 size(c)]))
%
% Example using the file exchange's 'colorspace':
%   func = @(x) colorspace('RGB->Lab',x);
%   c = distinguishable_colors(25,'w',func);

% Copyright 2010-2011 by Timothy E. Holy

  % Parse the inputs
  if (nargin < 2)
    bg = [1 1 1];  % default white background
  else
    if iscell(bg)
      % User specified a list of colors as a cell aray
      bgc = bg;
      for i = 1:length(bgc)
	bgc{i} = parsecolor(bgc{i});
      end
      bg = cat(1,bgc{:});
    else
      % User specified a numeric array of colors (n-by-3)
      bg = parsecolor(bg);
    end
  end
  
  % Generate a sizable number of RGB triples. This represents our space of
  % possible choices. By starting in RGB space, we ensure that all of the
  % colors can be generated by the monitor.
  n_grid = 30;  % number of grid divisions along each axis in RGB space
  x = linspace(0,1,n_grid);
  [R,G,B] = ndgrid(x,x,x);
  rgb = [R(:) G(:) B(:)];
  if (n_colors > size(rgb,1)/3)
    error('You can''t readily distinguish that many colors');
  end
  
  % Convert to Lab color space, which more closely represents human
  % perception
  if (nargin > 2)
    lab = func(rgb);
    bglab = func(bg);
  else
    C = makecform('srgb2lab');
    lab = applycform(rgb,C);
    bglab = applycform(bg,C);
  end

  % If the user specified multiple background colors, compute distances
  % from the candidate colors to the background colors
  mindist2 = inf(size(rgb,1),1);
  for i = 1:size(bglab,1)-1
    dX = bsxfun(@minus,lab,bglab(i,:)); % displacement all colors from bg
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
  end
  
  % Iteratively pick the color that maximizes the distance to the nearest
  % already-picked color
  colors = zeros(n_colors,3);
  lastlab = bglab(end,:);   % initialize by making the "previous" color equal to background
  for i = 1:n_colors
    dX = bsxfun(@minus,lab,lastlab); % displacement of last from all colors on list
    dist2 = sum(dX.^2,2);  % square distance
    mindist2 = min(dist2,mindist2);  % dist2 to closest previously-chosen color
    [~,index] = max(mindist2);  % find the entry farthest from all previously-chosen colors
    colors(i,:) = rgb(index,:);  % save for output
    lastlab = lab(index,:);  % prepare for next iteration
  end
end

function c = parsecolor(s)
  if ischar(s)
    c = colorstr2rgb(s);
  elseif isnumeric(s) && size(s,2) == 3
    c = s;
  else
    error('MATLAB:InvalidColorSpec','Color specification cannot be parsed.');
  end
end

function c = colorstr2rgb(c)
  % Convert a color string to an RGB value.
  % This is cribbed from Matlab's whitebg function.
  % Why don't they make this a stand-alone function?
  rgbspec = [1 0 0;0 1 0;0 0 1;1 1 1;0 1 1;1 0 1;1 1 0;0 0 0];
  cspec = 'rgbwcmyk';
  k = find(cspec==c(1));
  if isempty(k)
    error('MATLAB:InvalidColorString','Unknown color string.');
  end
  if k~=3 || length(c)==1,
    c = rgbspec(k,:);
  elseif length(c)>2,
    if strcmpi(c(1:3),'bla')
      c = [0 0 0];
    elseif strcmpi(c(1:3),'blu')
      c = [0 0 1];
    else
      error('MATLAB:UnknownColorString', 'Unknown color string.');
    end
  end
end