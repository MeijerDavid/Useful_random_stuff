function [grid,prob_distrs] = equalGridProbDistr(grids,prob_distrs)
%Form one common grid for multiple probability distributions with different
%grids. This function interpolates probabilities on the new joint grid. 

assert(isequal(size(grids),size(prob_distrs)),'Inputs matrices "grids" and "prob_distrs" must have equal sizes');
[num_grid,num_distrs] = size(grids);

MIN = nanmin(grids,[],'all');
MAX = nanmax(grids,[],'all');
grid = linspace(MIN,MAX,num_grid)';

%Interpolate using 'lininterp1' and then normalize to probabilities
for i=1:num_distrs
    prob_distrs(:,i) = lininterp1(grids(:,i),prob_distrs(:,i),grid,0);
    prob_distrs(:,i) = prob_distrs(:,i)./sum(prob_distrs(:,i),1);
end

end %[EoF]
