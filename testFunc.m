function testFunc(a)
    [ir, jc, pr] = find(a);
    for k = length(ir)
        v = pr(k);
        idx =a(ir(k),jc(k));
        sprintf('%s = %s\n',v , idx);
    end
end

