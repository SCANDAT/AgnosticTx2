from dash import Dash, dcc, html, dash_table
from dash.dash_table.Format import Format, Scheme, Group, Trim, Align
from dash.dash_table import FormatTemplate
import pandas as pd

# Assuming you have necessary configurations in the following:
from config import predictor_dict, label_dict
from functions import format_pvalue

df = pd.read_csv('../Output/Supp table 1.csv')

# Apply mappings
df['Predictor'] = df['Predictor'].map(predictor_dict)
df['Label'] = df['Label'].map(label_dict)

app = Dash(__name__)

columns = [
    {"name": ["Supplementary Table 1 - Results from unadjusted analyses","Lab test"], "id": "Label"},   
    {"name": ["Supplementary Table 1 - Results from unadjusted analyses","Predictor"], "id": "Predictor"},
    {
        "name": ["Supplementary Table 1 - Results from unadjusted analyses","Number of observations"], 
        "id": "Number of observations",
        "type": "numeric",
        "format": Format().group(True)
    },
    {
        "name": ["Supplementary Table 1 - Results from unadjusted analyses","Crude p-value"], 
        "id": "Crude p-value", 
        "type": "numeric", 
        "format": Format(precision=2, scheme=Scheme.decimal_or_exponent)
    },
    {
        "name": ["Supplementary Table 1 - Results from unadjusted analyses","FDR adjusted p-value"], 
        "id": "FDR adjusted p-value", 
        "type": "numeric", 
        "format": Format(precision=2, scheme=Scheme.decimal_or_exponent)
    }
]


app.layout = html.Div([
    dash_table.DataTable(
        data=df.to_dict('records'),
        columns=columns,
        page_size=20,
        style_table={'height': '750px', 'overflowY': 'auto'},
        fill_width=False,
        filter_action='native',
        sort_action='native',
        sort_mode='single',
        page_action='native',
        merge_duplicate_headers=True,
        style_header={
            'fontWeight': 'bold'
        },
        style_data_conditional=[
            {
                'if': {
                    'filter_query': '{FDR adjusted p-value} lt 0.05'  
                },
                'fontWeight': 'bold'
            },
            {
                'if': {
                    'filter_query': '{FDR adjusted p-value} ge 0.05'  
                },
                'fontWeight': 'normal',
                'font-style': 'italic'
            },
        ],
        style_cell_conditional=[
            {
                'if': {'column_id': 'Predictor'},
                'textAlign': 'left'
            },
            {
                'if': {'column_id': 'Label'},
                'textAlign': 'left'
            }
        ]
    )
])

if __name__ == '__main__':
    app.run_server(debug=True)