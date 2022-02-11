function [M, S, T] = timeFunc(f, n, description, filename)
%timeFunc calls the given Function n times 
% Inputs:
%   f: Function to be measured, specified as a function handle. f is either a handle to a function that takes no input, or a handle to an anonymous function with an empty argument list.
%   n: number of repitions
%   description: optional string to show console output, if non given no
%   output 
%
% Outputs:
%   M: mean runtime
%   S: standard deviation of runtime
%   T: runtime vector

gpudev = gpuDevice;

if ~exist('n', 'Var')
    n = 1;
end
    
T = zeros(1,n);
for i=1:n
    tic;
    f();
    wait(gpudev)
    T(i) = toc;
end

M = mean(T);
S = std(T);

if nargin > 2
    if description
        
        fileID = 1;
        if nargin > 3
            fileID = fopen(filename, 'w');
        end
        
        fprintf(fileID, '\nTest: %s | %s \n------------------------------------------------------\nSignature: %s\n\nNumber of runs: %d\nAverage run time: %.8f\nStandard deviation: %.8f\nShortest time: %.8f\nLongest time: %.8f\n------------------------------------------------------\n',description, datetime, functions(f).function, n, M, S, min(T), max(T));
        
        if nargin > 3
            fclose(fileID);
        end
    
     end
end

