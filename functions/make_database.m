function [truth_timit] = make_database(path_timit)

%% Extracting prompts
prompts_file = ['doc',filesep,'prompts.txt'];
fid = fopen([path_timit, prompts_file]);
lines = textscan(fid,'%s %s','Delimiter','(','CommentStyle',';');
fclose(fid);
for ind = 1:size(lines{1},1)
    lines{1}{ind} = lines{1}{ind}(1:end-1);
    lines{2}{ind} = lines{2}{ind}(1:2);
end
lines = struct('type', lines{2}, 'sentence', lines{1});

%% Extracting dictionary
dict_file = ['doc',filesep,'timitdic.txt'];
fid = fopen([path_timit, dict_file]);
dict = textscan(fid,'%s %s','Delimiter','/','CommentStyle',';');
fclose(fid);
for ind = 1:size(dict{1},1)
    dict{1}{ind} = dict{1}{ind}(1:end-2);
    dict{2}{ind} = dict{2}{ind}(1:end);
end
dict = struct('word', dict{1}, 'phonemes', dict{2});

%% Extracting speaker set
speakers_file = ['doc',filesep,'spkrsent.txt'];
fid = fopen([path_timit, speakers_file]);
speakers = textscan(fid,'%s %d %d %d %d %d %d %d %d %d %d','CommentStyle',';');
fclose(fid);
speakersdata = double(cell2mat(speakers(2:end)));
speakers = struct('id',speakers{1});
for ind = 1:numel(speakers)
    speakers(ind).sa = speakersdata(ind,1:2);
    speakers(ind).sx = speakersdata(ind,3:7);
    speakers(ind).si = speakersdata(ind,8:10);
end

truth_timit = struct('lines', lines, 'dict', dict, 'speakers', speakers);