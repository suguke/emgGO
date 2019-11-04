function tau =  autoApplyActivations(singleChannel, fs, activationKernel, randomInit, initialTau,...
    lowerBound, upperBound)
%autoApplyActivations Minimises baseline energy for a given
%   activationKernel on a single channel of emg data.
%
%
%   Copyright (c) <2019> <Usman Rashid>
%   Licensed under the MIT License. See LICENSE in the project root for
%   license information.



if ~(exist("particleswarm", 'file') && exist("optimoptions", 'file') && exist("fmincon", 'file'))
    tau =  autoApplyActivationsNoTB(singleChannel, fs, activationKernel, randomInit, initialTau,...
    lowerBound, upperBound);
    warning(sprintf('MATLAB optimisation functions were not found.\nA third party optimisation toolbox was used.\nResults may be better or worse as full testing has not been conducted.\nInstalling Global Optimisation Toolbox and Optimisation Toolbox may solve the problem.'));
    return;
end

% Defaults
PARAM_MULTIPLIER    = 3;


totalParams         = length(initialTau);
f                   = @(tau)costFunc(singleChannel, fs, activationKernel, tau);
lb                  = lowerBound;
ub                  = upperBound;
swarmMatrix         = initialTau;


hybridopts = optimoptions('fmincon',...
    'Algorithm', 'interior-point',...
    'FunctionTolerance', 1e-6);


if randomInit
    optimOptions = optimoptions('particleswarm',...
        'SwarmSize', PARAM_MULTIPLIER*totalParams,...
        'UseParallel', false,...
        'ObjectiveLimit', 0,...
        'Display', 'iter',...
        'FunctionTolerance', 1e-3,...
        'HybridFcn', {@fmincon, hybridopts});
else
    optimOptions = optimoptions('particleswarm',...
        'SwarmSize', PARAM_MULTIPLIER*totalParams,...
        'UseParallel', false,...
        'InitialSwarmMatrix', swarmMatrix,...
        'ObjectiveLimit', 0,...
        'Display', 'iter',...
        'FunctionTolerance', 1e-3,...
        'HybridFcn', {@fmincon, hybridopts});
end



[tau,~,~,~] = particleswarm(f, totalParams, lb, ub, optimOptions);

    function cost                   = costFunc(singleChannel, fs, activationKernel, tau)
        tauSamples                  = round(tau*fs);
        
        onsets                      = activationKernel(:, 1)+tauSamples;
        offsets                     = activationKernel(:, 2)+tauSamples;
        onsets(onsets<=1)           = 1;
        offsets(offsets<=1)         = 1;
        lChannel                    = length(singleChannel);
        onsets(onsets>=lChannel)    = lChannel;
        offsets(offsets>=lChannel)  = lChannel;
        algoBurst                   = createBusts(singleChannel, onsets, offsets);
        [~, tkoEnergy]              = energyop(singleChannel, 0);
        totalEnergy                 = sum(tkoEnergy);
        baseEnergy                  = sum(tkoEnergy(~algoBurst));
        cost                        = baseEnergy / totalEnergy;
    end
end