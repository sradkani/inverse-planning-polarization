import os
import json
import sys
import numpy as np
import pandas as pd
import math
import itertools


model = sys.argv[1]    # e.g., "Uaccuracy_Utarget"
training_set = sys.argv[2]   # e.g., "All"

log_dir = f"results_{model}/{training_set}" 
scenarios = [name for name in os.listdir(log_dir) if os.path.isdir(os.path.join(log_dir, name))]
conditions = [name for name in os.listdir(f"{log_dir}/{scenarios[0]}") if os.path.isdir(os.path.join(f"{log_dir}/{scenarios[0]}", name))]
IDs = [name for name in os.listdir(f"{log_dir}/{scenarios[0]}/{conditions[0]}") if os.path.isdir(os.path.join(f"{log_dir}/{scenarios[0]}/{conditions[0]}", name))]
epochs = [name for name in os.listdir(f"{log_dir}/{scenarios[0]}/{conditions[0]}/{IDs[0]}") if os.path.isdir(os.path.join(f"{log_dir}/{scenarios[0]}/{conditions[0]}/{IDs[0]}", name))]
available_actions = [name for name in os.listdir(f"{log_dir}/{scenarios[0]}/{conditions[0]}/{IDs[0]}/{epochs[0]}/posteriors") if os.path.isdir(os.path.join(f"{log_dir}/{scenarios[0]}/{conditions[0]}/{IDs[0]}/{epochs[0]}/posteriors", name))]

## TODO: Instead of hand coding the column names, I should make the column names to be determined by whatever file name that is there in the results folder
data_df0 = pd.DataFrame({'scenario': [], 'condition': [], 'ID': [], 
                         'content_mean': [], 'content_variance': [], 
                         'alpha_accuracy_mean': [], 'alpha_accuracy_variance': [],
                         'alpha_target_mean': [], 'alpha_target_variance': [],
                         'alpha0': [], 'beta': [], 'gamma': [], 
                         'epoch': [], 'action': [], 'action_prob': [], 
                         'alpha_target': [], 'alpha_accuracy': [], 'content': [],
                         'alpha_target_sd': [], 'alpha_accuracy_sd': [], 'content_sd': []})
data_df1 = pd.DataFrame({'scenario': [], 'condition': [], 'ID': [], 
                         'content_mean': [], 'content_variance': [], 
                         'alpha_accuracy_mean': [], 'alpha_accuracy_variance': [],
                         'alpha_target_mean': [], 'alpha_target_variance': [],
                         'alpha0': [], 'beta': [], 'gamma': [], 
                         'epoch': [], 'action': [], 'action_prob': [], 
                         'alpha_target_prior': [], 'alpha_accuracy_prior': [], 'content_prior': [],
                         'alpha_target_posterior': [], 'alpha_accuracy_posterior': [], 'content_posterior': [],
                         'alpha_target_prior_sd': [], 'alpha_accuracy_prior_sd': [], 'content_prior_sd': [],
                         'alpha_target_posterior_sd': [], 'alpha_accuracy_posterior_sd': [], 'content_posterior_sd': []})

with open(f"general_config/ID_to_params.json", 'r') as f:
    ID_to_param_file = json.load(f)
    
