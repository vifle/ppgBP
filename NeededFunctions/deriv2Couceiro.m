function d=deriv2Couceiro(f)
% Second derivative of vector using 5-point central difference.
% h = 1
n=length(f);
d=zeros(size(f));
for t = 3:n-2
    d(t) = (-f(t-2) + 16*f(t-1) - 30*f(t) + 16*f(t+1) - f(t+2))/12;
end
d(1) = d(3);
d(2) = d(3);
d(n) = d(n-2);
d(n-1) = d(n-2);
end