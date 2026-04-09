function [pVal, hypo] = plotPvalue(testTarget)

cmap = colormap("gray");
cmap(end,:) = [0 1 0];
pVal = [];
hypo = [];
for i = 1:size(testTarget, 1)
    for j = 1:size(testTarget, 1)
        [p,h] = signrank(testTarget(i,:),testTarget(j,:));
        pVal(i,j) = p; hypo(i,j) = h;
    end
end
imagesc(pVal,[0 0.05]);axis image;colormap(cmap);

end