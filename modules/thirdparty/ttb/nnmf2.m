%{ 
coded by Takei

[explanation of this func]
Perform NNMF according to multiplicative update rule.
Also calculate values for SSE, SST, etc.

[input arguments]:
EMG_dataset:  matrix of EMG data ([mm,nn]=size(a) mm channels x nn data length)
synergy_num:  number of synergies (factors in NNMF) to extract
initial_W,initial_H: Initial values of W_matrix (spatial pattern. [mm, synergy_num] = size(W)) & H_matrix (temporal pattern. [synergy_num, nn] = size(H)) 
update_rule_type: which matrix should be updated? ('wh' or 'h'). basically 'wh' is fine
post_normalize_flag: whether to perform amplitude normalization of H_matrix after optimization of H. 'mean'or 'none'. (Default is 'none')

[explanation of output arguments]:
wbest: return the matrix of spatial pattern (after nnmf optimization)
hbest: return the matrix of temporal pattern(after nnmf optimization)
normbest: return the norm of the difference between reconstructed EMG and original EMG
%}

function[wbest,hbest,normbest] = nnmf2(EMG_dataset, synergy_num, initial_W, initial_H, num_iterations, NMF_algorithm_type, update_rule_type,pre_normalize_flag,post_normalize_flag)
% set parameters (threshold setting in MU method of nnmf)
max_iteration_num = 1000; % maximum number of multiplicative updates
dVAF_threshold    = 10^-4; %threshold of dVAF

if(nargin<3)
    initial_W      = [];
    initial_H      = [];
    num_iterations    =1;
    NMF_algorithm_type     = 'als';
    update_rule_type    = 'wh';
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
elseif(nargin<4)
    initial_H      = [];
    num_iterations    =1;
    NMF_algorithm_type     = 'als';
    update_rule_type    = 'wh';
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
elseif(nargin<5)
    num_iterations    =1;
    NMF_algorithm_type     = 'als';
    update_rule_type    = 'wh';
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
   
elseif(nargin<6)
    NMF_algorithm_type     = 'als';
    update_rule_type    = 'wh';
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
elseif(nargin<7)
    update_rule_type    = 'wh';
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
elseif(nargin<8)
    pre_normalize_flag   = 'none';
    post_normalize_flag  = 'none';
elseif(nargin<9)
    post_normalize_flag  = 'none';
end

initial_W_isempty   = isempty(initial_W); % wether the matrix is empty or not
initial_H_isempty   = isempty(initial_H);

% Check required arguments
[muscle_num,sample_num] = size(EMG_dataset); 
if ~isscalar(synergy_num) || ~isnumeric(synergy_num) || synergy_num<1 || synergy_num>min(sample_num,muscle_num) || synergy_num~=round(synergy_num) 
    error('stats:nnmf:BadK',...
        'K must be a positive integer no larger than the number of rows or columns in A.');
end

% create flag to identify differences in algorithm
if(strcmp(NMF_algorithm_type,'mult')) 
    ismult  = true;
else
    ismult  = false;
end

% Creation of pseudo-random numbers
S = RandStream.getGlobalStream; 
fprintf('repetition\titeration\tSSE\tVAF\tdVAF\tAlgorithm\n');

% pre_normalize_flag
switch pre_normalize_flag
    case 'mean'
        EMG_dataset = normalize(EMG_dataset,'mean'); 
        disp([mfilename,': pre_normalize_flag = mean']);
    case 'none'
        disp([mfilename,': pre_normalize_flag = none']);
end


for irep=1:num_iterations
    if(initial_W_isempty)
        initial_W  = rand(S,muscle_num,synergy_num); % create a random number matrix of size n(muscle num)*synergy_num
    end
    if(initial_H_isempty)
        initial_H  = rand(S,synergy_num,sample_num); % create a random number matrix of size synergy_num*sample_num(length of data)
    end
    
    % Perform a factorization
    [w1,h1,norm1,iter1,SSE1,VAF1,dVAF1] =    nnmf1(EMG_dataset,initial_W,initial_H,ismult,update_rule_type,max_iteration_num,dVAF_threshold);
    
    fprintf('%7d\t%7d\t%12g\t%12g\t%12g\t%s\t%s\n',irep,iter1,SSE1,VAF1,dVAF1,NMF_algorithm_type,update_rule_type);

    % change parameters based on which initial random number matrix was the best
    if(irep==1) 
        wbest   = w1;
        hbest   = h1;
        normbest    = norm1;
        iterbest    = iter1;
        SSEbest     = SSE1;
        VAFbest     = VAF1;
        dVAFbest    = dVAF1;
        irepbest    = irep;
    else
        if(norm1<normbest)
            wbest   = w1;
            hbest   = h1;
            normbest    = norm1;
            iterbest    = iter1;
            SSEbest     = SSE1;
            VAFbest     = VAF1;
            dVAFbest    = dVAF1;
            irepbest    = irep;
        end
    end
