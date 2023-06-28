function Vq = interp2NormalWeighted(X,Y,V,Xq,Yq,SIGMA)

num_points = numel(Xq);
Vq = nan(num_points,1);

for i=1:num_points
    
    weights = mvnpdf([Xq(i) Yq(i)],[X(:),Y(:)],SIGMA);
    weights(isnan(V),:) = NaN;                      %Ensure proper normalization 
    weights = weights./nansum(weights,1);           %normalize over first dimension
    Vq(i) = nansum(weights.*V(:),1);                %compute weighted average
    
end

Vq = reshape(Vq,size(Xq));
Vq(isnan(Xq) | isnan(Yq)) = NaN;                    %Correct zero to NaN (nansum(NaN)-->0)

end %[EoF]



