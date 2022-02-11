% Test script for gpu performance improvement with vector product of a random
% vector and the dij.physicalDose sparse matrix


if ~exist('dij', 'var')
    load('example1_engine.mat', 'dij');
end

pD = dij.physicalDose{1};
gpupD = gpuArray(dij.physicalDose{1});
randV = randn(dij.totalNumOfBixels, 1);
gpurandV = gpuArray(randV);
f = @(spareM, v) spareM * v;
% f(dij.physicalDose{1}, randV)
% res = f(gpupD, gpurandV);
t1 = timeFunc(@() f(dij.physicalDose{1}, randV), 1, 1); % time for cpu
t2 = timeFunc(@() f(gpupD, gpurandV), 1, 1); % time for both already on gpu
t3 = timeFunc(@() f(gpuArray(dij.physicalDose{1}), randV), 1, 1); % time for copy spare matrix to gpu 
t4 = timeFunc(@() f(dij.physicalDose{1}, gpuArray(randV)), 1, 1);
t5 = timeFunc(@() f(gpuArray(dij.physicalDose{1}), gpuArray(randV)), 1, 1); % time for copy both on gpu


fprintf("Time for cpu computation: %f\n", t1);
fprintf("Time for gpu computation with both already on the gpu: %f\n", t2);
fprintf("Time for gpu computation including copying the sparse matrix to gpu: %f\n", t3);
fprintf("Time for gpu computation including copying the vector to gpu: %f\n", t4);
fprintf("Time for cpu computation including copying both matrix and vector to gpu: %f\n", t5);
