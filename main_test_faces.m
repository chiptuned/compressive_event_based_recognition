clear variables;
close all;
clc;

filename_mat = 'N-datasets/Faces/faces_square.mat';
load(filename_mat);
[nb_faces, nb_presentations] = size(ROI);

%faces_suqare contient 24 presentations de 7 personnes. On va concatener la
%premiere de chaque personne pour faire notre base de learning, et on va
%concatener tout le reste dans un fichier pour reconnaitre. On va permuter
%l'ordre les permutations et créer un label (vérité terrain). Toutes les
%présentations seront séparés par un temps delay_between_prez.

x_learning_hots = [];
y_learning_hots = [];
p_learning_hots = [];
ts_learning_hots = [];

x_learning_classif = [];
y_learning_classif = [];
p_learning_classif = [];
ts_learning_classif = [];

x_reco = [];
y_reco = [];
p_reco = [];
ts_reco = [];
