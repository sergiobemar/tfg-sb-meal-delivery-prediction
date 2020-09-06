import joblib
import pandas as pd
import json

from flask import Flask
from flask import request
# from flask_restful import Api, Resource

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

# api.add_resource(Test, '/my_custom_test')
# api.add_resource(Predict, '/predict')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)