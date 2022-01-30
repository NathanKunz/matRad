% run test function to do sparse
% vector product with different sizes for all modalitys photon,
% carbon, and 3 different sizes for number of beamlets and graph it

% and cases for:
%   gpuArray before after 
%   mex files:
%       - use build in spasrse library and convert to float
%       - use cusparse or eigen library and convert to float
%       - write a kernel inside the mex file
%   custom kernel that gets directly called from matlab 



nBeams = 3;
radiationMode = "photon";
callMode = 1;

