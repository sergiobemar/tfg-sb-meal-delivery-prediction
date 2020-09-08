import joblib
import json
import numpy as np
import os
import pandas as pd

from flask import Flask
from flask import jsonify
from flask import request
# from flask_restful import Api, Resource
import sys

os.chdir('/home/jupyter/tfg-sb-meal-delivery-prediction/')

from src.data.data_collect import read_train_data
from src.model.xgboost_model import preprocess_data, train_xgboost_model

df_train = read_train_data()

regressor_model = joblib.load('./models/xgboost_model.pkl')
features = joblib.load('./models/xgboost_features.pkl')

app = Flask(__name__)
# api = Api(app)

# class Test(Resource):
# 	def get(self):
# 		return {'response': 'test successful!!!!!'}

# class Predict(Resource):
# 	def post(self):
# 		json_data_dict = request.get_json(force=True)
# 		X = json_data_dict['features']
# 		predictions = model.predict(X)
# 		return {'predictions':predictions}

@app.route('/test', methods=['GET'])
def get():
	return {'response': 'test successful!!!!!'}


@app.route('/predict', methods=['POST'])
def predict():
# 	data = {}
	
# 	for v in features:
# 		data[v] = [request.form[v]]
	
# 	print(request.form)
	content = request.json
# 	print('Contenido: ' + content)
		
# 	json_data_dict = request.get_json(force=True)
#     X = json_data_dict['features']

	# Read dataframe
	df = pd.DataFrame.from_records(content)
	
	# Set column date as index in order to use it in predictions result
	df = df.set_index('date')
	
	# Select significative columns
	df = df[features]

	# Cast to numeric
	df = df.apply(pd.to_numeric)
	
	print('NUM ROWS: ' + str(len(df.index)))
	pred = regressor_model.predict(df[features])
	
	# Use exponential to convert the result
	pred_results = np.exp(pred)
	
	# Create a dataframe with predictions
	df_result = pd.DataFrame({"num_orders" : pred_results})
	
	# Assign index from source dataframe and, so that we're able to have another column with the date, index is reseted
	df_result.index = df.index
	df_result.reset_index(inplace=True)
	
	# Generate a JSON with results
	result = df_result.to_json(orient='records')
	
# 	return pred[0]
# 	result = {
# 		"features" : features,
# 		"columns" : list(df.columns),
# 		"pred" : list(pred[0])
# 	}
# 	print(pred)
# 	result = {df.index[i] : str(pred_results[i]) for i in range(0, len(pred_results))}
	
	return result

@app.route('/save', methods=['GET'])
def save_model():
	
	joblib.dump(regressor_model, './models/xgboost_model.pkl')
	joblib.dump(features, './models/xgboost_features.pkl')
	
	return {'response': 'Model saved done!'}

@app.route('/train', methods=['POST'])
def train():
	
	# Get data from the request
	content = request.json
	
	center_id = content['center_id']
	meal_id = content['meal_id']
	
	# Preprocess the dataframe
	df_preprocessed = preprocess_data(df_train, center_id, meal_id)
	
	regressor_model, rmse = train_xgboost_model(df_preprocessed)

	features = list(df_preprocessed.drop(columns='num_orders').columns)

	result = {
		'features' : features,
		'rmse' : rmse
	}
# 	result = {
# 		'data' : content['center_id']
# 	}
	return jsonify(result)
# api.add_resource(Test, '/my_custom_test')
# api.add_resource(Predict, '/predict')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)