for combination in itertools.product(scenarios, conditions, IDs, epochs):
    scenario, simulation_condition, ID, epoch = combination
    ID = ID.split("_")[1]
    print(f"scenario: {scenario}")
    print(f"condition: {simulation_condition}")
    print(f"ID: {ID}")
    print(f"epoch: {epoch}")

    # For each simulation_condition and ID, go and find the corresponding entry in general_config/ID_to_params.json, then take its alpha0, beta, gamma, 
    # as well as the mean and variance of the content, alpha_accuracy and alpha_target
    params = [simulation for simulation in ID_to_param_file if (simulation['simulation_condition']==simulation_condition and simulation['ID']==ID)][0]
    if(params['alpha0']%1==0): 
        params['alpha0'] = int(params['alpha0'])
    if(params['beta']%1==0): 
        params['beta'] = int(params['beta'])
    if(params['gamma']%1==0): 
        params['gamma'] = int(params['gamma'])

    # read the prior beliefs for the condition -- note: the priors only depend on the condition and not the utilities
    file_names = [filename for filename in os.listdir(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/priors") 
                  if (filename.startswith("expected_") and f"{params['alpha0']}_{params['beta']}_{params['gamma']}" in filename)]
    variable_names = ["_".join(fname.split("_")[1:-3]) for fname in file_names]
    priors = {}
    for var_name in variable_names:
        with open(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/priors/expected_{var_name}_{params['alpha0']}_{params['beta']}_{params['gamma']}.json", 'r') as f:
            priors[f'{var_name}'] = json.load(f)  # the json file for expected values contain only one value = expectation of the distribution
    
    # read the config files containing the beta parameters for prior distributions to calculate the standard deviation of the prior distributions
    prior_sds = {}
    with open(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/config/prior_params.json", 'r') as f:
        config = json.load(f)
        if(not isinstance(config, dict)):
            config = config[0]
        for var_name in variable_names:
            a = config[f'beta_a_{var_name}']
            b = config[f'beta_b_{var_name}']
            prior_sds[f'{var_name}'] = math.sqrt(a * b / ((a + b)**2 * (a + b + 1)))

    # read the marginalized moderator decision policy 
    with open(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/moderator/moderator_{params['alpha0']}_{params['beta']}_{params['gamma']}.json", 'r') as f:
        moderator_policy = json.load(f)  # a dictionary with keys "support" (i.e., available actions) and "probs" (i.e., marginalized policy)
        for action in available_actions:
            if action not in moderator_policy['support']:
                moderator_policy['support'].append(action)
                moderator_policy['probs'].append(0)
        moderator_policy['action'] = moderator_policy.pop('support')   # TODO: I'm not sure why I just don't rename the keys!
        moderator_policy['action_prob'] = moderator_policy.pop('probs')
        moderator_policy = pd.DataFrame(moderator_policy).set_index('action')

    ## Save the data for each scenario, condition, beta, and action as a new row
    tmp_df = {'scenario': scenario, 'condition': simulation_condition, 'ID': ID,
              'content_mean': params['mean_content'], 'content_variance': params['variance_content'], 
              'alpha_accuracy_mean': params['mean_alpha_accuracy'], 'alpha_accuracy_variance': params['variance_alpha_accuracy'],
              'alpha_target_mean': params['mean_alpha_target'], 'alpha_target_variance': params['variance_alpha_target'],
              'alpha0': params['alpha0'], 'beta': params['beta'], 'gamma': params['gamma'], 
              'epoch': epoch, 'action': 'Prior', 'action_prob': np.NaN, 
              'alpha_target': priors['alpha_target'], 'alpha_accuracy': priors['alpha_accuracy'], 'content': priors['content'],
              'alpha_target_sd': prior_sds['alpha_target'], 'alpha_accuracy_sd': prior_sds['alpha_accuracy'], 'content_sd': prior_sds['content']}
    data_df0 = data_df0.append(tmp_df, ignore_index=True)
    
    # for each action, read the posterior belief of the observer given the moderator chooses that action
    for action in available_actions:
        # read the posterior beliefs
        file_names = [filename for filename in os.listdir(f'{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/posteriors/{action}/') 
                      if (filename.startswith("expected_") and f"{params['alpha0']}_{params['beta']}_{params['gamma']}" in filename)]
        variable_names = np.unique(["_".join(fname.split("_")[1:-3]) for fname in file_names]).tolist()
        posteriors = {}
        for var_name in variable_names:
            with open(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/posteriors/{action}/expected_{var_name}_{params['alpha0']}_{params['beta']}_{params['gamma']}.json", 'r') as f:
                posteriors[f'{var_name}'] = json.load(f)
        
        # read the samples from posterior beliefs to calculate the standard deviation of posterior belief distribution
        posterior_sds = {}
        for var_name in variable_names:
            with open(f"{log_dir}/{scenario}/{simulation_condition}/ID_{ID}/{epoch}/posteriors/{action}/{var_name}_{params['alpha0']}_{params['beta']}_{params['gamma']}.json", 'r') as f:
                file = json.load(f)
                samples = file['support']
                probabilities = file['probs']
                mean = sum(sample * prob for sample, prob in zip(samples, probabilities))
                variance = sum((sample - mean) ** 2 * prob for sample, prob in zip(samples, probabilities))
                posterior_sds[f'{var_name}'] = math.sqrt(variance)
        
        ## Save the data for each scenario, condition, beta, and action as a new row
        tmp_df = {'scenario': scenario, 'condition': simulation_condition, 'ID': ID,
                 'content_mean': params['mean_content'], 'content_variance': params['variance_content'], 
                 'alpha_accuracy_mean': params['mean_alpha_accuracy'], 'alpha_accuracy_variance': params['variance_alpha_accuracy'],
                 'alpha_target_mean': params['mean_alpha_target'], 'alpha_target_variance': params['variance_alpha_target'],
                 'alpha0': params['alpha0'], 'beta': params['beta'], 'gamma': params['gamma'], 
                 'epoch': epoch, 'action': action, 'action_prob': moderator_policy.loc[action][0], 
                 'alpha_target': posteriors['alpha_target'], 'alpha_accuracy': posteriors['alpha_accuracy'], 'content': posteriors['content'],
                 'alpha_target_sd': posterior_sds['alpha_target'], 'alpha_accuracy_sd': posterior_sds['alpha_accuracy'], 'content_sd': posterior_sds['content']}
        data_df0 = data_df0.append(tmp_df, ignore_index=True)
        
        tmp_df = {'scenario': scenario, 'condition': simulation_condition, 'ID': ID,
                 'content_mean': params['mean_content'], 'content_variance': params['variance_content'], 
                 'alpha_accuracy_mean': params['mean_alpha_accuracy'], 'alpha_accuracy_variance': params['variance_alpha_accuracy'],
                 'alpha_target_mean': params['mean_alpha_target'], 'alpha_target_variance': params['variance_alpha_target'],
                 'alpha0': params['alpha0'], 'beta': params['beta'], 'gamma': params['gamma'], 
                 'epoch': epoch, 'action': action, 'action_prob': moderator_policy.loc[action][0], 
                 'alpha_target_prior': priors['alpha_target'], 'alpha_accuracy_prior': priors['alpha_accuracy'], 'content_prior': priors['content'],
                 'alpha_target_posterior': posteriors['alpha_target'], 'alpha_accuracy_posterior': posteriors['alpha_accuracy'], 'content_posterior': posteriors['content'],
                 'alpha_target_prior_sd': prior_sds['alpha_target'], 'alpha_accuracy_prior_sd': prior_sds['alpha_accuracy'], 'content_prior_sd': prior_sds['content'],
                 'alpha_target_posterior_sd': posterior_sds['alpha_target'], 'alpha_accuracy_posterior_sd': posterior_sds['alpha_accuracy'], 'content_posterior_sd': posterior_sds['content']}
        data_df1 = data_df1.append(tmp_df, ignore_index=True)


data_df0.to_csv(f'{log_dir}/simulated_results_format0.csv', index=False)
data_df1.to_csv(f'{log_dir}/simulated_results_format1.csv', index=False)