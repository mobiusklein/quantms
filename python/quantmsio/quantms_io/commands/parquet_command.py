import click
import pandas as pd
import datacompy


@click.command("parquet-compare", short_help="Compare two parquet files")
@click.option("--parquet_path_one", help="First parquet file", required=True)
@click.option("--parquet_path_two", help="the parquet file of memory version", required=True)
@click.option("--report_path", help="report path", required=True)
def compare_feature_convert(parquet_path_one: str, parquet_path_two: str, report_path: str):
    """
    Compare two parquet files generated from the same mztab psms files.
    :param parquet_path_one: the parquet file of discache version
    :param parquet_path_two: the parquet file of memory version
    :param report_path: report path
    """
    parquet_one = pd.read_parquet(parquet_path_one)
    parquet_two = pd.read_parquet(parquet_path_two)
    parquet_one = parquet_one.astype(str)
    parquet_two = parquet_two.astype(str)
    compare = datacompy.Compare(parquet_one, parquet_two, join_columns='sequence', df1_name='discache',df2_name='no_cache')
    with open(report_path,'w') as f:
        f.write(compare.report())