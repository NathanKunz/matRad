/*
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2019 the matRad development team.
%
% This file is part of the matRad project. It is subject to the license
% terms in the LICENSE file found in the top-level directory of this
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part
% of the matRad project, including this file, may be copied, modified,
% propagated, or distributed except according to the terms contained in the
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*/

/*
Function for seperating the three component arrays of a sparse matrix into 3 sperate vector arrays
helper function for the gpuSparse class

compiling needs a matlab supported c/c++ compiler e.g. Microsoft Visual Studio C++ or MinGW64
compile with matlab: mex -R2018a matRad_deconstructSparseSingle.cpp
compile with matlab for debug: mex -R2018a -v -g matRad_deconstructSparseSingle.cpp use (https://de.mathworks.com/help/matlab/matlab_external/debugging-on-microsoft-windows-platforms.html) for DB on windows
compile from matRad_Root: mex -R2018a -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_deconstructSparseSingle.cpp'

run with matlab: [pr,ir,jc] = seperateSparse(sparseMatrix);
*/

#include "mex.h"
#include "matrix.h"
#include <cstring>
#include "gpu/mxGPUArray.h"

void mexFunction(
    int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])
{

    mwIndex *ir, *jc; // ir: row indec, jc: encode row index and values in pr per coloumn
    mwSize col;       // itterator index
    mwSize total = 0; // itterater helper for value indexing
    mwIndex starting_row_index, stopping_row_index, current_row_index;
    mwSize n; // number of cols inside sparse matrix
    mwSize nnz;  // number of non zero elements in sparse matrix
    double *pr;

    // check input
    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseInternalOutput:invalidNumInputs",
                          "One input argument required.");
    }

    if (nlhs != 3)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseInternalOutput:invalidNumOutputs",
                          "Wrong number of output arguments.");
    }

    if (!mxIsSparse(prhs[0]))
    {
        mexErrMsgIdAndTxt("MATLAB:sparseInternalOutput:invalidInputType",
                          "First argument must be sparse.");
    }

    // Get the starting pointer of all three data arrays.
    pr = mxGetPr(prhs[0]);     // value array
    ir = mxGetIr(prhs[0]);     // row index array
    jc = mxGetJc(prhs[0]);     // column encrypt array
    n = mxGetN(prhs[0]);       // number of columnss
    const mwSize dims[] = {nnz,1};
    // nnz = mxGetNzmax(prhs[0]); // number of possible non zero elements
    nnz = jc[n]; // number of non zero elements currently stored inside the sparse matrix

    //plhs[0] = mxCreateNumericMatrix(nnz, 1, mxSINGLE_CLASS, mxREAL);  // output pr vector
    plhs[1] = mxCreateNumericMatrix(nnz, 1, mxINT64_CLASS, mxREAL);   // output ir vector
    plhs[2] = mxCreateNumericMatrix(n + 1, 1, mxINT64_CLASS, mxREAL); // output jc vector

    //mxGPUArray* gpu_arr = mxGPUCreateGPUArray(2, dims, mxSINGLE_CLASS, mxREAL, MX_GPU_DO_NOT_INITIALIZE);

    // set values to output vectors
    
    double *new_ir = mxGetPr(plhs[1]); // had to use memcpy beause mxRealloc don't change the address, and Matlab doesn't like two elements pointing to the same address
    std::memcpy(new_ir, ir, nnz * sizeof(mwIndex));

    double *new_jc = mxGetPr(plhs[2]); // had to use memcpy beause mxRealloc don't change the address, and Matlab doesn't like two elements pointing to the same address
    std::memcpy(new_jc, jc, (n + 1) * sizeof(mwIndex));
    // no need to free memory because matlab should handle memory management of return values

    // convert pr vector to single and move it on the gpu
    mxArray *pr_arr = mxCreateNumericMatrix(nnz, 1, mxSINGLE_CLASS, mxREAL);
    float *new_pr = mxGetSingles(pr_arr);

    // convert double to single array
    for (int i = 0; i < nnz; i++)
    {
        new_pr[i] = (float)pr[i];
    }

    mxGPUArray *gpu_pr = mxGPUCopyFromMxArray(pr_arr);
    plhs[0] = mxGPUCreateMxArrayOnCPU(gpu_pr);

    // clear gpu array
    mxGPUDestroyGPUArray(gpu_pr);

}
