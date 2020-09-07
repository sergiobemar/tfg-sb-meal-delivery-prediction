import joblib
import json
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

	df = pd.DataFrame.from_records(content)
	
	print(df.columns)
	df = df[features]
# 	df = pd.DataFrame(data)

	df = df.apply(pd.to_numeric)
	
	print('NUM ROWS: ' + str(len(df.index)))
	pred = regressor_model.predict(df[features])

# 	return pred[0]
# 	result = {
# 		"features" : features,
# 		"columns" : list(df.columns),
# 		"pred" : list(pred[0])
# 	}
# 	print(pred)
	result = {i : str(pred[i]) for i in range(0, len(pred))}
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