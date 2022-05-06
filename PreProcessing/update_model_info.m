function [model_info] = update_model_info(S,osim_path,model_info)
% --------------------------------------------------------------------------
% update_model_info
%   Create additional fields with indices combination in model_info, based 
%   on existing fields. All sets of indices needed outside PreProcessing 
%   should be added here to guarantee consistency.
% 
% INPUT:
%   - S -
%   * setting structure S
%
%   - model_info -
%   * structure with all the model information based on the OpenSim model
% 
% OUTPUT:
%   - model_info -
%   * structure with all the model information based on the OpenSim model
% 
% Original author: Dhruv Gupta
% Original date: 17/March/2022
%
% Last update:
%   moved most content to separate functions that are called earlier
% Last edit by: Lars D'Hondt
% Last edit date: 12/April/2022
% --------------------------------------------------------------------------


%%

NMuscle = model_info.muscle_info.NMuscle;
for i=1:NMuscle
    idx_coords_i = find(model_info.muscle_info.muscle_spanning_joint_info(i,:)==1);
    names_coords_i = model_info.ExtFunIO.coord_names.all(idx_coords_i);
    tmpst = [num2str(length(names_coords_i)) ': '];
    for j=1:length(names_coords_i)-1
        tmpst = [tmpst names_coords_i{j} ', '];
    end
    tmpst = [tmpst names_coords_i{end}];
    model_info.muscle_info.parameters(i).coords_crossed_by_muscle = tmpst;
end

%%
if strcmp(S.subject.mtp_type,'active')
    act_mtpi = [];
    act_not_mtpi = [];
    for i=1:model_info.actuator_info.NActuators
        if contains(model_info.actuator_info.parameters(i).coord_name,'mtp')
            act_mtpi(end+1) = i;
        else
            act_no_mtpi(end+1) = i;
        end

    end
else
    act_mtpi = [];
    act_not_mtpi = 1:model_info.actuator_info.NActuators;
end

model_info.actuator_info.act_mtpi = act_mtpi;
model_info.actuator_info.act_not_mtpi = act_not_mtpi;

%%
Ncoords = length(model_info.ExtFunIO.coord_names.all);

% model_info.ExtFunIO.jointi.NOT_muscleActuated = setdiff([1:Ncoords],model_info.ExtFunIO.jointi.muscleActuated);

model_info.ExtFunIO.jointi.legsi = sort([model_info.ExtFunIO.jointi.leg_l model_info.ExtFunIO.jointi.leg_r]);
model_info.ExtFunIO.jointi.armsi = sort([model_info.ExtFunIO.jointi.arm_l model_info.ExtFunIO.jointi.arm_r]);
model_info.ExtFunIO.jointi.mtpi  = sort([model_info.ExtFunIO.jointi.mtp_l model_info.ExtFunIO.jointi.mtp_r]);
model_info.ExtFunIO.jointi.legs_nomtp = sort(setdiff(model_info.ExtFunIO.jointi.legsi,model_info.ExtFunIO.jointi.mtpi));
model_info.ExtFunIO.jointi.noarmsi = sort([model_info.ExtFunIO.jointi.ground_pelvis model_info.ExtFunIO.jointi.legsi model_info.ExtFunIO.jointi.torso]); % all but arms
model_info.ExtFunIO.jointi.legs_torso = sort([model_info.ExtFunIO.jointi.legsi model_info.ExtFunIO.jointi.torso]);

model_info.ExtFunIO.jointi.tau_passi = [model_info.ExtFunIO.jointi.muscleActuated model_info.ExtFunIO.jointi.armsi model_info.ExtFunIO.jointi.mtpi];

model_info = addCoordNames(model_info,'leg_r');
model_info = addCoordNames(model_info,'leg_l');
model_info = addCoordNames(model_info,'arm_r');
model_info = addCoordNames(model_info,'arm_l');
model_info = addCoordNames(model_info,'ground_pelvis');
model_info = addCoordNames(model_info,'torso');
model_info = addCoordNames(model_info,'muscleActuated');
model_info = addCoordNames(model_info,'legs_torso');
model_info = addCoordNames(model_info,'legsi');
model_info = addCoordNames(model_info,'armsi');
model_info = addCoordNames(model_info,'noarmsi');
model_info = addCoordNames(model_info,'mtpi');
model_info = addCoordNames(model_info,'legs_nomtp');
model_info = addCoordNames(model_info,'rotations');
model_info = addCoordNames(model_info,'translations');
model_info = addCoordNames(model_info,'tau_passi');



