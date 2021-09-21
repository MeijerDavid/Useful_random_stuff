function replicated_and_shuffled = replicateAndShuffle(values,nNeeded)
%ReplicateAndShuffle creates a row vector of length 'nNeeded' with the values given by 'values' in randomized order. 
%If 'values' is a matrix, then each row is randomized in exactly the same way (such that whole columns are shuffled), and 'nNeeded' is the number of columns to which the matrix is replicated.        
%Care is taken such that all the 'values' have equal number of appearances (or at most once more than others) after replication.

[~, nColumns] = size(values);
shuffled_values = values(:,randperm(nColumns));                                              %shuffle the columns
replicated_values_tooMany = repmat(shuffled_values,1,ceil(nNeeded/nColumns));                %replicate enough (or too many) of the shuffled columns
replicated_values = replicated_values_tooMany(:,1:nNeeded);                                  %make sure there are not too many anymore
replicated_and_shuffled = replicated_values(:,randperm(nNeeded));                            %shuffle the columns once again

end