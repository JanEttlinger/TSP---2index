import time




import itertools

import numpy as np
import pandas as pd
from scipy.spatial import distance_matrix
import matplotlib
import matplotlib.pylab as plt
import seaborn as sns

import pulp

import warnings
warnings.filterwarnings("ignore")



# define TSP

n_customer = 10
n_point = n_customer + 1

df = pd.DataFrame({
    'x': np.random.randint(0, 100, n_point),
    'y': np.random.randint(0, 100, n_point),
})

df.iloc[0]['x'] = 0
df.iloc[0]['y'] = 0

distances = pd.DataFrame(distance_matrix(df[['x', 'y']].values, df[['x', 'y']].values), index=df.index, columns=df.index).values

# set problem
problem = pulp.LpProblem('tsp_mip', pulp.LpMinimize)

# set variables
x = pulp.LpVariable.dicts('x', ((i, j) for i in range(n_point) for j in range(n_point)), lowBound=0, upBound=1, cat='Binary')
# we need to keep track of the order in the tour to eliminate the possibility of subtours
u = pulp.LpVariable.dicts('u', (i for i in range(n_point)), lowBound=1, upBound=n_point, cat='Integer')

# set objective function
problem += pulp.lpSum(distances[i][j] * x[i, j] for i in range(n_point) for j in range(n_point))

# set constrains
for i in range(n_point):
    problem += x[i, i] == 0

for i in range(n_point):
    problem += pulp.lpSum(x[i, j] for j in range(n_point)) == 1
    problem += pulp.lpSum(x[j, i] for j in range(n_point)) == 1

# eliminate subtour
for i in range(n_point):
    for j in range(n_point):
        if i != j and (i != 0 and j != 0):
            problem += u[i] - u[j] <= n_point * (1 - x[i, j]) - 1

# remove longest arcs
hdist = distances
for j in range(0,len(hdist),4):
    for i in range(len(hdist)):

        x[i,np.argmax(hdist[i])].setInitialValue(0)
        x[i,np.argmax(hdist[i])].fixValue()
        hdist[i,np.argmax(hdist[i])] = 0


for i in range(0,len(hdist)): 
    x[i,i].setInitialValue(0)
    x[i,i].fixValue()

# set solver options
solver = pulp.PULP_CBC_CMD(fracGap=0.001, msg=True, warmStart=True)

# solve problem

status = problem.solve(solver)

# output status, value of objective function
end = time.time()
print('fast', round(end-start,0), pulp.LpStatus[status], round(pulp.value(problem.objective),0)


