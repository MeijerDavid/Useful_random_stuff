function [grid,prob_distrs] = equalGridProbDistr(grids,prob_distrs)
%Form one common grid for multiple probability distributions with different
%grids. This function bins probabilities on the new joint grid. 

assert(isequal(size(grids),size(prob_distrs)),'Inputs matrices "grids" and "prob_distrs" must have equal sizes');
[num_grid,num_distrs] = size(grids);

MIN = min(grids,[],'all');
MAX = max(grids,[],'all');
grid = linspace(MIN,MAX,num_grid)';

%Interpolate using 'numIntegrAndInterp' and then normalize to probabilities
for i=1:num_distrs
    prob_distrs(:,i) = numIntegrAndInterp(grids(:,i),prob_distrs(:,i),grid);
    prob_distrs(:,i) = prob_distrs(:,i)./sum(prob_distrs(:,i),1);
end

end %[EoF]
