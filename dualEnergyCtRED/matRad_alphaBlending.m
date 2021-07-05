function ret = matRad_alphaBlending(a,ul,uh)
%Summary alphaBlending
    ret =(a*(uh/1000 + 1))+(1-a)*(ul/1000 + 1);
end


