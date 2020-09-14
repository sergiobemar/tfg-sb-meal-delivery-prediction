#!/usr/bin/env python
# coding: utf-8

import json
import os
import pandas as pd
import requests

# Get credentials from config file
with open('./config/credentials_github.json') as f:
    cred = json.load(f)

# Create the endpoint with the owner name
API_ENDPOINT = 'https://api.github.com/repos/' + cred['owner'] + '/{}/commits'

# Store the auth credentials
auth = (cred['username'], cred['password'])

# Repo
for r in cred['repository']: 
	## Get the name of the repo
	repo = r['repo']

	## Make the request
	r = requests.get(url = API_ENDPOINT.format(repo), auth=auth)

	## Iterate over the commits getting the relevant fields that I need
	row = []

	for i in r.json():
		d = {}
		commit = i['commit']
		author = commit['author']

		d['sha'] = i['sha']
		d['author'] = author['name']
		d['message'] = commit['message']
		d['html_url'] = i['html_url']
		d['date'] = author['date']

		row.append(d)

	## Create a dataframe with the information that I haver recovered
	df = pd.DataFrame(row)

	## Cast date as datetime and sort the dataframe by this field
	df['date'] = pd.to_datetime(df.date)

	df = df.sort_values('date')

	## Export the changes table to HTML
	df.to_html('./reports/change_list_repo_' + repo + '.html', index_names=False)

