function y = transform2perJND(x,a,b,direction)
% Transform input "x" to output "y" in two directions:
% - 'real2trans': transforms "x" to units of 1/JND, with JND = a+b.*x
% - 'trans2real': transforms "x" back to original units
%
% Based on the suggestion on page 173 of: 
% Reijniers, Vanderelst, Jin, Carlile & Peremans,
% An ideal-observer model of human sound localization,
% Biol Cybern (2014) 108:169–181. DOI 10.1007/s00422-014-0588-4

%Defaults
if nargin < 2 || isempty(a)
    a = 0;
end
if nargin < 3 || isempty(b)
    b = 1;
end
if nargin < 4
    direction = 'real2trans';
end

%Quick checks
assert(all(a > 0,'all'), 'All "a" must be larger than zero');
assert(all(abs(b) > 0,'all'), 'All "b" must be different from zero');
assert(all(a+b.*x > 0,'all'), 'All "JND = a+b.*x" must be larger than zero');

%Transform x to 1/JND units such that JND is constant in transformed units    
if strcmp(direction,'real2trans')
    
    JND = a+b.*x;  
    y = (log(JND)-log(a))./b;
    
%Transform back to original units   
elseif strcmp(direction,'trans2real')
    
    JND = a.*exp(x.*b);
    y = (JND-a)./b;

%Error    
else 
    error('Unknown direction of transformation');
end

end %[EoF]
