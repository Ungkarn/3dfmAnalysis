function v = stderr(X, flag, dim)

if nargin < 3 || isempty(dim)
    dim = 1;
end

if nargin < 2 || isempty(flag)
    flag = [];
    dim = 1;
end

    v = std(X, flag, dim) ./ sqrt(size(X,dim));

return;