end

fprintf('Final result:\n');
fprintf('%7d\t%7d\t%12g\t%12g\t%12g\n',irepbest,iterbest,SSEbest,VAFbest,dVAFbest);

if normbest==Inf
    error('stats:nnmf:NoSolution',...
        'Algorithm could not converge to a finite solution.')
end

hlen = sqrt(sum(hbest.^2,2));
if any(hlen==0)
    warning('stats:nnmf:LowRank',...
        'Algorithm converged to a solution of rank %d rather than %d as specified.',...
        synergy_num-sum(hlen==0), synergy_num);
    hlen(hlen==0) = 1;
end

% amplitude normalizetion of H_matrix
switch post_normalize_flag
    case 'mean'
        A   = mean(hbest,2);
        wbest   = wbest .* repmat(A',size(wbest,1),1);
        hbest   = hbest ./ repmat(A ,1,size(hbest,2));
        disp([mfilename,': post_normalize_flag = mean']);
    case 'none'
        disp([mfilename,': post_normalize_flag = none']);
end

% Then order by w
[~,idx] = sort(sum(wbest.^2,1),'descend');
wbest = wbest(:,idx);
hbest = hbest(idx,:);

end

%% define local function

function [w,h,dnorm,iter,SSE,VAF,dVAF] = nnmf1(EMG_dataset,initial_W,initial_H,ismult,update_rule_type,max_iteration_num,dVAF_threshold)
%{ 
explanation of output arguments:
w:final version of spatial pattern after optimization 
h: final version of spatial pattern after optimization 
dnorm: norm of difference between measured EMG and reconstructed EMG => to evaluate the discrepancy
iter: how many multiplicative updates have been performed?
SSE: final version of SSE
VAF: final version of VAF
dVAF: final version of dVAF
%}

% Single non-negative matrix factorization
sqrteps = sqrt(eps); % define machine epsilon for less error in calculations
for iter=1:max_iteration_num 
    if ismult
        % Multiplicative update formula
        switch lower(update_rule_type)
            case 'wh' 
                numerator   = initial_W'*EMG_dataset; % 
                h = initial_H .* (numerator ./ ((initial_W'*initial_W)*initial_H + eps(numerator)));
                numerator   = EMG_dataset*h'; %XH^T
                w = initial_W .* (numerator ./ (initial_W*(h*h') + eps(numerator)));
            case 'h' % update only h
                numerator   = initial_W'*EMG_dataset;
                h = initial_H .* (numerator ./ ((initial_W'*initial_W)*initial_H + eps(numerator)));
                w = initial_W;
        end
    else
        % Alternating least squares
        switch lower(update_rule_type)
            case 'wh'
                h = max(0, initial_W\EMG_dataset);
                w = max(0, EMG_dataset/h);
            case 'h'
                h = max(0, initial_W\EMG_dataset);
                w = initial_W;
        end
    end
    
    
    % Get norm, SSE, SST and VAF
    b = w*h; % reconstructed EMG (created from W, H after muluticative update)
    A   = reshape(EMG_dataset,numel(EMG_dataset),1); % converts a (measured EMG) into a vector by reshape
    B   = reshape(b,numel(b),1); % converts b (reconstructed EMG) into a vector by reshape
    D   = A-B; %X-wh (difference between measured EMG and reconstructed EMG)

    dnorm   = sqrt(sum(D.^2)/length(D)); % find the norm of the difference
    SSE = sum(D.^2);    % sum of squared residuals (errors)
    SST = sum((A-mean(A)).^2);  % sum of squared total?

    dw = max(max(abs(w-initial_W) / (sqrteps+max(max(abs(initial_W))))));
    dh = max(max(abs(h-initial_H) / (sqrteps+max(max(abs(initial_H))))));
    delta = max(dw,dh);
    
    % Check for convergence
    % create an array to record VAF and dVAF(differencce from previous iteration)
    if(iter==1) 
        VAF     = nan(1,max_iteration_num);
        dVAF    = nan(1,max_iteration_num);
    end
    
    VAF(iter)  = 1 - SSE./SST;
    
    if(iter==1)
        dVAF(iter) = VAF(iter);
    else
        dVAF(iter) = VAF(iter)-VAF(iter-1);
    end

    % whether to break iteration and terminate optimization
     if iter>20
        if delta <= 1e-4
            break; 
        elseif dVAF(iter) <= dVAF_threshold
            break;
        elseif iter==max_iteration_num
            break
        end
     end

    % Remember previous iteration results
    initial_W = w;
    initial_H = h;
end
VAF = VAF(iter);
dVAF = dVAF(iter);

end

