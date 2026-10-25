## `sparkly_lite` technical guide

This guide describes the `sparkly-lite` command, the two Python functions of `sparkly_lite`, `block` and `evaluate`, the file formats and the limits. The [tutorial](tutorial.md) shows them in use, and [How `sparkly_lite` works](how-it-works.md) explains the concepts behind them.

Contents:

- [Conventions and data shapes](#conventions-and-data-shapes)
- [The command line](#the-command-line)
- [Reading and writing files](#reading-and-writing-files)
- [The Python functions](#the-python-functions)
- [Limits](#limits)

## Conventions and data shapes

The examples below use `import sparkly_lite as sl`. The package provides `block`, `evaluate`, and `LimitError`.

The data of a run has the following shapes.

| Data | Columns | Notes |
| --- | --- | --- |
| A table | an id column, and the columns to block on | The id column is `_id` unless `id_col` names another. Its values are whole numbers, 0 or more, present on every row and unique. |
| Candidate pairs | `id1`, `id2`, `blocking_score` | `id1` is the ID of a record from table A, and `id2` is the ID of a record from table B, in either direction. `blocking_score` is the TF/IDF score of the pair. |
| A gold set | two id columns | The pairs known to be matches, with the id of table A in the first column or in a column named as [How `sparkly_lite` works](how-it-works.md#recall-reduction-and-the-gold-set) describes. |

In a deduplication, table A and table B are the same table, and each pair holds the smaller id in `id1`.

In messages, `query` means the table whose records receive candidates (table B by default), and `doc` means the table the candidates come from (table A by default). [How `sparkly_lite` works](how-it-works.md#the-top-k-and-the-direction) describes the direction.

## The command line

The installer puts the command `sparkly-lite` in the `.venv` environment. It has two subcommands, `block` and `smoke`. `sparkly-lite --help` lists them, and `sparkly-lite block --help` lists the options of `block`, with examples.

### `sparkly-lite block`

```
sparkly-lite block TABLE_A [TABLE_B] [options]
```

Blocks table B against table A, or table A against itself with `--dedup`, prints a summary of the run, and saves the candidates when `--out` is given. It performs the same run as the Python function [`block()`](#block), and each option corresponds to an argument of `block`.

| Option | Python | Default | What it does |
|---|---|---|---|
| `TABLE_A` | `table_a` | required | The table the candidates come from, as a file. |
| `TABLE_B` | `table_b` | none | The table whose records receive candidates. Left out with `--dedup`. |
| `--gold FILE` | `gold` | none | The gold set. Adds the rows `\|GT\|`, `Found/GT` and `Recall` to the summary. |
| `--out FILE` | `out` | none | Saves the candidates to this file, in the format its extension names, and as Parquet when it has none. See [Output files](#output-files). |
| `--format NAME` | `format` | from the extension | `parquet`, `csv`, `tsv` or `jsonl`, for an `--out` whose extension does not name the format. |
| `--k N` | `k` | 20 | The number of candidates kept for each record, from 1 to 128. |
| `--columns a,b,c` | `columns=["a", "b", "c"]` or `columns="a,b,c"` | all but the id | The blocking columns, separated by commas. Spaces around the names are ignored, so `--columns a, b, c` names the same columns. |
| `--id-col NAME` | `id_col` | `_id` | The id column. `_rid` numbers the rows 0, 1, 2 and so on instead. |
| `--direction b2a\|a2b` | `direction` | `b2a` | `b2a` finds candidates in table A for each record from table B. `a2b` finds candidates in table B for each record from table A, and adds a `Mode` row to the summary. |
| `--dedup` | `dedup=True` | off | Matches table A against itself, to find its duplicates. |
| `--tokenizer NAME` | `tokenizer` | `word` | `word`, `trigram` or `hybrid`. See [Tokens](how-it-works.md#tokens). |
| `--k1 X` | `bm25_k1` | 1.2 | The BM25 parameter that sets how fast repeated tokens stop adding to the score. |
| `--b-param X` | `bm25_b` | 0.75 | The BM25 parameter that sets how much the length of a record counts, from 0 to 1. |
| `--quiet` | `progress=False` | off | Hides the progress line. |

The summary has one row per measure, as [Part 1](tutorial.md#part-1-blocking-two-tables) and [Part 2](tutorial.md#part-2-measuring-recall-against-a-gold-set) of the tutorial describe. While the run is in progress, a progress line shows the number of records processed and the estimated time remaining.

The command exits with status 0 when the run succeeds. When the run fails, it prints the message after `error: ` and exits with status 1. A value out of range, such as `--k 200`, is such a failure. When the command line itself is wrong, such as an unknown option or a missing `TABLE_B` without `--dedup`, it prints the usage and the message, and exits with status 2. [Troubleshooting](troubleshooting.md) lists the messages.

**Example:**

```bash
sparkly-lite block data/dblp_acm/table_a.parquet data/dblp_acm/table_b.parquet \
    --gold data/dblp_acm/gold.parquet --columns title,authors --out candidates.parquet
```

### `sparkly-lite smoke`

```
sparkly-lite smoke
```

Checks that `sparkly_lite` runs on this Mac, with a search on two records. It prints `OK — sparkly_lite runs on this machine.` and exits with status 0, or prints the error and exits with status 1. The installer runs it as its last step.

## Reading and writing files

### File formats

The tables, the gold set and the candidate set given to `evaluate` can be given as files or, from Python, as objects in memory. A file is read according to its extension.

| Extension | Format | Notes |
|---|---|---|
| `.parquet`, `.pq` | Parquet | Read with the types it has. |
| `.csv`, `.txt` | CSV, separated by commas | The first line names the columns. |
| `.tsv` | TSV, separated by tabs | The first line names the columns. |
| `.json`, `.jsonl`, `.ndjson` | JSON Lines, or a JSON array of objects | An object that holds the array under `data`, `records`, `rows` or `items` is also read. |

From Python, a table can also be a pandas or Polars DataFrame, or a pyarrow Table or RecordBatch, and a gold set can also be a pair of arrays `(a_ids, b_ids)`. The values of the blocking columns are converted to text, whatever their type.

### What your files need

- *An id column.* Each table needs a column whose values identify its records, present on every row and unique. `sparkly_lite` reads the ids from `_id` by default, and `--id-col` (or `id_col` param in python) lets you name a differently named id column. It never guesses another column, and it checks the ids before any work. A table without such a column can use `--id-col _rid`, which numbers the rows 0, 1, 2 and so on. These numbers are row positions, so they identify the records only while the row order stays the same. The ids must be whole numbers, 0 or more. The next section describes what to do for a table keyed by strings.
- *Columns to block on.* By default, every column except the id column, which is `_id` or the column that `--id-col` names. Columns named `id`, `_id` or `_rid` are left out too, since they usually hold ids. `--columns` (`columns`) names them instead, and every column it names must exist in the table.
- *A gold set (optional).* Required only to measure recall, with `--gold` (`gold`). It has two columns that hold the ids of the pairs known to match, with the id of table A first, or with names that [How `sparkly_lite` works](how-it-works.md#recall-reduction-and-the-gold-set) lists.

### Tables keyed by strings

`sparkly_lite` does not support string ids. Ids must be whole numbers, 0 or more.

To block a table keyed by strings, such as product codes, use `--id-col _rid`, which numbers the rows 0, 1, 2 and so on. The column of codes is then blocked on like any other column, unless `--columns` names the columns to block on:

```bash
sparkly-lite block table_a.csv table_b.csv --id-col _rid \
    --columns title,price --out candidates.parquet
```

The candidates then hold row numbers. A gold set, or a matcher given the candidates, must use the same numbers. For either, convert the files once with the script below, and use the files it writes from then on. The script adds to each table a column `_id` that numbers its rows, and writes the gold set with these numbers in place of the codes.

```python
import pandas as pd

table_a = pd.read_csv('table_a.csv')
table_b = pd.read_csv('table_b.csv')
gold = pd.read_csv('gold.csv')
table_a.insert(0, '_id', range(len(table_a)))
table_b.insert(0, '_id', range(len(table_b)))
id_a = dict(zip(table_a['code'], table_a['_id']))
id_b = dict(zip(table_b['code'], table_b['_id']))
gold = pd.DataFrame({'id1': gold['code_a'].map(id_a), 'id2': gold['code_b'].map(id_b)})
table_a.to_parquet('table_a.parquet', index=False)
table_b.to_parquet('table_b.parquet', index=False)
gold.to_parquet('gold.parquet', index=False)
```

A code of the gold set that is not in its table gives an empty id, and the run stops with the message `the gold set has missing ids`.

Block the converted files as any others. Their column `code` is blocked on unless `--columns` names the columns to block on:

```bash
sparkly-lite block table_a.parquet table_b.parquet --gold gold.parquet \
    --columns title,price --out candidates.parquet
```

In a deduplication there is one table. Number it, and convert both columns of the gold set with its numbers.

### Output files

`--out` of the CLI, and the argument `out` of `block`, write the candidates in the format that the extension of the file names, or that `--format` (`format` param in python) names when the extension does not name one.

| Format | Extension | Content |
|---|---|---|
| `parquet`, the default | `.parquet`, `.pq` or none | One row per pair, with `id1` and `id2` as 64-bit integers and `blocking_score` as a 32-bit float. |
| `csv` | `.csv` | One row per pair, after a header line, with each score to 6 decimal places. |
| `tsv` | `.tsv` | The same as `csv`, separated by tabs. |
| `jsonl` | `.jsonl` | One JSON object per pair, with the keys `id1`, `id2` and `blocking_score`. |

The following rules apply to every format.

- An extension that names no format, or an extension and a format that disagree, such as `--out x.csv --format parquet`, is refused before the run starts.
- The file is written under a temporary name beside it, `<file>.partial-<n>`, and renamed when it is complete, so it is written whole or not at all.
- In a deduplication, the file holds no pair of a record with itself, and holds each pair once, with the smaller id as `id1`.

## The Python functions

### `block()`

```python
def block(
    table_a,                 # table A, as a file, a DataFrame or a pyarrow Table
    table_b=None,            # table B; None for a deduplication of table A
    *,
    gold=None,               # the gold set, to measure recall
    out=None,                # a file to save the candidates to
    format=None,             # the format of out, when its extension names none
    verbose=True,            # print the summary
    **options,               # the options of the command, such as k=50
) -> dict
```

Performs a whole run in one call, as `sparkly-lite block` does. It blocks, measures recall when a gold set is given, saves the candidates when a file is given, prints the summary, and returns it.

**Parameters:**

- `table_a`, `table_b`: the tables, as [File formats](#file-formats) describes. With `table_b` left out, or with `dedup=True`, the run is a deduplication of `table_a`.
- `gold`: the gold set, as a file, a DataFrame, a pyarrow Table, or a pair of arrays `(a_ids, b_ids)`.
- `out`: the file to save the candidates to, as [Output files](#output-files) describes.
- `format`: the format of `out`, when its extension names none.
- `verbose`: `True` prints the summary when the run ends.
- `**options`: the options described in the [command-line reference](#sparkly-lite-block), passed using their Python parameter names: `k`, `columns`, `id_col`, `direction`, `dedup`, `tokenizer`, `bm25_k1`, `bm25_b`, and `progress`.

This function:

1. Checks the options, and, when `out` is given, determines its format.
2. Reads the tables, checks the row limit, and checks that the ids are whole numbers, 0 or more. When `gold` is given, it reads the gold set and checks its ids the same way.
3. Finds the K candidates of each record, as [How `sparkly_lite` works](how-it-works.md) describes, with the progress line unless `progress=False`.
4. Saves the candidates to `out`, when it is given.
5. Measures recall against `gold`, when it is given.
6. Prints the summary when `verbose` is `True`.

**Returns:** the summary, as a `dict` with the following keys.

| Key | What it holds |
|---|---|
| `n_candidates` | The number of candidate pairs. In a deduplication, the number of distinct pairs. |
| `reduction` | The share of all pairs left out, as a fraction, such as 0.992355. |
| `seconds` | The time from reading the tables to having the candidates. Saving and evaluating are not included. |
| `n_a`, `n_b` | The number of rows of table A and of table B. In a deduplication both are the rows of the one table. |
| `k`, `columns`, `direction`, `dedup` | The options of the run. `direction` is `None` in a deduplication. |
| `dataset` | The name of the directory that holds table A, or `None` for a table in memory. |
| `out` | The file the candidates were saved to, or `None`. |
| `n_gold`, `tp`, `fn`, `recall` | Only with a gold set. The number of pairs in the gold set, the number of them among the candidates, the number missing, and `tp / n_gold` as a fraction. |

**Raises:** `ValueError` for an invalid option, file or id, as [Troubleshooting](troubleshooting.md) lists. `TypeError` for an unknown option. `FileNotFoundError` when a file does not exist. `LimitError` when a table has more than 3,000,000 rows.

**Example:**

```python
summary = sl.block("data/dblp_acm/table_a.parquet", "data/dblp_acm/table_b.parquet",
                   gold="data/dblp_acm/gold.parquet", out="candidates.parquet", verbose=False)
print(summary["n_candidates"], summary["recall"])   # 45880 1.0
```

The candidates reach Python through the saved file. `pyarrow`, which is installed with `sparkly_lite`, reads it:

```python
import pyarrow.parquet as pq

pairs = pq.read_table("candidates.parquet")
print(pairs.num_rows, pairs.column_names)   # 45880 ['id1', 'id2', 'blocking_score']
```

### `evaluate()`

```python
def evaluate(
    candidates,              # the candidate set, as a file or a table
    gold,                    # the gold set
    dedup=False,             # True for the candidates of a deduplication
) -> dict
```

Measures the recall of a candidate set against a gold set, as `--gold` does, for a candidate set that was saved earlier. It does not block again.

**Parameters:**

- `candidates`: a candidate file in any of the formats of [Output files](#output-files), or a DataFrame or pyarrow Table with the columns `id1` and `id2`. A Parquet file grouped by `id2`, with the columns `id2` and `id1_list`, as other blockers write it, is read too.
- `gold`: the gold set, as for `block`.
- `dedup`: `True` when the candidates come from a deduplication. A gold pair then counts as found in either order, and a pair of a record with itself is never found.

**Returns:** a `dict` with the keys `n_candidates`, `n_gold`, `tp`, `fn` and `recall`, which hold what they hold in the summary of `block`.

**Raises:** `FileNotFoundError` when a file does not exist. `ValueError` when the candidates have no columns `id1` and `id2`, when an id of the candidates or of the gold set is missing or is not a whole number, 0 or more, or when the gold set has fewer than two columns.

**Example:**

```python
report = sl.evaluate("candidates.parquet", "data/dblp_acm/gold.parquet")
print(report["tp"], report["recall"])   # 2224 1.0
```

## Limits

### The row limit and `LimitError`

```python
class LimitError(RuntimeError)
```

`sparkly_lite` handles up to 3,000,000 rows in each table. `block` counts the rows after reading the tables and before any other work, and raises `LimitError` when a table has more. The limit is fixed, and no setting changes it. For larger tables, contact [our team](mailto:hello@relixa.ai).

The limits of a run are the following.

| Limit | Value | When it is checked |
|---|---|---|
| Rows in each table | 3,000,000 | Before any work. A larger table raises `LimitError`. |
| K | from 1 to 128 | Before any work. Another value raises `ValueError`. |
| Joined text of the blocking columns of one table | under 4 GB | When the text is prepared, before the search. A larger text raises `ValueError`. |

**Example:**

```python
try:
    sl.block("big_table.parquet", dedup=True)
except sl.LimitError as e:
    print(e)
```
