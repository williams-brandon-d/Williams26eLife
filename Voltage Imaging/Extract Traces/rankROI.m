function ROIs = rankROI(ROIs)

x_cord = zeros(1,numel(ROIs));
deleteIndex = false(1,numel(ROIs));

for i = 1:numel(ROIs)
    mask = ROIs{i};
    mask = sum(mask, 1);
    if any(mask) % not empty
        x_cord(i) = find(mask>0, 1);
    else % empty
        deleteIndex(i) = 1; 
    end
end

ROIs(deleteIndex) = []; % delete empty ROIs
x_cord(deleteIndex) = [];

[~, I] = sort(x_cord);

ROIs = ROIs(I);

end