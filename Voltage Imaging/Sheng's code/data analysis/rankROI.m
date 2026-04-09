function ROIs = rankROI(ROIs)

x_cord = zeros(1,numel(ROIs));

for i = 1:numel(ROIs)
    mask = ROIs{i};
    mask = sum(mask, 1);
    x_cord(i) = find(mask>0, 1);
end

[~, I] = sort(x_cord);

ROIs = ROIs(I);

end