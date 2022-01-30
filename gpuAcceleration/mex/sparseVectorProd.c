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
compile with matlab: mex -largeArrayDims sparseVectorProd.c
run with matlab: resultVector = sparseVectorProd(sparse, vector)
*/

#include "mex.h"
#include <math.h>
#include "matrix.h"

void mexFunction(
    int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])
{
    // check inputs
    if (nrhs != 2)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidNumInputs",
                          "Two input argument required.");
    }

    if (nlhs > 1)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidNumOutputs",
                          "Too many output arguments.");
    }

    if (!mxIsSparse(prhs[0]))
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidInputType",
                          "First argument must be sparse.");
    }

    if (!mxIsNumeric(prhs[1]))
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidInputType",
                          "Second argument must be vector.");
    }

    if (mxIsComplex(prhs[0]) || mxIsComplex(prhs[1]))
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidInputType",
                          "Complex data is not supported");
    }


    // allocate vars
    mwIndex *ir, *jc; // ir: row indec, jc = encode row index and values in pr per coloumn
    mwSize col;       // iterator for columns
    mwSize total = 0; // itterater helper for value indexing
    mwIndex starting_row_index, stopping_row_index, current_row_index;
    mwSize n;   // number of columns inside sparse matrix
    mwSize m; // number of rows inside sparse matrix
    int nnz;    // number of non zero elements in sparse matrix
    double *pr; // pointer to the value array
    double *val;
    double *v; // input vector values
    int ne_vector; // number of elements inside vector

    // Get the starting pointer of all three data arrays.
    pr = mxGetPr(prhs[0]); 
    ir = mxGetIr(prhs[0]); 
    jc = mxGetJc(prhs[0]);
    nnz = mxGetNzmax(prhs[0]);
    n = mxGetN(prhs[0]);
    m = mxGetM(prhs[0]);
    v = mxGetPr(prhs[1]);
    ne_vector = mxGetNumberOfElements(prhs[1]);
    
    // check if Matrix vector product is possible for this specific computation res_v = (v' * s)'
    if (ne_vector != m)
    {
        mexErrMsgIdAndTxt("MATLAB:sparseVectorProd:invalidInputSize",
                        "Sparse matrix number of columns and elements in vector need to be same.");
    }

    plhs[0] = mxCreateDoubleMatrix(n, 1, mxREAL); // output vector
    val = mxGetPr(plhs[0]); // values from output vector
    
    for (col = 0; col < n; col ++)
    {
        int begin = jc[col];
        int end = jc[col+1];

        val[col] = 0;
        //mexPrintf("col: %d Begin: %d End: %d\n", col, begin, end);
        for (int j = begin; j < end; j++)
        {
            //val[ir[j]] += pr[j] * v[col];
            val[col] += pr[j] * v[ir[j]];
        }
        
    }
    
}
