#!/bin/bash

results_dir="results_Uaccuracy_Utarget"
moderator='Uaccuracy-Utarget'

job_ID=$1
echo "job_ID = $job_ID"

for training_set in "All"
do
  echo "Training set = $training_set"
  
  U_content_coef=$(jq --arg TRAIN_SET "$training_set" '.[] | select(.training_set == $TRAIN_SET) .U_content_coef' general_config/Uaccuracy.json)
  U_target_coef=$(jq --arg TRAIN_SET "$training_set" '.[] | select(.training_set == $TRAIN_SET) .U_target_coef' general_config/Uaccuracy.json)

  for scenario in "All";
  do
    echo $scenario

    U_target_none=$(jq --arg SCENARIO "$scenario" '.[] | select(.scenario == $SCENARIO) .U_target_none' general_config/Utarget.json)
    U_target_debunk=$(jq --arg SCENARIO "$scenario" '.[] | select(.scenario == $SCENARIO) .U_target_debunk' general_config/Utarget.json)
  
    # read the parameters associated with the job array ID
    simulation_condition=$(jq --raw-output --arg JOB_ID "$job_ID" '.[] | select(.ID == $JOB_ID) .simulation_condition' general_config/ID_to_params.json)
    alpha_0=$(jq --arg JOB_ID "$job_ID" '.[] | select(.ID == $JOB_ID) .alpha0' general_config/ID_to_params.json)
    beta=$(jq --arg JOB_ID "$job_ID" '.[] | select(.ID == $JOB_ID) .beta' general_config/ID_to_params.json)
    gamma=$(jq --arg JOB_ID "$job_ID" '.[] | select(.ID == $JOB_ID) .gamma' general_config/ID_to_params.json)

    echo "${simulation_condition}-generalization simulation";
    echo "alpha_0 = $alpha_0";
    echo "beta = $beta";
    echo "gamma = $gamma";

    for epoch in 1 2 3 4 5;
    do
      echo "epoch $epoch"

      # Fitting beta distribution to posterior beliefs of observers in epoch 5 of simulation_condition pre-generalization (for epoch 1), 
      # or by fitting beta distribution to posterior files from epoch_t-1 of generalization simulation (for epoch t)
      mkdir -p "$results_dir/training_$training_set/$scenario/${simulation_condition}-generalization/ID_$job_ID/epoch_$epoch/config"
      
      if [ "$epoch" -eq 1 ]; then
        last_epoch=5
        last_action=$(jq -r --arg EPOCH "$last_epoch" '.[] | select(.epoch == $EPOCH) .action' general_config/actions.json)
        python find_prior_params_generalization.py "$results_dir/training_$training_set" $scenario $simulation_condition $job_ID $last_epoch $last_action

        # read the content beliefs separately from general_config/generalization_content_prior_params.json
        beta_a_content=$(jq --arg SCENARIO "$scenario" '.[] | select(.scenario == $SCENARIO) .beta_a_content' general_config/generalization_content_prior_params.json)
        beta_b_content=$(jq --arg SCENARIO "$scenario" '.[] | select(.scenario == $SCENARIO) .beta_b_content' general_config/generalization_content_prior_params.json)

        # Modify prior_params.json to add beta_a_content and beta_b_content
        param_dir="$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch/config/prior_params.json"
        jq --arg beta_a_content "$beta_a_content" --arg beta_b_content "$beta_b_content" \
        '.[].beta_a_content = ($beta_a_content | tonumber) | .[].beta_b_content = ($beta_b_content | tonumber)' \
        "$param_dir" > "temp_$job_ID.json" && mv "temp_$job_ID.json" "$param_dir" && rm -f "temp_$job_ID.json"
      else
        # call the python script that fits beta distribution to posterior files from previous epoch and 
        # saves the beta parameters in current epoch's config folder as prior_params.json
        prev_epoch=$((epoch - 1))
        prev_action=$(jq -r --arg EPOCH "$prev_epoch" '.[] | select(.epoch == $EPOCH) .action' general_config/actions_generalization.json)
        python find_prior_params.py "$results_dir/training_$training_set" $scenario "$simulation_condition-generalization" $job_ID $epoch $prev_action
      fi

      # read the parameters for epoch_t
      param_dir="$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch/config/prior_params.json"
      beta_a_content=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_a_content' $param_dir)
      beta_b_content=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_b_content' $param_dir)
      beta_a_alpha_accuracy=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_a_alpha_accuracy' $param_dir)
      beta_b_alpha_accuracy=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_b_alpha_accuracy' $param_dir)
      beta_a_alpha_target=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_a_alpha_target' $param_dir)
      beta_b_alpha_target=$(jq --arg SCENARIO "$scenario" --arg SIMULATION "$simulation_condition-generalization" '.[] | select(.scenario == $SCENARIO) | select(.simulation == $SIMULATION) .beta_b_alpha_target' $param_dir)

      echo "beta_a_content = $beta_a_content";
      echo "beta_b_content = $beta_b_content";
      echo "beta_a_alpha_accuracy = $beta_a_alpha_accuracy";
      echo "beta_b_alpha_accuracy = $beta_b_alpha_accuracy";
      echo "beta_a_alpha_target = $beta_a_alpha_target";
      echo "beta_b_alpha_target = $beta_b_alpha_target";

      # make the required sub-directories for saving model simulation outputs
      mkdir -p "$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch/moderator"
      mkdir -p "$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch/priors"

      # read the moderator's action in current epoch
      action=$(jq -r --arg EPOCH "$epoch" '.[] | select(.epoch == $EPOCH) .action' general_config/actions_generalization.json)
      mkdir -p "$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch/posteriors/$action"

      webppl main.wppl --require . --require webppl-json -- --moderator=$moderator --condition="$simulation_condition-generalization" --action=$action --alpha_0=$alpha_0 --beta=$beta --gamma=$gamma --U_target_none=$U_target_none --U_target_debunk=$U_target_debunk --U_content_coef=$U_content_coef --U_target_coef=$U_target_coef --beta_a_content=$beta_a_content --beta_b_content=$beta_b_content --beta_a_alpha_accuracy=$beta_a_alpha_accuracy --beta_b_alpha_accuracy=$beta_b_alpha_accuracy --beta_a_alpha_target=$beta_a_alpha_target --beta_b_alpha_target=$beta_b_alpha_target --dir "$results_dir/training_$training_set/$scenario/$simulation_condition-generalization/ID_$job_ID/epoch_$epoch"
    done
  done
done