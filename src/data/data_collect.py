import numpy as np
import pandas as pd

def read_train_data():
	df_train = pd.read_csv('./data/processed/train.csv', sep = ';', decimal=',')

	return df_train