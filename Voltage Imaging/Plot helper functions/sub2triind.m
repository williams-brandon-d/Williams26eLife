function ind = sub2triind(siz,i,j)
%SUB2TRIIND Convert matrix subscripts to triangular indices
%   This function is for use with pdist which calculates distances between
%   pairs of points in an m-by-n matrix.  Results are returned as a row
%   vector in order
%       (2,1), (3,1), ..., (m,1), (3,2), ..., (m,2), ..., (m,m–1))
%   sub2triind takes the size of the input matrix to pdist and arrays
%   of column and row subscripts of the distances returned.  The result is an array of the
%   same dimensions of the subscripts containing the indices.
%   Where corresponding row and column subscripts are equal or
%   outside the range [1..siz(1)] the returned index will be 0.  This
%   function is the inverse of triind2sub
%
%   See also PDIST, SQUAREFORM, TRIIND2SUB.

% Copyright 2017 James Ashton

n = siz(1); % number of columns given to pdist
col = max(i, j);
row = min(i, j);
ind = col - n + row * n - row .* (row + 1) ./ 2;
ind(col == row | col > n | row < 1) = 0;
end