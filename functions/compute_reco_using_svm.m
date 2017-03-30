function reco_rate = compute_reco_using_svm(all_sigs_train, all_sigs_test)

  %let's train 1 svm for each class
  %then, inject all test signatures in all svm. and the class is the svm with the best spectrogram-like

training_label_vector = all_sigs_train(:,1);
training_instance_matrix = all_sigs_train(:,3:end);
testing_label_vector = all_sigs_test(:,1);
testing_instance_matrix = all_sigs_test(:,3:end);

model = svmtrain(training_label_vector, training_instance_matrix, '-h 0 -q');
[predicted_label, accuracy, prob_estimates] = ...
  svmpredict(testing_label_vector, testing_instance_matrix, model, '-b 0 -q');

cmat = confusionmat(testing_label_vector, predicted_label);
reco_rate = trace(cmat)/sum(cmat(:));
