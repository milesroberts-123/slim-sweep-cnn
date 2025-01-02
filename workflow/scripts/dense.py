# load packages
print("Loading packages...")
import sys, os
import numpy as np
import pandas as pd
from PIL import Image
import tensorflow as tf
from tensorflow import keras
#import matplotlib.pyplot as plt
#from keras.optimizers import SGD
from keras.preprocessing.image import ImageDataGenerator
import scipy
import keras_tuner

# Check if GPUs are available
#print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
#tf.debugging.set_log_device_placement(True)

# define parameters
path = "data/images/"
batch_size = 32
epochs = 200
patience = 20
tune_trials = 60
#slim_params = "../config/parameters.tsv"
slim_params = "stratified_sample_20.tsv"
weightFolderName = "data/weights"
finalModelName = "best_cnn.h5"
summary_stats = ["ID", "pi", "thetaw", "tajd", "tajd_var", "num_haplos", "h1", "h2", "h12", "h123", "h2h1", "gkl_var", "gkl_skew", "gkl_kurt", "hscan"]

# split data into training, testing, and validation
print("Reading table of parameters...")
slim_params = pd.read_table(slim_params)

print("Splitting table into training, validation, and testing...")
train_params = slim_params[slim_params["split"] == "train"].copy().reset_index()
val_params = slim_params[slim_params["split"] == "val"].copy().reset_index()
test_params = slim_params[slim_params["split"] == "test"].copy().reset_index()

print(train_params)
print(val_params)
print(test_params)

# reformat IDs, and log transform dependent variable
train_params['ID'] = train_params['ID'].astype(str)
val_params['ID'] = val_params['ID'].astype(str)

train_params['ID'] = train_params["ID"].replace(to_replace = r"$", value = ".png", regex = True).replace(to_replace = r"^", value = "slim_", regex = True)
val_params['ID'] = val_params["ID"].replace(to_replace = r"$", value = ".png", regex = True).replace(to_replace = r"^", value = "slim_", regex = True)

# transform dependent variables
train_params['tf'] = train_params['tf'].apply(np.log10)
val_params['tf'] = val_params['tf'].apply(np.log10)
test_params['tf'] = test_params['tf'].apply(np.log10)

train_params['ta'] = train_params['ta'].apply(np.log10)
val_params['ta'] = val_params['ta'].apply(np.log10)
test_params['ta'] = test_params['ta'].apply(np.log10)

# subset out features
train_stats = train_params[summary_stats]
val_stats = val_params[summary_stats]
test_stats = test_params[summary_stats]

# drop rows with nan values
print("Drop nan rows...")
print(train_stats.shape)
print(val_stats.shape)
print(test_stats.shape)

train_stats = train_stats.dropna()
val_stats = val_stats.dropna()
test_stats = test_stats.dropna()

print(train_stats.shape)
print(val_stats.shape)
print(test_stats.shape)

# get output variable
print("Subset output variable...")
train_output = train_params.loc[train_params['ID'].isin(train_stats['ID'])]
val_output = val_params.loc[val_params['ID'].isin(val_stats['ID'])]
test_output = test_params.loc[test_params['ID'].isin(test_stats['ID'])]

train_output = train_output['tf']
val_output = val_output['tf']
test_output = test_output['tf']

print(train_output.shape)
print(val_output.shape)
print(test_output.shape)

# extract ID as it's own list
train_ids = list(train_stats["ID"])
val_ids = list(val_stats["ID"])
test_ids = list(test_stats["ID"])

# drop ID column
print("Drop ID column...")
train_stats.drop('ID', axis=1, inplace=True)
val_stats.drop('ID', axis=1, inplace=True)
test_stats.drop('ID', axis=1, inplace=True)

# convert to numpy array
print("Convert dataframes to numpy arrays...")
train_stats = train_stats.to_numpy()
val_stats = val_stats.to_numpy()
test_stats = test_stats.to_numpy()

print(train_stats.shape)
print(val_stats.shape)
print(test_stats.shape)


