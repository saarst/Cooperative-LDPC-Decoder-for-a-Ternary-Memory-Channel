function SavePartiyMat(filename,d)
[hInds,gInds] = LDPCWrapper('GetParityMatrix',filename);
G = sparse(double(gInds(:,1)),double(gInds(:,2)),ones(size(gInds,1),1));
H = [G,eye(size(G,1))];
Hnonsys = sparse(double(hInds(:,1)),double(hInds(:,2)),ones(size(hInds,1),1));
save(filename,'H','Hnonsys','d')