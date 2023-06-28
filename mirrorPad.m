function y = mirrorPad(x,n)
% Mirror (reflection) pad a signal (vector) x, with n samples on both sides
%
% Smith, G. (1989). Padding point extrapolation techniques for the 
% butterworth digital filter. Journal of Biomechanics, 22(8-9), 967–971. 
% doi:10.1016/0021-9290(89)90082-1 

assert(~isempty(x));                   %x should not be empty
assert((rem(n,1) == 0) && (n >= 0));   %n should be a positive integer or 0    

%Make column vector
column_flag_orig = iscolumn(x);
x = x(:);

nx = numel(x);

%Catch special cases
if n == 0
    y = x;                      %no padding
elseif nx == 1
    y = ones(2*n+1,1)*x;        %replication padding
else
    if nx > n  
        %Mirror pad until n using a part of signal x (normal case)   
        pad1 = x(1)-flipud(cumsum(diff(x(1:(n+1)))));
        pad2 = x(end)+cumsum(flipud(diff(x((nx-n):nx))));
    else    
        %Repeated mirror padding of signal x until n has been reached
        n_rep = ceil(n/(2*nx-2));
        
        %first, create too many samples
        d = diff(x);
        pad1 = x(1)-flipud(cumsum(repmat([d; flipud(d)],[n_rep 1])));
        pad2 = x(end)+cumsum(repmat([flipud(d); d],[n_rep 1]));
        
        %then, remove the excess
        n_pad = numel(pad1);
        pad1 = pad1((n_pad-n+1):n_pad);
        pad2 = pad2(1:n);
    end
    y = [pad1; x; pad2];
    
%     %plot to check
%     grid = 1:numel(y);
%     grid_orig = grid(n+(1:nx));
%     plot(grid,y,'bo-'); hold on; plot(grid_orig,y(n+(1:nx)),'ro--');
end

%Reshape back to row vector
if ~column_flag_orig
    y = y'; 
end

end %[EoF]
