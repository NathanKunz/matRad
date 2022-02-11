function ret = floatEqual(float_a,float_b, factor)
%FLOATEQUAL Not perfect but funtional function for comparing floats for
%equality
    
    if ~exist('factor', 'var')
        factor = 32;
    end
    
    ret = all(abs(float_a - float_b) < factor * max(abs(float_a), abs(float_b)));
    
end

