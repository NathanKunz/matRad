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
Mex Function for Computing a sparse vector product with

compiling needs a matlab supported c/c++ compiler e.g. Microsoft Visual Studio C++ or MinGW64 and CUDA
compile with matlab: mexcuda matRad_cuSparse.cu
compile with matlab for debug: mexcuda -v -g matRad_cuSparse.cu use (https://de.mathworks.com/help/matlab/matlab_external/debugging-on-microsoft-windows-platforms.html) for DB on windows
compile from matRad_Root: mexcuda  -outdir 'gpuAcceleration/mex' 'gpuAcceleration/mex/matRad_cuSparse.cu'

run with matlab: [pr,ir,jc] = seperateSparse(sparseMatrix);
*/

// include matlabs api
#include "mex.h"
#include "gpu/mxGPUArray.h"
#include "matrix.h"

// include Cuda runtime and Cusparse
#include <cuda.h>
#include <cusparse.h>
#include <cuda_runtime_api.h>

// checks for simplifying cuda code
#define CHECK_CUDA(func)                                        \
    {                                                           \
        cudaError_t status = (func);                            \
        if (status != cudaSuccess)                              \
        {                                                       \
            mexPrintf("CUDA failed at %d line with error: %s (%d)\n", __LINE__, cudaGetErrorString(status), status); \
            mexErrMsgIdAndTxt(errId, "Critical CUSPARSE ERROR"); \
        }                                                       \
    }

#define CHECK_CUSPARSE(func)                   \
    {                                          \
        cusparseStatus_t status = (func);      \
        if (status != CUSPARSE_STATUS_SUCCESS) \
        {                                      \
            mexPrintf("CUDA failed at %d line with error: %s (%d)\n", __LINE__, cusparseGetErrorString(status), status); \
            mexErrMsgIdAndTxt(errId, "Critical CUSPARSE ERROR"); \
        }                                                       \
    }

/*
define input arguments for less confusion
*/
#define NROWS_A prhs[0]
#define NCOLS_A prhs[1]
#define NNZ_A prhs[2]
#define JC_A prhs[3] // column offset size cols + 1
#define IR_A prhs[4] // row index size nnz
#define PR_A prhs[5] // values size nnz
#define TRANS prhs[6] // transpose flag
#define X_B prhs[7] // input Vector

void mexFunction(
    int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])
{

    char const *const errId = "matRad:gpuAcceleration:cuSparse:InvalidInput";
    char const *const errMsg = "Invalid input to MEX file";

    /* 
    check input and output arguments
    */
    if (nrhs != 8) mexErrMsgIdAndTxt(errId, "Wrong number of input arguments");

    if (!mxIsScalar(NROWS_A)) mexErrMsgIdAndTxt(errId, "Argument 1 ROWS must be scalar");
    if (!mxIsScalar(NCOLS_A)) mexErrMsgIdAndTxt(errId, "Argument 2 COLS must be scalar");
    if (!mxIsScalar(NNZ_A)) mexErrMsgIdAndTxt(errId, "Argument 3 NNZ must be scalar");
    if (!mxIsScalar(TRANS)) mexErrMsgIdAndTxt(errId, "Argument 7 Transpose Flag must be scalar");

    if (!mxIsGPUArray(JC_A) && !mxGPUIsValidGPUData(JC_A)) mexErrMsgIdAndTxt(errId, "Argument 4 JC must be gpu array");
    if (!mxIsGPUArray(IR_A) && !mxGPUIsValidGPUData(IR_A)) mexErrMsgIdAndTxt(errId, "Argument 5 IR must be gpu array");
    if (!mxIsGPUArray(PR_A) && !mxGPUIsValidGPUData(PR_A)) mexErrMsgIdAndTxt(errId, "Argument 6 PR must be gpu array");
    if (!mxIsGPUArray(X_B) && !mxGPUIsValidGPUData(X_B)) mexErrMsgIdAndTxt(errId, "Argument 7 Vector B must be gpu array");

    // Initializie MathWorks Parallel Gpu API
    mxInitGPU();

    // Create read only pointer to gpu arrays
    mxGPUArray const *ir_a = mxGPUCreateFromMxArray(IR_A);
    mxGPUArray const *jc_a = mxGPUCreateFromMxArray(JC_A);
    mxGPUArray const *pr_a = mxGPUCreateFromMxArray(PR_A);

    mxGPUArray const *x = mxGPUCreateFromMxArray(X_B);

    mwSize A_n_rows = mxGetScalar(NROWS_A);
    mwSize A_n_cols = mxGetScalar(NCOLS_A);
    mwSize A_nnz = mxGetScalar(NNZ_A);

    mwSize *xdims = (mwSize*)mxGPUGetDimensions(x);

    if (mxGPUGetNumberOfDimensions(x) > 2) mexErrMsgIdAndTxt(errId, "Vector has to many dimensions");

    mwSize numelx = mxGPUGetNumberOfElements(x);
    cusparseOperation_t trans = (cusparseOperation_t)mxGetScalar(TRANS);
    //int nx = (trans == CUSPARSE_OPERATION_NON_TRANSPOSE) ? xdims[0] : xdims[1];

    // check if size allows multiplication
    //mexPrintf("vector Dimensions x:%d y:%d \n", xdims[0], xdims[1]);
    //mexPrintf("numel in vector: %d\n, number of dimensions in vector: %d\n", mxGPUGetNumberOfElements(x), mxGPUGetNumberOfDimensions(x));
    //mexPrintf("A number cols: %d number row:%d \n", A_n_cols, A_n_rows);
    if (trans == CUSPARSE_OPERATION_NON_TRANSPOSE)
    {
        if (numelx != A_n_cols)
            mexErrMsgIdAndTxt(errId, "Vector argument wrong size for multiply");
    }
    else
    {
        if (numelx != A_n_rows)
            mexErrMsgIdAndTxt(errId, "Vector argument wrong size for transpose multiply");
    }

    // check types
    if (mxGPUGetClassID(ir_a) != mxINT32_CLASS) mexErrMsgIdAndTxt(errId, "IR is not int32");
    if (mxGPUGetClassID(jc_a) != mxINT32_CLASS) mexErrMsgIdAndTxt(errId, "JC is not int32");
    if (mxGPUGetClassID(pr_a) != mxSINGLE_CLASS) mexErrMsgIdAndTxt(errId, "VAL is not single");
    if (mxGPUGetClassID(x) != mxSINGLE_CLASS) mexErrMsgIdAndTxt(errId, "Vector V is not single");

    // check complexity
    if (mxGPUGetComplexity(pr_a) != mxREAL) mexErrMsgIdAndTxt(errId, "Complex arguments are not supported");
    if (mxGPUGetComplexity(x) != mxREAL) mexErrMsgIdAndTxt(errId, "Complex arguments are not supported");


    // return vector
    const mwSize ndim = 1;
    mwSize dims[ndim] = { trans == CUSPARSE_OPERATION_NON_TRANSPOSE ? A_n_rows : A_n_cols };
    mxClassID cid = mxGPUGetClassID(x);
    mxGPUArray* y;

    y = mxGPUCreateGPUArray(ndim, dims, cid, mxREAL, MX_GPU_INITIALIZE_VALUES);
    if (y == NULL) mexErrMsgIdAndTxt(errId, "mxGPUCreateGPUArray failed");

    // CUSPARSE APIs Y=α*op(A)⋅X+β*Y
    cusparseHandle_t handle = NULL;
    cusparseStatus_t status;
    cusparseSpMatDescr_t matA;
    cusparseDnVecDescr_t vecX, vecY;
    void* d_buffer = NULL;
    size_t bufferSize = 0;

    CHECK_CUSPARSE( cusparseCreate(&handle) );

    // Convert matlab pointer to native pointer and types
    int* const d_ir_a = (int*)mxGPUGetDataReadOnly(ir_a); // data row index of a
    int* const d_jc_a = (int*)mxGPUGetDataReadOnly(jc_a); // data coloumn indexing of a
    float * const d_val = (float *)mxGPUGetDataReadOnly(pr_a); // data values of a
    float * const d_x = (float *)mxGPUGetDataReadOnly(x); // data in vector x
    float* d_y = (float *)mxGPUGetData(y); // data in (return) vector y
    float alpha = 1.0f;
    float beta = 0.0f;

    // create sparse matrix A
    CHECK_CUSPARSE( cusparseCreateCsc(&matA, A_n_rows, A_n_cols, A_nnz, d_jc_a, d_ir_a, d_val, CUSPARSE_INDEX_32I, CUSPARSE_INDEX_32I, CUSPARSE_INDEX_BASE_ZERO, CUDA_R_32F) );

    // create dense vector x
    int x_numel = (trans == CUSPARSE_OPERATION_NON_TRANSPOSE) ? A_n_cols: A_n_rows;
    CHECK_CUSPARSE( cusparseCreateDnVec(&vecX, x_numel, d_x, CUDA_R_32F) );

    // create dense output vector y
    int y_numel = (trans == CUSPARSE_OPERATION_NON_TRANSPOSE) ? A_n_rows : A_n_cols;
    CHECK_CUSPARSE(cusparseCreateDnVec(&vecY, y_numel, d_y, CUDA_R_32F));

        // create buffer if needed
    CHECK_CUSPARSE(
        cusparseSpMV_bufferSize(
            handle, trans,
            &alpha, matA, vecX, &beta, vecY, CUDA_R_32F,
            CUSPARSE_SPMV_ALG_DEFAULT, &bufferSize));

    if (bufferSize > 0)
    {
        cudaError_t status = cudaMalloc(&d_buffer, bufferSize);
        if (status != cudaSuccess)
            mexErrMsgIdAndTxt(errId, "Critical CUSPARSE ERROR");
    }

    // execute SpMV
    CHECK_CUSPARSE(cusparseSpMV(handle, trans, &alpha, matA, vecX, &beta, vecY, CUDA_R_32F, CUSPARSE_SPMV_ALG_DEFAULT, d_buffer));

    /* return result this status check has some problems and return unrecognized error codes now and then propable when no status was set beforehand or another gpu operation writes into status in between operations
    if (status == CUSPARSE_STATUS_SUCCESS)
    {
        plhs[0] = mxGPUCreateMxArrayOnGPU(y);
    }else
    {
        mexPrintf("CUDA failed at %d line with error: %s (%d)\n", __LINE__, cusparseGetErrorString(status), status);
        mexErrMsgTxt("Unkown Error in cu sparse");
    }*/

    // return data
    plhs[0] = mxGPUCreateMxArrayOnGPU(y);

    // free data
    // destroy cuda matrix/ vector descriptors and buffer
    CHECK_CUSPARSE(cusparseDestroySpMat(matA));
    CHECK_CUSPARSE(cusparseDestroyDnVec(vecX));
    CHECK_CUSPARSE(cusparseDestroyDnVec(vecY));
    CHECK_CUSPARSE(cusparseDestroy(handle));
    if (d_buffer) CHECK_CUDA(cudaFree(d_buffer));
    mxGPUDestroyGPUArray(ir_a);
    mxGPUDestroyGPUArray(pr_a);
    mxGPUDestroyGPUArray(jc_a);
    mxGPUDestroyGPUArray(x);
    mxGPUDestroyGPUArray(y);
    mxFree(xdims);

    return;
}