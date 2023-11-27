%-------------------------------------------------------------------------
% Title: Code for MCS of Tandem Device (P/CIS)
% Author: Tan Hu Quee
% Date: Feb 2022
% Progress: Can include for FF and Voc as well
%-------------------------------------------------------------------------
clear
clc
close all
format shortEng
delete('TC_IV.txt')
delete('BC_IV.txt')
delete('TC_RII.txt')
delete('TC_RIII.txt')
delete('TC_Rrad.txt')
delete('TC_Rsrh.txt')
delete('TC_Raug.txt')
delete('TC_R_Vmpp.txt')
load Parameters.mat
num_run = size(Parameter,2);
f = zeros(4,num_run);

for i = 1:num_run
f(:,i) = objectiveFcn(Parameter(:,i));
end

Output = f;
save Output.mat Output

%% Function for tandem device
function f = objectiveFcn(x)
%% Top Cell

L1 = num2str(x(1));
L1 = {L1,'[m]'};
L1 = strjoin(L1);
L2 = num2str(x(2));
L2 = {L2,'[m]'};
L2 = strjoin(L2);
L3 = num2str(x(3));
L3 = {L3,'[m]'};
L3 = strjoin(L3);
L4 = num2str(x(4));
L4 = {L4,'[m]'};
L4 = strjoin(L4);
L6 = num2str(x(5));
L6 = {L6,'[m]'};
L6 = strjoin(L6);

model = mphload('4T_TopCell_C52a_final_Probe.mph');


model.param.set('L1', L1);
model.param.set('L2', L2);
model.param.set('L3', L3);
model.param.set('L4', L4);
model.param.set('L6', L6);

model.study('std1').run;

%% TC iV curve from COMSOL table
model.result.table('tbl1').clearTableData;
model.result.numerical('pev1').set('descr', {'' ''});
model.result.numerical('pev1').set('table', 'tbl1');
model.result.numerical('pev1').set('unit', {'' ''});
model.result.numerical('pev1').set('expr', {'-dflux_spatial(CeE)*e' ''});
model.result.numerical('pev1').setResult;

tabl=model.result.table('tbl1').getTableData(0);
CalculatedIV_TC = str2double(string(tabl));
P = CalculatedIV_TC(:,1).*CalculatedIV_TC(:,2);          
[Pmax_TC mpp] = max(P); % mW/(cm^2) Max power and id point for mpp
Eff_TC = Pmax_TC/1000; % Divided by one sun which is 100 mW/(cm^2)
%% TC RIII from COMSOL table
model.result.table('tbl2').clearTableData;
model.result.numerical('pev2').set('descr', {'' ''});
model.result.numerical('pev2').set('table', 'tbl2');
model.result.numerical('pev2').set('unit', {'A/m^2' ''});
model.result.numerical('pev2').set('expr', {'RIII*e' ''});
model.result.numerical('pev2').setResult;

tabl=model.result.table('tbl2').getTableData(0);
R_III = str2double(string(tabl));

%% TC RII from COMSOL table
model.result.table('tbl3').clearTableData;
model.result.numerical('pev3').set('descr', {'' ''});
model.result.numerical('pev3').set('table', 'tbl3');
model.result.numerical('pev3').set('unit', {'A/m^2' ''});
model.result.numerical('pev3').set('expr', {'RII*e' ''});
model.result.numerical('pev3').setResult;

tabl=model.result.table('tbl3').getTableData(0);
R_II = str2double(string(tabl));

%% TC Rbulk from COMSOL table
model.result.table('tbl4').clearTableData;
model.result.numerical('int1').label('Bulk');
model.result.numerical('int1').set('descr', {'' '' ''});
model.result.numerical('int1').set('table', 'tbl4');
model.result.numerical('int1').set('unit', {'A/m^2' 'A/m^2' 'A/m^2'});
model.result.numerical('int1').set('expr', {'Rrad_P*e' 'Rsrh_P*e' 'Raug_P*e'});
model.result.numerical('int1').setResult;

tabl=model.result.table('tbl4').getTableData(0);
R_bulk = str2double(string(tabl));
R_rad = R_bulk(:,2);
R_srh = R_bulk(:,3);
R_aug = R_bulk(:,4);

%% Bottom Cell
lGlassTC = 1e-3;
lSnO2 = 10e-9;
lLiF = 100e-9;
laBC = 100e-9;
lAZO = 225e-9;
lZnO = 70e-9;
lCdS = 35e-9;
lCIS = 2.4e-6;
lMo = 500e-9;
xstepsize = 1e-9;
x_coord = 0:xstepsize:lCIS;
[jsc_BC, R, T] = TMMBC(x_coord',xstepsize,x(1),x(2),x(3),x(4),lSnO2,x(5),lLiF,laBC,lAZO,lZnO,...
    lCdS,lCIS,lMo,lGlassTC);

CalculatedIV_BC = two_diode(jsc_BC);

Pmax_BC = max(CalculatedIV_BC(:,1).*CalculatedIV_BC(:,2)); % mW/(cm^2)
Eff_BC = Pmax_BC/1000; % Divided by one sun which is 100 mW/(cm^2)

f = [Eff_TC; Eff_BC; R; T];

%% Writing parametric search space to file
num_Va_TC = size(CalculatedIV_TC,1);
num_Va_BC = size(CalculatedIV_BC,1);
TC_str = "%e";
BC_str = "%e";
str = "%e";
for i = 2:num_Va_TC
    TC_str = append(TC_str,' ',str);
end
TC_str = append(TC_str,' ','\n');
TC_char = convertStringsToChars(TC_str);
for i = 2:num_Va_BC
    BC_str = append(BC_str,' ',str);
end
BC_str = append(BC_str,' ','\n');
BC_char = convertStringsToChars(BC_str);

fileID = fopen('TC_IV.txt','a');
%     fprintf(fileID, 'Parameter space with current density\n\n');
fprintf(fileID,TC_char,CalculatedIV_TC(:,2)');
fclose(fileID);

fileID = fopen('BC_IV.txt','a');
fprintf(fileID,BC_char,CalculatedIV_BC(:,2)');
fclose(fileID);

fileID = fopen('TC_RII.txt','a');
fprintf(fileID,TC_char,R_II(:,2)');
fclose(fileID);

fileID = fopen('TC_RIII.txt','a');
fprintf(fileID,TC_char,R_III(:,2)');
fclose(fileID);

fileID = fopen('TC_Rrad.txt','a');
fprintf(fileID,TC_char,R_rad');
fclose(fileID);

fileID = fopen('TC_Rsrh.txt','a');
fprintf(fileID,TC_char,R_srh');
fclose(fileID);

fileID = fopen('TC_Raug.txt','a');
fprintf(fileID,TC_char,R_aug');
fclose(fileID);

fileID = fopen('TC_R_Vmpp.txt','a');
fprintf(fileID,'%e %e %e %e %e \n',[R_rad(mpp) R_srh(mpp) R_aug(mpp) R_II(mpp,2) R_III(mpp,2)]);
fclose(fileID);
end