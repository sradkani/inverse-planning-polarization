import json
import numpy as np
import pandas as pd
import sys
import itertools

""" For the simulations of differing content beliefs, shared motives:
- set the content prior a and b in the config content_prior_params file,
  one object corresponding to false and one object corresponding to true
- for accuracy and bias motive priors, if the mean is M and the variance is V:
- a = (M^2 * (1-M) - V * M) / V
- b = (1-M) * a / M
- for each value of content prior in differing_content_priors, iterate over M and V values (corresponding to each motive), 
  as well as the uncertainty of content prior belief

"""

def stats_to_params(M, V):
    # converts the mean and variance of beta distribution to its shape parameters a and b
    a = (M**2 * (1-M) - V * M) / V
    b = a * (1-M) / M
    return(a, b)

alpha0_set = np.array([1])
beta_set = np.array([10])
gamma_set = np.array([1])

simulation_condition = sys.argv[1] 
if(simulation_condition == "Differing-content"):
    content_Means = np.array([0.2, 0.8])
    content_Variances = np.square(np.array([0.05, 0.1, 0.15]))
    accuracy_Means = np.array([0.2, 0.5, 0.8])
    accuracy_Variances = np.square(np.array([0.05, 0.15, 0.25]))
    bias_Means = np.array([0.2, 0.5, 0.8])   # in the webppl code, this will be reduced by 0.5, therefore [-0.3, 0, 0.3]
    bias_Variances = np.square(np.array([0.05, 0.15, 0.25]))

ID_param_df = pd.DataFrame({'ID': [], 'simulation_condition': [], 
                            'alpha0': [], 'beta': [], 'gamma': [],
                            'mean_content': [], 'variance_content': [],
                            'mean_alpha_accuracy': [], 'variance_alpha_accuracy': [],
                            'mean_alpha_target': [], 'variance_alpha_target': [],
                            'beta_a_content': [], 'beta_b_content': [], 
                            'beta_a_alpha_accuracy': [], 'beta_b_alpha_accuracy': [],
                            'beta_a_alpha_target': [], 'beta_b_alpha_target': []})

i = 1
for combination in itertools.product(content_Means, content_Variances, accuracy_Means, accuracy_Variances, bias_Means, bias_Variances, alpha0_set, beta_set, gamma_set):
    c_M, c_V, a_M, a_V, b_M, b_V, alpha0, beta, gamma = combination
    beta_a_content, beta_b_content = stats_to_params(c_M, c_V)
    beta_a_alpha_accuracy, beta_b_alpha_accuracy = stats_to_params(a_M, a_V)
    beta_a_alpha_target, beta_b_alpha_target = stats_to_params(b_M, b_V) 

    tmp_df = {'ID': str(i), 'simulation_condition': simulation_condition, 
              'alpha0': alpha0, 'beta': beta, 'gamma': gamma,
              'mean_content': c_M, 'variance_content': c_V,
              'mean_alpha_accuracy': a_M, 'variance_alpha_accuracy': a_V,
              'mean_alpha_target': b_M, 'variance_alpha_target': b_V,
              'beta_a_content': beta_a_content, 'beta_b_content': beta_b_content, 
              'beta_a_alpha_accuracy': beta_a_alpha_accuracy, 'beta_b_alpha_accuracy': beta_b_alpha_accuracy,
              'beta_a_alpha_target': beta_a_alpha_target, 'beta_b_alpha_target': beta_b_alpha_target}
    
    ID_param_df = ID_param_df.append(tmp_df, ignore_index=True)
    i = i + 1

# Convert the DataFrame to JSON
json_result = ID_param_df.to_json(orient='records', lines=False)

# Write the JSON string to a file
with open("general_config/ID_to_params.json", "w") as file:
    file.write(json_result)