# Create model with functional API
# https://keras.io/guides/keras_tuner/getting_started/
def build_model(hp):
  print("Creating model...")
  input = keras.layers.Input(shape = [14], name = "summaries")
  dense_A = keras.layers.Dense(units=hp.Int("denseA-units", min_value=16, max_value=512, step=8), activation = "relu")(input)
  dense_A = keras.layers.Dropout(hp.Float(name = "denseA-dropout", min_value=0, max_value=0.99))(dense_A)
  dense_B = keras.layers.Dense(units=hp.Int("denseB-units", min_value=16, max_value=512, step=8), activation = "relu")(dense_A)
  dense_B = keras.layers.Dropout(hp.Float(name = "denseB-dropout", min_value=0, max_value=0.99))(dense_B)
  dense_C = keras.layers.Dense(units=hp.Int("denseC-units", min_value=16, max_value=512, step=8), activation = "relu")(dense_B)
  dense_C = keras.layers.Dropout(hp.Float(name = "denseC-dropout", min_value=0, max_value=0.99))(dense_C)
  output = keras.layers.Dense(1, name = "output")(dense_C)

  model = keras.Model(inputs = [input], outputs = [output])

  # compile model
  print("Compiling model...")
  model.compile(optimizer='adam', loss="mse", metrics = [tf.keras.metrics.MeanSquaredError()])

  return model


# build hyperparameter tuner
tuner = keras_tuner.BayesianOptimization(
    hypermodel=build_model,
    objective="val_mean_squared_error",
    max_trials=tune_trials,
    overwrite=True,
    directory="tuning_dir",
    project_name="slimcnn",
)

# print summary of search space
tuner.search_space_summary()

# Seach hyperparameter space
print("Starting search...")
tuner.search(train_stats, train_output, epochs=2, validation_data=(val_stats, val_output))

# Get the top 2 models.
print("Extract best model...")
models = tuner.get_best_models(num_models=2)
best_model = models[0]
best_model.summary()
model = best_model

# add callbacks: early stopping and saving at checkpoints
earlystop = keras.callbacks.EarlyStopping(monitor='val_loss', min_delta=0.0, patience=patience, verbose=0, mode='auto')
checkpoint = keras.callbacks.ModelCheckpoint(weightFolderName, monitor='val_loss', verbose=1, save_best_only=True, mode='min')
callbacks = [earlystop, checkpoint]

# fit model
print("Fitting model...")
history = model.fit(train_stats, train_output, batch_size=batch_size, epochs=epochs, verbose=1, validation_data=(val_stats, val_output), callbacks=callbacks)

# evaluate total error in model
print("Evaluating model on testing data...")
test_pred = np.stack([model(test_stats, training = True) for sample in range(100)])
test_pred_mean = test_pred.mean(axis=0)
test_pred_std = test_pred.std(axis=0)
np.savetxt('test_predicted_vs_actual_dense.txt', np.c_[test_ids, test_output, test_pred_mean, test_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std", fmt="%s")

print("Evaluating model on validation data...")
val_pred = np.stack([model(val_stats, training = True) for sample in range(100)])
val_pred_mean = val_pred.mean(axis=0)
val_pred_std = val_pred.std(axis=0)
np.savetxt('val_predicted_vs_actual_dense.txt', np.c_[val_ids, val_output, val_pred_mean, val_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std", fmt="%s")

print("Evaluating model on training data...")
train_pred = np.stack([model(train_stats, training = True) for sample in range(100)])
train_pred_mean = train_pred.mean(axis=0)
train_pred_std = train_pred.std(axis=0)
np.savetxt('train_predicted_vs_actual_dense.txt', np.c_[train_ids, train_output, train_pred_mean, train_pred_std], header = "ID true_tf pred_tf_mean pred_tf_std", fmt="%s")

# save model
print("Saving final model...")
model.save(finalModelName)

# save comparison of predictions vs actual
print("Done! :)")
