% train_clean_test_5dB
doDisp=1;
if(doDisp)
    disp('=================================================');
    disp('==================  5dB-SNR   Male ==============');
    disp('=================================================');
end;    
Fs=8000;


Root='./';

TrainDataRoot=[Root 'database/train/'];
TestDataRoot=[Root 'database/test/SNR5_male/'];

TrainFeatureRoot=[Root 'features/train/'];
TestFeatureRoot=[Root 'features/test/'];

ModelRoot=[Root 'models/'];
ScriptRoot=[Root 'scripts/'];
wdnet_file      = [ScriptRoot 'wdnet_file.txt'];

ConfigFile=[ScriptRoot 'config_file.cfg'];
ModelList=[ScriptRoot 'Model_List.txt'];
DictFile=[ScriptRoot 'Dictionary.txt'];
WordList=[ScriptRoot 'Word_List.txt'];
WordList2=[ScriptRoot 'Word_List2.txt'];
WordListSP=[Root 'scripts/WordListSP.txt'];
MLF_Results=[ScriptRoot 'MLF_Results.mlf'];
TrainWordMLF=[Root 'scripts/TrainWordMLF.mlf'];
TrainWordMLF2=[Root 'scripts/TrainWordMLF2.mlf'];
TestWordMLF=[Root 'scripts/TestWordMLF.mlf'];
TrainFeatureScript=[Root 'scripts/TrainFeatureScript.txt'];
TestFeatureScript=[Root 'scripts/TestFeatureScript.txt'];
TestScript=[Root 'scripts/TestScript.txt'];
MixScript1=[Root 'scripts/HED1.txt'];
MixScript2=[Root 'scripts/HED2.txt'];
WdnetFile=[Root 'scripts/WDNet.txt'];
MLFResults=[Root 'scripts/MLFResults.mlf'];
hmmdefs=[ModelRoot 'hmmdefs'];

NUM_STATES=16;
NUM_HEREST_1=3;
NUM_HEREST_2=6;
alpha=1.16;

% =======================================================================================
% =============== Testing Feature Extraction ============================================
% =======================================================================================
testfiles=dir(TestDataRoot);
testfiles=testfiles(3:end);
features=dir(TestFeatureRoot);
for n=3:length(features)
    delete([TestFeatureRoot '/' features(n).name]);  
end;
if(doDisp)

    disp('>>> Performing testing feature extraction ');

end;     
numfiles=length(testfiles);
for num=1:numfiles
    if(doDisp & mod(num,200)==0)
        disp([num2str(ceil(100*num/numfiles)) '% done...']);
    end;
    file_name=char(testfiles(num).name);
    wavFile=[TestDataRoot file_name];
    data=open_wavfile(wavFile);
    feature=MFCC(data,Fs);
    %feature=PNCC_warp_freq_low(data,Fs, alpha);
    
    
    
    TestMFCCs = feature;
    % Calculate PDF for male and female GMMs
    ProbsMale = pdf(BestModelMale, TestMFCCs);          
    ProbsFemale = pdf(BestModelFemale, TestMFCCs);
    ProbsAll = ProbsMale+ ProbsFemale;
    prob_m = ProbsMale./ProbsAll;
    prob_f = ProbsFemale./ProbsAll;
    averageMale = mean(ProbsMale);
    ave_prob_m = mean(prob_m);
    ave_prob_f = mean(prob_f);
    averageFemale = mean(ProbsFemale);
    m=[m;averageMale];
    f=[f;averageFemale];
    p_m =[p_m; ave_prob_m];
    p_f=[p_f; ave_prob_f];
%     counterMale = 0;
%     counterFemale = 0;
%     
%     for j = 1:length(ProbsMale)
%         if (ProbsMale(j) > ProbsFemale(j))
%             counterMale = counterMale + 1;
%         else
%             counterFemale = counterFemale + 1;
%         end
%     end
    
    %if (averageMale > averageFemale)
    if (ave_prob_m > ave_prob_f)    
        %classification_m{index} = 'M';
        feature=MFCC(data,Fs);
    else
        %classification_m{index} = 'F';
        feature=MFCC_warp_freq_low(data,Fs, alpha);
    end
    
    
    
    
    
    
    
    feature_file=[TestFeatureRoot file_name(1:end-3) 'mfc'];
    writehtk(feature_file,feature,1/120,9);
end;
fid=fopen(TestFeatureScript,'w');
for i=1:numfiles
    fprintf(fid, '%s\n',[TestFeatureRoot testfiles(i).name(1:end-3) 'mfc']);
end
fclose(fid);
%=======================================================================================
%=======================================================================================
%=======================================================================================



%=======================================================================================
%=============== Training HMM Models ===================================================
%=======================================================================================



%=======================================================================================
%=============== Testing HMM Models ===================================================
%=======================================================================================

if(doDisp)  

    disp('>>>  Testing HMMs ');

end;
    
disp(['Creating MLF file...']);  
feature_files=char(textread(TestFeatureScript,'%s'));
fid1=fopen(TestWordMLF,'w');
fprintf(fid1,'%s\n','#!MLF!#');
for k=1:size(feature_files,1)
    dashes=find(feature_files(k,:)=='-');
    dots=find(feature_files(k,:)=='.');
    slashes=find(feature_files(k,:)=='\');
    underscores=find(feature_files(k,:)=='_');
    for s=1:length(slashes)
        feature_files(k,slashes(s))='/';
    end;  
    fprintf(fid1,'%s\n',['"' feature_files(k,1:dots(end)) 'lab"']);
    fprintf(fid1,'%s\n','sil');
    words=feature_files(k,underscores(end)+1:dots(end)-2);
    for w=1:length(words)
        number=find_number(words(w));
        fprintf(fid1,'%s\n',number);
    end;
    fprintf(fid1,'%s\n','sil');
    fprintf(fid1,'%s\n','.');       
end;
fclose(fid1);
cmd=['!HBuild'...
    ' -s sil sil'...
    ' ' WordList...
    ' ' WdnetFile...
    ];
eval(cmd);
disp('HVite.');
cmd = ['!HVite' ...
    ' -C ' ConfigFile...
    ' -H ' hmmdefs...
    ' -i ' MLFResults...
    ' -I ' TestWordMLF...
    ' -w ' WdnetFile...
    ' -p -20.0 '...
    ' -S ' TestFeatureScript ...
    ' ' DictFile ...
    ' ' WordList ...
    ];
eval(cmd);        
disp('HREsults.');
cmd = ['! HResults '...
    '   -e  "???" sil'...
    ' -I ' TestWordMLF...
    ' -p '...
    ' ' WordList...
    ' ' MLFResults...
    ];
eval(cmd);


%=======================================================================================
%=======================================================================================
%=======================================================================================

