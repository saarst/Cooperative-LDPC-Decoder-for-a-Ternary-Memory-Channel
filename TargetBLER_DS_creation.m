function targetBLER_DS = TargetBLER_DS_creation

    targetBLER_DS = struct;
    generalP = logspace(-4,-5,10)';
    sz = [length(generalP) 5];
    varTypes = {'double','double','double','double','double'};
    varNames = {'p','q_l','BLER_at_q_l','q_h','BLER_at_q_h'};
    T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    
    T{:,"p"} = generalP;
    T{:,"q_l"} = 1E-4;
    T{:,"q_h"} = 1E-3;
    
    targetBLER_DS.joint = T;
    targetBLER_DS.prior = T;

end