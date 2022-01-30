v = randi(1000,100000,1);
A = gallery('toeppen', 100000);
o = matRad_gpuSparse(A);
ret = o *v;