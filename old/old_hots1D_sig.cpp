

  // //Make signatures (sliding window)
  // std::string td_data_test(directory+"events_test_classif.dat");
  // read1Daudiofile(td_data_test,ts,lvl,ch,pol);
  // std::vector<unsigned short> polphn;
  // opol.resize(pol.size(),0);
  // polphn.resize(pol.size(),0);
  // std::vector<std::pair<unsigned long, unsigned short>> event_buffer_; // ts et opol
  // for(int32_t i = 0; i < (int32_t)ts.size(); i++)
  // {
  //   coord[0] = lvl.at(i);
  //   opol.at(i) = Network.updateNetworkFromEventAndReturnPolarity(coord, pol.at(i), ts.at(i) + shift_ts, &lo);
  //   event_buffer_.push_back(std::make_pair(ts.at(i), opol.at(i)));

  //   unsigned long size_interval(1000);
  //   while((ts.at(i) > size_interval) && (event_buffer_.front().first < ts.at(i) - size_interval)){
  //     event_buffer_.erase(event_buffer_.begin());
  //   }

  //   std::vector<float> signature_event_;
  //   signature_event_.resize(Network.allLayers[Network.allLayers.size()-1]->layerSurfaces.size(), 0); // == nbCenters
  //   float tempSum = 0.;
  //   for(auto&& it : event_buffer_){
  //       signature_event_.at(it.second)++;
  //       tempSum++;
  //   }
  //   for(auto&& it : signature_event_){
  //     it /= tempSum;
  //   }
  //   polphn.at(i) = compute_dist_signatures(signature_event_, learned_signatures_);
  // }
  // std::string td_data_patch3(directory+"events_sigLayer"+std::to_string(curr_layer)+".dat");
  // write1Daudiofile(td_data_patch3,ts,lvl,ch,polphn);





  // //Make signatures (supervised)
  // std::string td_data_test(directory+"events_test_classif.dat");
  // read1Daudiofile(td_data_test,ts,lvl,ch,pol);
  // opol.resize(pol.size(),0);
  //
  // std::string filename_label_test(directory+"labels_test_classif.txt");
  // std::vector<unsigned long> tleft, tright, labeltruth, labelpred;
  // getStreamInfo(filename_label_test, tleft, tright, labeltruth);
  // labelpred.resize(labeltruth.size());
  // std::vector<float> signature_reco_(Network.allLayers[Network.allLayers.size()-1]->layerSurfaces.size(), 0.);
  // float tmpSum = 0;
  // unsigned int curr_label = 0;
  // #if defined(DEBUG)
  // std::string file_ts(directory+"surfaces_last_layer.txt");
  // std::ofstream ofstest(file_ts.c_str(), std::ofstream::out | std::ofstream::trunc);
  // if(ofstest.good() == false){
  //   std::cout << "error: try to open " << file_ts.c_str() << " failed" << std::endl;
  //   throw;
  // }
  // #endif
  // for(int32_t i = 0; i < (int32_t)ts.size(); i++)
  // {
  //   coord[0] = lvl.at(i);
  //   opol.at(i) = Network.updateNetworkFromEventAndReturnPolarity(coord, pol.at(i), ts.at(i) + shift_ts, &lo);
  //
  //   #if defined(DEBUG)
  //   {
  //     std::stringstream ss;
  //     Network.allLayers[Network.allLayers.size()-1]->getInputDecayedSurface()->writeTimeSurfaceInFile(ss);
  //     ofstest << ss.str();
  //   }
  //   #endif
  //
  //   if (ts.at(i) > tright.at(curr_label)){
  //     for(auto&& it:signature_reco_){
  //       it /= tmpSum;
  //     }
  //     // test sig ans return pred
  //     labelpred.at(curr_label) = compute_dist_signatures(signature_reco_, learned_signatures_) + 1;
  //     std::fill(signature_reco_.begin(),signature_reco_.end(),0.);
  //
  //     tmpSum = 0.;
  //     curr_label++;
  //   }
  //   signature_reco_.at(opol.at(i))++;
  //   tmpSum++;
  // }
  // #if defined(DEBUG)
  // ofstest.close();
  // #endif
  // // int number_diffs = 0;
  // // for (unsigned int ind = 0; ind < labeltruth.size(); ++ind)
  // // {
  // //   if (labeltruth.at(ind) != labelpred.at(ind)) number_diffs++;
  // // }
  // std::string td_data_patch3(directory+"events_sigLayer"+std::to_string(curr_layer)+".dat");
  // write1Daudiofile(td_data_patch3,ts,lvl,ch,opol);
