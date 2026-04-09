function neuron = getNeuron(ROIs,stack)
% create neuron struct from ROIs and stack
N = length(ROIs);
traces = zeros(size(stack, 3), N);
stack2 = reshape(stack,[],size(stack,3));
neuron = cell(N,1);
SE = strel("disk",5);
invert = 1; % true for voltron

for i = 1:N
    traces(:,i) = mean(stack2(ROIs{i},:),1);
    neuron{i}.raw_trace = traces(:, i).*((-1)^(invert));
    neuron{i}.edges = edge(ROIs{i});
    neuron{i}.mask = ROIs{i};

    surround = logical(imdilate(ROIs{i},SE) - ROIs{i});
    neuron{i}.meanBk = mean(stack2(surround(:),:),'all');
end


end