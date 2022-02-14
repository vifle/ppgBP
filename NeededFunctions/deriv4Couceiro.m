function d=deriv4Couceiro(f)
% Fourth derivative of vector using 5-point central difference.
% h = 1
n=length(f);
d=zeros(size(f));
for t = 3:n-2
    d(t) = f(t-2) - 4*f(t-1) + 6*f(t) - 4*f(t+1) + f(t+2);
end
d(1) = d(3);
d(2) = d(3);
d(n) = d(n-2);
d(n-1) = d(n-2);
end