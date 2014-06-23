%clear all;
%close all;

% Coding rules :
% Function start with a Capital letter
% variable start with a lower-case letter
% but : only the MATRIX used for matrix calculation are completly named in CAPITAL


%% Import meshing
% If reduction = 1, the matrix system will be reduced, in order to set all
% the border node to the same value, in order to respect the divergence free criteria
% i.e. the node vector will be reorgenized in order to have all the border
% node on top, in order to facilitate the reduction of all the system

[shield.listNode,shield.listTriangle,shield.tri] = importMeshWavefront('./data/20x20_R180_H400.obj');

shield.center = [0 0 0];
shield.reduction = 1;
shield.maxMeshSize = 0.24; % 6 cm for the grob meshing
shield.nbrNodeToBorder = 6; %With Blender, their is sometime some with 5 connection. This can be corrected in the mesh
shield.distanceBetween2Wire = 0.1;
shield.rateIncreasingWire = 1;

[coil.listNode,coil.listTriangle,coil.tri] = importMeshWavefront('./data/20x20_R119_H280.obj');

coil.center = [0 0 0];
coil.reduction = 1;
coil.maxMeshSize = 0.24; % 6 cm for the grob meshing
coil.nbrNodeToBorder = 6; %With Blender, their is sometime some with 5 connection. This can be corrected in the mesh
coil.distanceBetween2Wire = 0.1;
coil.rateIncreasingWire = 1;

%% Target point definition
targetVolumeType = 'sphereSH';%'cylinder_xy'; %'sphere';%
targetVolumeRayon = 0.05;
% We first define the range and step


degreeMax = 10;
orderMax = 10;
rhoReference = 0.08;
rk = createTargetPointGaussLegendreAndRectangle7(rhoReference,degreeMax,orderMax);
calculateR = 1;
calculateL = 1;
calculateLwp = 0;
calculateA = 0;

%% In order to calculate the resistance matrix, we have to providfe some data :

% For the coil
coil.wireThickness = 0.008; % (meter) Thickness of the conductor
coil.wireWidth = 0.008; % (meter) Thickness of the conductor
coil.wireSurface = coil.wireThickness*coil.wireWidth; % in meter %5mmx5mm is equivalent to the number used in Timo's coil or the 7.5*7.5 litz wire
coil.fillFactor = 0.5;
coil.rhoCopper = 1.68*10^-8; % (Ohm*m) resistivity of the copper
coil.rho = coil.rhoCopper*coil.fillFactor;
coil.wireResistivity = coil.rhoCopper/coil.fillFactor;  % (Ohm*m) resistivity of the wire
%coil.wireResistance = coil.wireConductivity/(t^2); %Ohm.m 
%coil.wireResistance = 0.683*10^-3; %Ohm.m wireConductivity/(t^2);
%coil.wireConductivity = coil.wireSurface*coil.wireResistance;

%For the shield
coil.freq = 25000;
shield.wireThickness = 0.002; % (meter) Thickness of the shield. Should be 4*skin depth
%shield.wireSurface = shield.wireThickness^2; % in meter %5mmx5mm is equivalent to the number used in Timo's coil or the 7.5*7.5 litz wire
%shield.fillFactor = 1;
shield.rhoCopper = 1.68*10^-8; % (Ohm*m) resistivity of the copper
shield.muCopper = 1.2566*10^-6; % (?) absolute magnetic permeability of the material
shield.skinDepth = sqrt(2*shield.rhoCopper/(shield.muCopper*2*pi*freq));
shield.wireThickness = 4*shield.skinDepth; % (meter) Thickness of the shield. Should be 4*skin depth
%shield.rho = shield.rhoCopper*shield.fillFactor;
shield.wireResistivity = shield.rhoCopper;  % (Ohm*m) resistivity of the wire


for i=1:7
    bc(1).coefficient(i,:) = zeros(1,7);
    bs(1).coefficient(i,:) = zeros(1,7);
    bc(2).coefficient(i,:) = zeros(1,7);
    bs(2).coefficient(i,:) = zeros(1,7);
    bc(3).coefficient(i,:) = zeros(1,7);
    bs(3).coefficient(i,:) = zeros(1,7);
end
bc(2).coefficient(1,1) = 15*10^-3; % Drive Y
B  = RebuildField7bis(bc,bs,rhoReference, rk, 'sch');

targetCoil = 'DriveY';
coil.btarget = [B(1,:) B(2,:) B(3,:)];


optimizationType = 'QP';
coil.error = 0.25;
clear('B');
