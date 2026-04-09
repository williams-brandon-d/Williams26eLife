function ROImask = getROImask(ROIs)

    nSelected = length(ROIs);
    
    [H,W] = size(ROIs{1});
    ROImask = false(H,W);

     for i = 1:nSelected
        ROImask = ROImask | ROIs{i};
     end

end