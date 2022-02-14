function d=deriv3Couceiro(f)
% Third derivative of vector using 4-point central difference.
% h = 1
n=length(f);
d=zeros(size(f));
for t = 3:n-2
    d(t) = (-f(t-2) + 2*f(t-1) - 2*f(t+1) + f(t+2))/2;
end
d(1) = d(3);
d(2) = d(3);
d(n) = d(n-2);
d(n-1) = d(n-2);
end