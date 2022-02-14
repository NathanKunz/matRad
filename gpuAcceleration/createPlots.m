T = readtable('D:\PraxissemesterDkfz\matRad\gpuAcceleration\output\gpuResultData_paper.xlsx');
none_idx = find(contains(cell(T.GpuAcceleration), 'none'));
gpuArray_idx = find(contains(cell(T.GpuAcceleration), 'gpuArray'));
gpuSparse_idx = find(contains(cell(T.GpuAcceleration), 'gpuMexCuSparse'));
%%
x_var = 'VerhaeltnisNNZ';
y_var = 'Gesamtzeit_s_';
%x = unique(T.VerhaeltnisNNZ);

xnone = sort(T(none_idx, x_var).(x_var));
ynone = sort(T(none_idx, y_var).(y_var));
xgpuArray = sort(T(gpuArray_idx, x_var).(x_var));
ygpuArray = sort(T(gpuArray_idx, y_var).(y_var));
xgpuSparse= sort(T(gpuSparse_idx, x_var).(x_var));
ygpuSparse = sort(T(gpuSparse_idx, y_var).(y_var));

figure
plot(xnone,ynone,xgpuArray,ygpuArray,xgpuSparse,ygpuSparse);
legend('CPU', 'GPU Array', 'cuSparse');
xlabel('sparsity physicalDose');
ylabel('Gesamtlaufzeit [s]');
ax = gca;
exportgraphics(ax, '.\gpuAcceleration\output\time-sparsity-plot.pdf');

%%
x_var = 'x_NNZ_1e6_';
y_var = 'Gesamtzeit_s_';
%x = unique(T.VerhaeltnisNNZ);

xnone = sort(T(none_idx, x_var).(x_var));
ynone = sort(T(none_idx, y_var).(y_var));
xgpuArray = sort(T(gpuArray_idx, x_var).(x_var));
ygpuArray = sort(T(gpuArray_idx, y_var).(y_var));
xgpuSparse= sort(T(gpuSparse_idx, x_var).(x_var));
ygpuSparse = sort(T(gpuSparse_idx, y_var).(y_var));

figure
plot(xnone,ynone,xgpuArray,ygpuArray,xgpuSparse,ygpuSparse);
legend('CPU', 'GPU Array', 'cuSparse');
xlabel('NNZ physicalDose [1e16]');
ylabel('Gesamtlaufzeit [s]');
ax = gca;
exportgraphics(ax, '.\gpuAcceleration\output\time-nnz-plot.pdf');

%%
x_var = 'Groe_ePhysicalDose_GB_';
y_var = 'Gesamtzeit_s_';
%x = unique(T.VerhaeltnisNNZ);

xnone = sort(T(none_idx, x_var).(x_var));
ynone = sort(T(none_idx, y_var).(y_var));
xgpuArray = sort(T(gpuArray_idx, x_var).(x_var));
ygpuArray = sort(T(gpuArray_idx, y_var).(y_var));
xgpuSparse= sort(T(gpuSparse_idx, x_var).(x_var));
ygpuSparse = sort(T(gpuSparse_idx, y_var).(y_var));

figure
plot(xnone,ynone,xgpuArray,ygpuArray,xgpuSparse,ygpuSparse);
legend('CPU', 'GPU Array', 'cuSparse');
xlabel('Groesse physicalDose [GB]');
ylabel('Gesamtlaufzeit [s]');
ax = gca;
exportgraphics(ax, '.\gpuAcceleration\output\time-groese-plot.pdf');

%%
x_var = 'Groe_ePhysicalDose_GB_';
y_var = 'MaximaleGPUAuslastung___';
%x = unique(T.VerhaeltnisNNZ);

xnone = sort(T(none_idx, x_var).(x_var));
ynone = sort(T(none_idx, y_var).(y_var));
xgpuArray = sort(T(gpuArray_idx, x_var).(x_var));
ygpuArray = sort(T(gpuArray_idx, y_var).(y_var));
xgpuSparse= sort(T(gpuSparse_idx, x_var).(x_var));
ygpuSparse = sort(T(gpuSparse_idx, y_var).(y_var));

figure
plot(xnone,ynone,xgpuArray,ygpuArray,xgpuSparse,ygpuSparse);
legend('CPU', 'GPU Array', 'cuSparse');
xlabel('Groesse physicalDose [GB]');
ylabel('Max GPU Auslastung [%]');
ax = gca;
exportgraphics(ax, '.\gpuAcceleration\output\gpuAuslastung-groese-plot.pdf');

