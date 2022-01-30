%% Example and in matlab composed pseudo code for sparse matrix vector product

% start matrix
A = zeros(4,3);
A(1,1) = 1;
A(1,3) = 1;
A(4,1) = 2;
A(4,2) = 3;
A(3,2) = 1;

s = sparse(A);

v = [4,1,0];

%% A in compressed sparse column CSC/ CCS

% Note that one-based indices shall be used here
pr = [1,2,1,3,1]; % array of length nnz (number of non zero el) containing values. Top to bottom, left to right
ir = [1,4,3,4,1]; % array of length nnz (number of non zero el) containing  row indeces
% array of length n+1 (n: number of columns) 
% encodes the index of the value in in pr and the row index, 
% where each coloumn starts. 
% Also represents the sum of all nnz elements in this and all previous
% columns
jc = [1,3,5,6]; 

res_v = zeros(1,4); % result vector filled with zeros
h_v = pr(:); % helper vecotr

n_columns = size(A,2); 
for i = 1:(n_columns)
    idx_begin = jc(i);
    idx_end = jc(i+1);
    for j = idx_begin:(idx_end-1)
        h_v(j) = pr(j) * v(i);
        res_v(ir(j)) = res_v(ir(j))+ pr(j) * v(i);
    end
end

res_check = A*transpose(v);
disp(res_check);
disp(res_v);


