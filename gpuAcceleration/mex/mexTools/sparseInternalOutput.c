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
compile with matlab: mex -largeArrayDims sparseInternalOutput.c
run with matlab: sparseInternalOutput(sparseArray);
*/

#include "mex.h"
#include <math.h>

void mexFunction(
    int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])
{

    mwIndex *ir, *jc; // ir: row indec, jc = encode row index and values in pr per coloumn
    mwSize col;       // num of coloumns in sparse matrix
    mwSize total = 0; // itterater helper for value indexing
    mwIndex starting_row_index, stopping_row_index, current_row_index;
    mwSize n; // number of rows inside sparse matrix
    int nnz;  // number of non zero elements in sparse matrix
    double *pr;

    // check input
    if (nrhs != 1)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseInternalOutput:invalidNumInputs",
                          "One input argument required.");
    }

    if (nlhs != 0)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseInternalOutput:invalidNumOutputs",
                        "Too many output arguments.");
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
    nnz = mxGetNzmax(prhs[0]); // number of non zero elements
    n = mxGetN(prhs[0]);       // number of columns

    // for refrence print out all 3 arrays before "calculationg" the nnz values
    for (int i = 0; i < nnz; i++)
    {
        mexPrintf("Value: pr[%d] = %g\n", i, pr[i]);
    }

    for (int i = 0; i < nnz; i++)
    {
        mexPrintf("Row index: ir[%d] = %d\n", i, ir[i]);
    }
    for (int i = 0; i < n + 1; i++)
    {
        mexPrintf("Coloumn encoding: jc[%d] = %d\n", i, jc[i]);
    }

    // Display the nonzero elements of the sparse array in tuple, value format.
    for (col = 0; col < n; col++)
    {
        starting_row_index = jc[col];
        stopping_row_index = jc[col + 1];
        if (starting_row_index == stopping_row_index)
            continue;
        else
        {
            for (current_row_index = starting_row_index;
                 current_row_index < stopping_row_index;
                 current_row_index++)
            {
                mexPrintf("\t(%" FMT_SIZE_T "u,%" FMT_SIZE_T "u) = %g, %d\n",
                          ir[current_row_index] + 1,
                          col + 1, pr[total]);
                total++;
            }
        }
    }
}
