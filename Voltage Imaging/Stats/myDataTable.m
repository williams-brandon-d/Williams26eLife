function data_table = myDataTable(data_all,cell_types)
nCells = numel(cell_types);

% construct data array with NaNs
maxNumEl = max(cellfun(@numel,data_all(:)));
data_all_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_all(:)); % Pad each vector with NaN values to equate lengths
data_all_mat = cell2mat(data_all_pad'); 

% build data table
data_table = table;
for i = 1:nCells
    switch cell_types{i}
        case {'stellate','Stellate'}
            name = 'Stellate';
        case {'pyramidal','Pyramidal'}
            name = 'Pyramidal';
        case {'fast spiking','FastSpiking'}
            name = 'FastSpiking';
        otherwise
            name = cell_types{i};
    end
    data_table.(name) = data_all_mat(:,i);
end

end