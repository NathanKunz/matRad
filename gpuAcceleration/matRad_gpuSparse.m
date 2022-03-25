classdef matRad_gpuSparse
    % matRad_gpuSparse
    % class for holding a gpu sparse array with single
    % precision in csc format
    % used in gpu acceleration of fluenz optimization
    %
    % this class is using a mex file containing CUDA cuSparse Code
    % for mtimes operation     
    % compile with matRad_gpuSparse.compileMex() or compileAll()
    %
    % installation of supported CUDA Toolkit and NVIDIA GPU for current matlab
    % version needed: https://de.mathworks.com/help/parallel-computing/gpu-support-by-release.html
    %
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
    
    properties
        % (1,1) makes sure it is a scalar or (:,1) a vector not sure if
        % this works in ovtave
        nrows(1,1) int32 % number of rows 
        ncols(1,1) int32 % number of columns
        nnz(1,1) int32 % number of non zero elements
        
        pr(:,1) gpuArray % value vector singe/ double
        ir(:,1) gpuArray % row vector indexing for csc format
        jc(:,1) gpuArray % coloum vector indexing 
        
        trans(1,1) % transpose flag for CUDA
        
        computationType string % switch for what type of mex file should be used (cuda kernel or cusparse or whatever gets implemented) 
    end
    
    methods
        function obj = matRad_gpuSparse(S)
            %GPUSPARSETEST Construct an instance of this class
            %   inputSpare: sparse Array which should be converted into gpu
            %   sparse
            %
            % gonna require Parallel Computing Toolbox and CUDA compiler
            % for compiling mex files
            
            %-- Some checks to validate input
            if isempty(S)
                error('Argument (S) is empty');
            elseif ~issparse(S)
                error('Argument (S) must be sparse');
            elseif ~isnumeric(S) && ~isreal(S)
                error('Argument (S) must be numeric real')
            end
            
            % TODO
            %-- check if all mex files are compiled else compile them from
            %-- check (roughly) if enough storage if available on gpu 
            
            obj.nnz = nnz(S);
            [obj.nrows, obj.ncols] = size(S);
            
            %-- Call a mex function that return the parts of the sparse
            %matrxi as gpu array and set the properties
            [pr, ir, jc] = matRad_deconstructSparse(S); % could also use matRad_deconstructSparseSingle but this works fine
            
            obj.pr = gpuArray(single(pr));
            obj.ir = gpuArray(int32(ir));
            obj.jc = gpuArray(int32(jc));
            
        end
        
        %-- Overwrite some methods for print or display, actual
        %calculations shouldnt be necessary
        
        % matrix vector product
        function ret_v = mtimes(arg1,arg2)
           if isempty(arg1) || isempty(arg2)
               error('One Input is empty');
           
           % vector * matrix
           elseif isvector(arg1) && isa(arg2, 'matRad_gpuSparse') 
               
               if ~isnumeric(arg1)
                   error('First Input (arg1) must be numeric');
               end
               
               % vector * matrix
               % arg1: numeric vector
               % arg2: gpu sparse obj
               if ~isa(arg1, 'single')
                   arg1 = single(arg1);
               end
               if ~isgpuarray(arg1)
                   arg1 = gpuArray(arg1);
               end
               % set tranpose flag to transforme the equation v * M to
               % transpose(v * M) = transpose(M) * transpose(v) 
               % still needs some work
               arg2.trans = 1; % transpose flag has to be inverted because cuSparse uses csr Format
               ret_v = matRad_cuSparse(arg2.nrows, arg2.ncols, arg2.nnz, arg2.jc, arg2.ir, arg2.pr, arg2.trans, arg1);
               ret_v = transpose(ret_v); % transpose result  
           
           % matrix * vector
           elseif isa(arg1, 'matRad_gpuSparse') && isvector(arg2)
               
               if ~isnumeric(arg2)
                   error('Second Input (arg2) must be numeric');
               end
               
               % arg1: gpu sparse obj
               % arg2: numeric vector
               if ~isa(arg2, 'single')
                   arg2 = single(arg2);
               end
               if ~isgpuarray(arg2)
                   arg2 = gpuArray(arg2);
               end
               arg1.trans = 0; % transpose flag has to be inverted because cuSparse uses csr Format
               ret_v = matRad_cuSparse(arg1.nrows, arg1.ncols, arg1.nnz, arg1.jc, arg1.ir, arg1.pr, arg1.trans, arg2);

           elseif ismatrix(arg1) && ismatrix(arg2)
               error('Matrix Matrix product not implemented');
           else
               error('Input of type %s not supported', class(v));
           end
        end
        
        function obj = transpose(obj) 
            obj.trans = xor(obj.trans, 1); % flip transpose flag
        end
        
        function obj = ctranspose(obj) 
            obj.trans = xor(obj.trans, 1); % flip transpose flag
        end
        
        % functions to can be implemented
        % s = gather(obj): to gather the gpuArray and cast it to a Matlab sparse
        % gpuArrayS = sparse(obj): cast to matlab sparse
        %
        % y = subref(obj,s): index obj
        % obj = subasgn(obj,s,b): assign value to index
        % 
        % disp(obj): print the content of sparse
        % eq(a,b): check equality
        % length(a): get length
        % sum(a, dim): get Dimension
        % max(a): get max value
        % mean(a): get mean
        % find(a): find indeces of non zero elements
        % size(a, dim): get size (optional dimension)
        % numel(a): get number of elements (either nnz or product of size)
        % full(a): convert to full matrix
        % 
        %
        % times(arg1, arg2): multiply with scalar
        % mtimes(arg1, arg2): multiple matrix x matrix
        % transpose(obj): "real" transpose not only setting flag
        % plus(a,b): cuSparse
        % minus(a,b): cuSparse
                
    end
    
    methods (Static)

        function ret = checkMex()
        end

        function compileMex()
            compileAll();
        end

    end
end

