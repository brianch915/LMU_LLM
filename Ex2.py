import numpy as np
import pandas as pd
import math
# plots
import matplotlib.pyplot as plt
import seaborn as sns
# sklearn
import sklearn
from sklearn.datasets import load_iris
from sklearn.tree import DecisionTreeRegressor
from sklearn.linear_model import LinearRegression
import sklearn.metrics as metrics

model = LinearRegression(fit_intercept=True)
print(model)
x = np.arange(0, 8, 0.01)
np.random.seed(42)
y = -1 + 3 * x + np.random.normal(loc=0.0, scale=4, size=len(x))
# R: `sklearn` relies on package-specific learning objectives.
# O: Optimization is triggered by `model.fit()`, internally calling
# package-specific optimization procedures.
# within the function `model.fit()`:
model.fit(x.reshape(-1, 1), y) # reshape for one feature design matrix
mse = metrics.mean_squared_error(y, model.predict(x.reshape(-1, 1)))
print(f'Model MSE: {mse:.4f}')

iris = load_iris()
X = iris.data
Y = iris.target
feature_names = iris.feature_names
target_names = iris.target_names

url = "https://archive.ics.uci.edu/ml/machine-learning-databases/abalone/abalone.data"
abalone = pd.read_csv(
url,
sep=',',
names=[
'sex',
"longest_shell",
"diameter",
"height",
"whole_weight",
"shucked_weight",
"visceral_weight",
"shell_weight",
"rings"
]
)
abalone = abalone[['longest_shell', 'whole_weight', 'rings']]
print(abalone.head)
plt.scatter(abalone["longest_shell"], abalone["whole_weight"], c = abalone["rings"])
plt.show()

x_lm = abalone.iloc[:, 0:2].values
y_lm = abalone.rings
lm = LinearRegression().fit(x_lm,y_lm)
pred_lm = lm.predict(x_lm)
results_dic = {'prediction' : pred_lm, 'truth': y_lm}
results = pd.DataFrame(results_dic)
results.head()

plt.grid(True)
sns.regplot(
x=pred_lm,
y=y_lm,
ci=95,
scatter_kws={'s': 5},
line_kws={"color": "black", 'linewidth': 1}
)
sns.rugplot(x=pred_lm, y=y_lm, height=0.025, color='k')
# title & label axes
plt.title('Truth vs prediction', size=15)
plt.xlabel('Prediction', size=11)
plt.ylabel('Truth', size=11)
plt.show()