%%
% Number of degrees of freedom for later use
model_info.ExtFunIO.jointi.nq.all          = Ncoords; % all
model_info.ExtFunIO.jointi.nq.abs          = length(model_info.ExtFunIO.jointi.ground_pelvis);
model_info.ExtFunIO.jointi.nq.torso        = length(model_info.ExtFunIO.jointi.torso); % trunk
model_info.ExtFunIO.jointi.nq.arms         = length(model_info.ExtFunIO.jointi.armsi); % arms
model_info.ExtFunIO.jointi.nq.mtp          = length(model_info.ExtFunIO.jointi.mtpi);
model_info.ExtFunIO.jointi.nq.leg          = length(model_info.ExtFunIO.jointi.legsi);
model_info.ExtFunIO.jointi.nq.legs_torso   = length(model_info.ExtFunIO.jointi.legs_torso);
model_info.ExtFunIO.jointi.nq.noarms       = length(model_info.ExtFunIO.jointi.noarmsi);
model_info.ExtFunIO.jointi.nq.muscleActuated = length(model_info.ExtFunIO.jointi.muscleActuated);
model_info.ExtFunIO.jointi.nq.torqAct      = length(model_info.ExtFunIO.jointi.torqueActuated);
model_info.ExtFunIO.jointi.nq.legs_nomtp   = length(model_info.ExtFunIO.jointi.legs_nomtp);
model_info.ExtFunIO.jointi.nq.roti         = length(model_info.ExtFunIO.jointi.rotations);
model_info.ExtFunIO.jointi.nq.translationsi = length(model_info.ExtFunIO.jointi.translations);

% note: remove the ones that we do not use later

ActOpp = find(ismember(model_info.ExtFunIO.symQs.QsOpp(:),model_info.ExtFunIO.jointi.torqueActuated));
ActInvA = setdiff(1:model_info.ExtFunIO.jointi.nq.torqAct,ActOpp);

ActInvB = zeros(size(ActInvA));

for i=1:length(ActInvB)
    idx_i = find(model_info.ExtFunIO.symQs.QsInvA==model_info.ExtFunIO.jointi.torqueActuated(ActInvA(i)));
    ActInvB(i) = find(model_info.ExtFunIO.jointi.torqueActuated==model_info.ExtFunIO.symQs.QsInvB(idx_i));
end
model_info.ExtFunIO.symQs.ActInvA = ActInvA;
model_info.ExtFunIO.symQs.ActInvB = ActInvB;
model_info.ExtFunIO.symQs.ActOpp = ActOpp;

%%
% orderTauPass = [1:nq.tau_pass];
% orderTauPassInv = zeros(1,nq.tau_pass);
% for i=1:nq.tau_pass
%     if strcmp(model_info.ExtFunIO.coord_names.tau_passi{i}(end-1:end),'_r')
%         orderTauPassInv(i) = orderTauPass(find(ismember(model_info.ExtFunIO.coord_names.tau_passi,[model_info.ExtFunIO.coord_names.tau_passi{i}(1:end-2) '_l'])));
%     elseif strcmp(model_info.ExtFunIO.coord_names.tau_passi{i}(end-1:end),'_l')
%         orderTauPassInv(i) = orderTauPass(find(ismember(model_info.ExtFunIO.coord_names.tau_passi,[model_info.ExtFunIO.coord_names.tau_passi{i}(1:end-2) '_r'])));
%     else
%         orderTauPassInv(i) = orderTauPass(find(ismember(model_info.ExtFunIO.coord_names.tau_passi,model_info.ExtFunIO.coord_names.tau_passi{i})));
%     end
% end
% 
% model_info.ExtFunIO.symQs.orderTauPass = orderTauPass;
% model_info.ExtFunIO.symQs.orderTauPassInv = orderTauPassInv;




















