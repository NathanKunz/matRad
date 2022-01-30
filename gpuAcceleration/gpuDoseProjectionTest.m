% Test script for gpu performance comparison with a transpose operation and
% vector matrix product of a random generated pseudo dose gradient vector
% and the dij.physicalDose sparse Matrix

load('example1_engine.mat');
cpuDoseGrad = randn(dij.doseGrid.numOfVoxels, 1);
gpuDoseGrad = gpuArray(cpuDoseGrad);

cpuPhysicalDose = dij.physicalDose{1};
gpuPhysicalDose = gpuArray(dij.physicalDose{1});
transposedGpu =  gpuArray(dij.physicalDose{1}');


scen = 1;
% wGrad = (cpuDoseGrad{scen}' * dij.physicalDose{scen})';
%f = @(doseGrad, pd) pd' * doseGrad;
f = @(doseGrad, pd) (doseGrad' * pd)';
f1 = @(doseGrad, transposed) transposed * doseGrad;
% Transpose on cpu
t1 = timeFunc(@() transpose(cpuDoseGrad), 1000, 'Transpose on cpu');
% Transpose on gpu
t2 = timeFunc(@() transpose(gpuDoseGrad), 1000, 'Transpose on gpu');
% dose projection on cpu
t3 = timeFunc(@() f(cpuDoseGrad, cpuPhysicalDose), 100, 'Projection on cpu');
% dose projection on gpu
t4 = timeFunc(@() f(gpuDoseGrad, gpuPhysicalDose), 100, 'Projection on gpu');

t5 = timeFunc(@() f1(gpuDoseGrad, transposedGpu), 100, 'Transposed Projection on gpu');