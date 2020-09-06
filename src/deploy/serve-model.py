import joblib
import pandas as pd
import json

from flask import Flask
from flask import request
# from flask_restful import Api, Resource

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
	data = {}

	for v in features:
		data[v] = [request.form[v]]

	data = pd.DataFrame(data)

	pred = regressor_model.predict(df[features])

	return pred[0]

@app.route('/train', methods=['POST'])
def train():

	center_id = request.args.get('center_id')
	meal_id = request.args.get('meal_id')

	df_preprocessed = preprocess_data(df_train, center_id, meal_id)
	
	regressor_model, rmse = train_xgboost_model(df_preprocessed)

	features = df.drop(columns='num_orders').columns

	result = {
		'features' : features,
		'rmse' : rmse
	}
	return jsonify(result)
# api.add_resource(Test, '/my_custom_test')
# api.add_resource(Predict, '/predict')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)